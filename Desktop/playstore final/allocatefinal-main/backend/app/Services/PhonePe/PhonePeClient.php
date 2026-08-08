<?php

namespace App\Services\PhonePe;

use Illuminate\Support\Facades\Cache;
use Illuminate\Support\Facades\Http;
use Illuminate\Support\Facades\Log;
use RuntimeException;

class PhonePeClient
{
    public function environment(): string
    {
        $env = strtolower((string) config('services.phonepe.env', 'sandbox'));

        return $env === 'production' ? 'production' : 'sandbox';
    }

    public function sdkEnvironment(): string
    {
        return $this->environment() === 'production' ? 'PRODUCTION' : 'SANDBOX';
    }

    public function merchantId(): string
    {
        $merchantId = (string) config('services.phonepe.merchant_id', '');
        if ($merchantId === '') {
            throw new RuntimeException('PhonePe merchant ID is not configured.');
        }

        return $merchantId;
    }

    public function baseUrl(): string
    {
        if ($this->environment() === 'production') {
            return rtrim((string) config('services.phonepe.production_base_url'), '/');
        }

        return rtrim((string) config('services.phonepe.sandbox_base_url'), '/');
    }

    public function authBaseUrl(): string
    {
        if ($this->environment() === 'production') {
            return rtrim((string) config('services.phonepe.production_auth_base_url'), '/');
        }

        return $this->baseUrl();
    }

    /**
     * @param  array<string, string|null>  $metaInfo
     * @return array{orderId: string, state: string, expireAt?: int|null, token: string}
     */
    public function createSdkOrder(string $merchantOrderId, int $amountPaise, array $metaInfo = []): array
    {
        if ($amountPaise < 100) {
            throw new RuntimeException('PhonePe order amount must be at least 100 paise.');
        }

        $payload = [
            'merchantOrderId' => $merchantOrderId,
            'amount' => $amountPaise,
            'expireAfter' => 1200,
            'paymentFlow' => [
                'type' => 'PG_CHECKOUT',
            ],
        ];

        $udf = [];
        foreach ($metaInfo as $key => $value) {
            if ($value === null || $value === '') {
                continue;
            }
            $udf[$key] = (string) $value;
        }
        if ($udf !== []) {
            $payload['metaInfo'] = $udf;
        }

        $response = Http::withHeaders([
            'Content-Type' => 'application/json',
            'Authorization' => 'O-Bearer '.$this->accessToken(),
        ])->post($this->baseUrl().'/checkout/v2/sdk/order', $payload);

        if (! $response->successful()) {
            Log::error('[PhonePe] createSdkOrder failed', [
                'status' => $response->status(),
                'body' => $response->body(),
                'merchant_order_id' => $merchantOrderId,
            ]);
            throw new RuntimeException('PhonePe create order failed: '.$response->body());
        }

        $data = $response->json();
        if (! is_array($data) || empty($data['orderId']) || empty($data['token'])) {
            throw new RuntimeException('PhonePe create order returned an invalid response.');
        }

        return [
            'orderId' => (string) $data['orderId'],
            'state' => (string) ($data['state'] ?? 'PENDING'),
            'expireAt' => $data['expireAt'] ?? ($data['expiryAt'] ?? null),
            'token' => (string) $data['token'],
        ];
    }

    /**
     * @return array<string, mixed>
     */
    public function getOrderStatus(string $merchantOrderId): array
    {
        $response = Http::withHeaders([
            'Content-Type' => 'application/json',
            'Authorization' => 'O-Bearer '.$this->accessToken(),
        ])->get($this->baseUrl().'/checkout/v2/order/'.rawurlencode($merchantOrderId).'/status', [
            'details' => 'false',
            'errorContext' => 'true',
        ]);

        if (! $response->successful()) {
            Log::error('[PhonePe] getOrderStatus failed', [
                'status' => $response->status(),
                'body' => $response->body(),
                'merchant_order_id' => $merchantOrderId,
            ]);
            throw new RuntimeException('PhonePe order status failed: '.$response->body());
        }

        $data = $response->json();
        if (! is_array($data)) {
            throw new RuntimeException('PhonePe order status returned an invalid response.');
        }

        return $data;
    }

    public function extractTransactionId(array $status): ?string
    {
        $details = $status['paymentDetails'] ?? null;
        if (! is_array($details) || $details === []) {
            return null;
        }

        $first = $details[0] ?? null;
        if (! is_array($first)) {
            return null;
        }

        $txn = $first['transactionId'] ?? null;

        return is_string($txn) && $txn !== '' ? $txn : null;
    }

    public function verifyWebhookAuthorization(?string $authorizationHeader): bool
    {
        $username = (string) config('services.phonepe.webhook_username', '');
        $password = (string) config('services.phonepe.webhook_password', '');

        if ($username === '' || $password === '') {
            return false;
        }

        if ($authorizationHeader === null || $authorizationHeader === '') {
            return false;
        }

        $expected = hash('sha256', $username.':'.$password);
        $header = trim($authorizationHeader);

        if (str_starts_with(strtolower($header), 'sha256 ')) {
            $header = trim(substr($header, 7));
        } elseif (str_starts_with(strtolower($header), 'bearer ')) {
            $header = trim(substr($header, 7));
        }

        return hash_equals($expected, $header);
    }

    protected function accessToken(): string
    {
        $cacheKey = 'phonepe_oauth_token_'.$this->environment();

        $cached = Cache::get($cacheKey);
        if (is_string($cached) && $cached !== '') {
            return $cached;
        }

        $clientId = (string) config('services.phonepe.client_id', '');
        $clientSecret = (string) config('services.phonepe.client_secret', '');
        $clientVersion = (string) config('services.phonepe.client_version', '1');

        if ($clientId === '' || $clientSecret === '') {
            throw new RuntimeException('PhonePe client credentials are not configured.');
        }

        $response = Http::asForm()->post($this->authBaseUrl().'/v1/oauth/token', [
            'client_id' => $clientId,
            'client_version' => $clientVersion,
            'client_secret' => $clientSecret,
            'grant_type' => 'client_credentials',
        ]);

        if (! $response->successful()) {
            Log::error('[PhonePe] OAuth failed', [
                'status' => $response->status(),
                'body' => $response->body(),
            ]);
            throw new RuntimeException('PhonePe OAuth failed: '.$response->body());
        }

        $data = $response->json();
        $token = is_array($data) ? ($data['access_token'] ?? null) : null;
        if (! is_string($token) || $token === '') {
            throw new RuntimeException('PhonePe OAuth response missing access_token.');
        }

        $expiresAt = is_array($data) ? ($data['expires_at'] ?? null) : null;
        $ttlSeconds = 50 * 60;
        if (is_numeric($expiresAt)) {
            $ttlSeconds = max(60, ((int) $expiresAt) - time() - 60);
        }

        Cache::put($cacheKey, $token, now()->addSeconds($ttlSeconds));

        return $token;
    }
}
