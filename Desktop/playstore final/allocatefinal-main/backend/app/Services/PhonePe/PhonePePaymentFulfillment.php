<?php

namespace App\Services\PhonePe;

use App\Mail\CompanySubscriptionSuccessMail;
use App\Mail\JobSeekerPaymentSuccessMail;
use App\Models\CompanySubscriptionPayment;
use App\Models\JobSeekerProfile;
use App\Models\SeekerPackagePurchase;
use App\Support\Identifier;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Log;
use Illuminate\Support\Facades\Mail;

class PhonePePaymentFulfillment
{
    public function __construct(
        protected PhonePeClient $phonePe,
    ) {}

    /**
     * Confirm a seeker purchase against PhonePe order status (idempotent).
     *
     * @return array{status: string, purchase: SeekerPackagePurchase|null, profile: JobSeekerProfile|null, message: string}
     */
    public function confirmSeekerPurchase(string $merchantOrderId): array
    {
        $purchase = SeekerPackagePurchase::query()
            ->where('phonepe_merchant_order_id', $merchantOrderId)
            ->first();

        if (! $purchase) {
            return [
                'status' => 'not_found',
                'purchase' => null,
                'profile' => null,
                'message' => 'Order not found.',
            ];
        }

        if ($purchase->payment_status === 'successful') {
            return [
                'status' => 'successful',
                'purchase' => $purchase,
                'profile' => $purchase->user?->jobSeekerProfile?->fresh(),
                'message' => 'Payment already verified and package active.',
            ];
        }

        $status = $this->phonePe->getOrderStatus($merchantOrderId);
        $state = strtoupper((string) ($status['state'] ?? 'PENDING'));
        $transactionId = $this->phonePe->extractTransactionId($status);
        $phonepeOrderId = isset($status['orderId']) ? (string) $status['orderId'] : $purchase->phonepe_order_id;

        if ($state === 'COMPLETED') {
            $this->fulfillSeekerPurchase($purchase, $transactionId, $phonepeOrderId);

            return [
                'status' => 'successful',
                'purchase' => $purchase->fresh(),
                'profile' => $purchase->user?->jobSeekerProfile?->fresh(),
                'message' => 'Payment verified and package activated successfully.',
            ];
        }

        if ($state === 'FAILED') {
            $purchase->update([
                'payment_status' => 'failed',
                'phonepe_order_id' => $phonepeOrderId,
                'phonepe_transaction_id' => $transactionId,
            ]);

            return [
                'status' => 'failed',
                'purchase' => $purchase->fresh(),
                'profile' => null,
                'message' => 'Payment failed.',
            ];
        }

        return [
            'status' => 'pending',
            'purchase' => $purchase,
            'profile' => null,
            'message' => 'Payment is still pending.',
        ];
    }

    /**
     * @return array{status: string, payment: CompanySubscriptionPayment|null, message: string}
     */
    public function confirmCompanyPayment(string $merchantOrderId, ?int $companyId = null): array
    {
        $query = CompanySubscriptionPayment::query()
            ->where('phonepe_merchant_order_id', $merchantOrderId);

        if ($companyId !== null) {
            $query->where('company_id', $companyId);
        }

        $payment = $query->first();

        if (! $payment) {
            return [
                'status' => 'not_found',
                'payment' => null,
                'message' => 'Order not found.',
            ];
        }

        if ($payment->payment_status === 'successful') {
            return [
                'status' => 'successful',
                'payment' => $payment,
                'message' => 'Payment already verified.',
            ];
        }

        $status = $this->phonePe->getOrderStatus($merchantOrderId);
        $state = strtoupper((string) ($status['state'] ?? 'PENDING'));
        $transactionId = $this->phonePe->extractTransactionId($status);
        $phonepeOrderId = isset($status['orderId']) ? (string) $status['orderId'] : $payment->phonepe_order_id;

        if ($state === 'COMPLETED') {
            $this->fulfillCompanyPayment($payment, $transactionId, $phonepeOrderId);

            return [
                'status' => 'successful',
                'payment' => $payment->fresh(),
                'message' => 'Payment verified successfully.',
            ];
        }

        if ($state === 'FAILED') {
            $payment->update([
                'payment_status' => 'failed',
                'phonepe_order_id' => $phonepeOrderId,
                'phonepe_transaction_id' => $transactionId,
            ]);

            return [
                'status' => 'failed',
                'payment' => $payment->fresh(),
                'message' => 'Payment failed.',
            ];
        }

        return [
            'status' => 'pending',
            'payment' => $payment,
            'message' => 'Payment is still pending.',
        ];
    }

