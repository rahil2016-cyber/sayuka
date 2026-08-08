<?php

namespace App\Http\Controllers\Api\V1;

use App\Http\Controllers\Controller;
use App\Models\CompanySubscriptionPayment;
use App\Models\SeekerPackagePurchase;
use App\Services\PhonePe\PhonePeClient;
use App\Services\PhonePe\PhonePePaymentFulfillment;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Log;

class PhonePeWebhookController extends Controller
{
    public function __construct(
        protected PhonePeClient $phonePe,
        protected PhonePePaymentFulfillment $fulfillment,
    ) {}

    public function handle(Request $request): JsonResponse
    {
        if (! $this->phonePe->verifyWebhookAuthorization($request->header('Authorization'))) {
            return response()->json([
                'success' => false,
                'message' => 'Unauthorized webhook.',
            ], 401);
        }

        $event = (string) $request->input('event', '');
        $payload = $request->input('payload');

        if (! is_array($payload)) {
            return response()->json([
                'success' => false,
                'message' => 'Invalid webhook payload.',
            ], 400);
        }

        $merchantOrderId = (string) ($payload['merchantOrderId'] ?? '');
        if ($merchantOrderId === '') {
            return response()->json([
                'success' => true,
                'message' => 'Webhook ignored (no merchantOrderId).',
            ], 200);
        }

        $transactionId = null;
        $details = $payload['paymentDetails'] ?? null;
        if (is_array($details) && isset($details[0]) && is_array($details[0])) {
            $txn = $details[0]['transactionId'] ?? null;
            if (is_string($txn) && $txn !== '') {
                $transactionId = $txn;
            }
        }

        $phonepeOrderId = isset($payload['orderId']) ? (string) $payload['orderId'] : null;

        try {
            if ($event === 'checkout.order.completed') {
                $seeker = SeekerPackagePurchase::query()
                    ->where('phonepe_merchant_order_id', $merchantOrderId)
                    ->first();

                if ($seeker) {
                    $this->fulfillment->fulfillSeekerPurchase($seeker, $transactionId, $phonepeOrderId);

                    return response()->json([
                        'success' => true,
                        'message' => 'Webhook processed and purchase activated.',
                    ], 200);
                }

                $companyPayment = CompanySubscriptionPayment::query()
                    ->where('phonepe_merchant_order_id', $merchantOrderId)
                    ->first();

                if ($companyPayment) {
                    $this->fulfillment->fulfillCompanyPayment($companyPayment, $transactionId, $phonepeOrderId);

                    return response()->json([
                        'success' => true,
                        'message' => 'Webhook processed and company subscription activated.',
                    ], 200);
                }
            }

            if ($event === 'checkout.order.failed') {
                $this->fulfillment->markSeekerFailed($merchantOrderId, $transactionId);
                $this->fulfillment->markCompanyFailed($merchantOrderId, $transactionId);

                return response()->json([
                    'success' => true,
                    'message' => 'Webhook processed (order failed).',
                ], 200);
            }

            return response()->json([
                'success' => true,
                'message' => 'Webhook event ignored.',
            ], 200);
        } catch (\Throwable $e) {
            Log::error('[PhonePeWebhook] '.$e->getMessage(), ['exception' => $e]);

            return response()->json([
                'success' => false,
                'message' => 'Webhook processing error: '.$e->getMessage(),
            ], 500);
        }
    }
}