    public function fulfillSeekerPurchase(
        SeekerPackagePurchase $purchase,
        ?string $transactionId,
        ?string $phonepeOrderId = null,
    ): void {
        if ($purchase->payment_status === 'successful') {
            return;
        }

        if ($purchase->kind === 'resume_pdf') {
            DB::transaction(function () use ($purchase, $transactionId, $phonepeOrderId): void {
                $locked = SeekerPackagePurchase::query()->lockForUpdate()->find($purchase->id);
                if (! $locked || $locked->payment_status === 'successful') {
                    return;
                }

                $profile = JobSeekerProfile::query()
                    ->where('user_id', $locked->user_id)
                    ->lockForUpdate()
                    ->first();

                if ($profile && (int) $profile->resume_builds_remaining > 0) {
                    $profile->decrement('resume_builds_remaining');
                }

                $now = now();
                $locked->update([
                    'payment_status' => 'successful',
                    'phonepe_order_id' => $phonepeOrderId ?? $locked->phonepe_order_id,
                    'phonepe_transaction_id' => $transactionId,
                    'activated_at' => $now,
                    'expires_at' => $now,
                ]);
            });

            $purchase->refresh();

            return;
        }

        $purchase->activate($transactionId ?? 'phonepe', $phonepeOrderId);
        $this->sendSeekerSuccessMail($purchase->fresh());
    }

    public function fulfillCompanyPayment(
        CompanySubscriptionPayment $payment,
        ?string $transactionId,
        ?string $phonepeOrderId = null,
    ): void {
        if ($payment->payment_status === 'successful') {
            return;
        }

        $payment->update([
            'payment_status' => 'successful',
            'phonepe_order_id' => $phonepeOrderId ?? $payment->phonepe_order_id,
            'phonepe_transaction_id' => $transactionId,
            'purchased_at' => now(),
        ]);

        try {
            $user = $payment->company?->user;
            if ($user && $user->email && ! Identifier::isSyntheticEmail($user->email)) {
                Mail::to($user->email)->send(new CompanySubscriptionSuccessMail($payment->fresh()));
            }
        } catch (\Throwable $e) {
            Log::warning('[PhonePe] Failed to send company subscription email: '.$e->getMessage());
        }
    }

    public function markSeekerFailed(string $merchantOrderId, ?string $transactionId = null): void
    {
        SeekerPackagePurchase::query()
            ->where('phonepe_merchant_order_id', $merchantOrderId)
            ->where('payment_status', '!=', 'successful')
            ->update([
                'payment_status' => 'failed',
                'phonepe_transaction_id' => $transactionId,
            ]);
    }

    public function markCompanyFailed(string $merchantOrderId, ?string $transactionId = null): void
    {
        CompanySubscriptionPayment::query()
            ->where('phonepe_merchant_order_id', $merchantOrderId)
            ->where('payment_status', '!=', 'successful')
            ->update([
                'payment_status' => 'failed',
                'phonepe_transaction_id' => $transactionId,
            ]);
    }

    protected function sendSeekerSuccessMail(SeekerPackagePurchase $purchase): void
    {
        try {
            $user = $purchase->user;
            if ($user && $user->email && ! Identifier::isSyntheticEmail($user->email)) {
                Mail::to($user->email)->send(new JobSeekerPaymentSuccessMail($purchase));
            }
        } catch (\Throwable $e) {
            Log::warning('[PhonePe] Failed to send seeker payment email: '.$e->getMessage());
        }
    }
}
