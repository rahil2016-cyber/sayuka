<?php

namespace App\Http\Controllers\Api\V1\Company;

use App\Http\Concerns\ApiResponses;
use App\Http\Controllers\Controller;
use App\Models\Company;
use App\Models\CompanyCoupon;
use App\Models\CompanySubscriptionPayment;
use App\Models\CompanySubscriptionPackage;
use App\Services\PhonePe\PhonePeClient;
use App\Services\PhonePe\PhonePePaymentFulfillment;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Log;
use Illuminate\Support\Str;

class CompanySubscriptionController extends Controller
{
    use ApiResponses;

    public function __construct(
        protected PhonePeClient $phonePe,
        protected PhonePePaymentFulfillment $fulfillment,
    ) {}

    private function inferStateDistrictFromLocation(Company $company): array
    {
        $state = $company->state;
        $district = $company->district;

        if ((filled($state) && filled($district)) || ! filled($company->location)) {
            return [$state, $district];
        }

        $parts = array_values(array_filter(array_map(
            fn ($p) => trim((string) $p),
            explode(',', (string) $company->location)
        ), fn ($p) => $p !== ''));

        // Common legacy format: "city, district, state"
        if (! filled($state) && count($parts) >= 1) {
            $state = $parts[count($parts) - 1];
        }
        if (! filled($district) && count($parts) >= 2) {
            $district = $parts[count($parts) - 2];
        }

        return [$state, $district];
    }

    private function matchCouponToCompany(CompanyCoupon $coupon, Company $company): bool
    {
        $targetType = (string) $coupon->target_type;
        $needle = mb_strtolower(trim($coupon->target_value));

        if ($targetType === 'all') {
            return true;
        }

        if ($needle === '') {
            return false;
        }

        if ($targetType === 'state') {
            [$s] = $this->inferStateDistrictFromLocation($company);
            return $s !== null && mb_strtolower(trim($s)) === $needle;
        }

        if ($targetType === 'district') {
            [, $d] = $this->inferStateDistrictFromLocation($company);
            return $d !== null && mb_strtolower(trim($d)) === $needle;
        }

        return false;
    }

    public function offer(Request $request): JsonResponse
    {
        try {
            $company = $request->user()->company;

            if (! $company) {
                return $this->fail('Company profile not found.', null, 404);
            }

            $verified = $company->isVerified();

            $successfulPaymentsCount = $company->subscriptionPayments()
                ->where('payment_status', 'successful')
                ->count();

            $totalJobsCount = \App\Models\JobPost::query()
                ->where('company_id', $company->id)
                ->count();

            $hasActiveSubscription = $successfulPaymentsCount >= $totalJobsCount;

            $activePackage = CompanySubscriptionPackage::query()
                ->where('is_active', true)
                ->orderByDesc('sort_order')
                ->orderByDesc('id')
                ->first();

            $packageId = $activePackage?->id;
            $monthlyPriceInr = (int) ($activePackage?->monthly_price_inr ?? 499);
            $packageTitle = (string) ($activePackage?->title ?? 'Company Subscription');

            if ($packageId === null) {
                return $this->ok([
                    'verified' => $verified,
                    'has_active_subscription' => false,
                    'package_title' => $packageTitle,
                    'monthly_price_inr' => $monthlyPriceInr,
                    'first_month' => [
                        'already_purchased' => false,
                        'is_free_eligible' => false,
                        'eligible_coupon_codes' => [],
                        'suggested_coupon_code' => null,
                        'message' => 'No active subscription package configured by admin yet.',
                    ],
                ]);
            }

        $cycle1 = CompanySubscriptionPayment::query()
            ->when($packageId !== null, fn ($q) => $q
                ->where(function ($qq) use ($packageId): void {
                    $qq->where('company_subscription_package_id', $packageId)
                        ->orWhereNull('company_subscription_package_id');
                })
            )
            ->where('company_id', $company->id)
            ->where('cycle_number', 1)
            ->first();

        $alreadyPurchasedFirstMonth = $cycle1 !== null;

        [$state, $district] = $this->inferStateDistrictFromLocation($company);

        $eligibleCoupons = CompanyCoupon::query()
            ->where('is_active', true)
            ->when($packageId !== null, fn ($q) => $q
                ->where(function ($qq) use ($packageId): void {
                    $qq->where('company_subscription_package_id', $packageId)
                        ->orWhereNull('company_subscription_package_id');
                })
            )
            ->where('free_first_month', true)
            ->where(function ($q) use ($state, $district): void {
                // General "All India" coupons.
                $q->where('target_type', 'all');

                if ($state) {
                    $q->orWhere(function ($qq) use ($state): void {
                        $qq->where('target_type', 'state')
                            ->whereRaw('lower(target_value) = ?', [mb_strtolower(trim($state))]);
                    });
                }

                if ($district) {
                    $q->orWhere(function ($qq) use ($district): void {
                        $qq->where('target_type', 'district')
                            ->whereRaw('lower(target_value) = ?', [mb_strtolower(trim($district))]);
                    });
                }
            })
            ->orderByDesc('id')
            ->get();

        $eligibleFreeCoupons = $eligibleCoupons->values();

        if (! $verified) {
            return $this->ok([
                'verified' => false,
                'has_active_subscription' => $hasActiveSubscription,
                'package_title' => $packageTitle,
                'monthly_price_inr' => $monthlyPriceInr,
                'first_month' => [
                    'already_purchased' => $alreadyPurchasedFirstMonth,
                    'is_free_eligible' => false,
                    'eligible_coupon_codes' => [],
                    'suggested_coupon_code' => null,
                    'message' => 'Your company is not verified yet. Free month eligibility will appear after verification.',
                ],
                'renewal' => [
                    'message' => 'After your first purchase, coupon codes can give renewal discounts.',
                ],
            ]);
        }

        if ($alreadyPurchasedFirstMonth) {
            return $this->ok([
                'verified' => true,
                'has_active_subscription' => $hasActiveSubscription,
                'package_title' => $packageTitle,
                'monthly_price_inr' => $monthlyPriceInr,
                'first_month' => [
                    'already_purchased' => true,
                    'is_free_eligible' => false,
                    'eligible_coupon_codes' => [],
                    'suggested_coupon_code' => null,
                    'message' => 'You already used your 1st month slot.',
                ],
                'renewal' => [
                    'message' => 'Use an eligible coupon code for renewal discounts.',
                ],
            ]);
        }

        if ($eligibleFreeCoupons->isEmpty()) {
            return $this->ok([
                'verified' => true,
                'has_active_subscription' => $hasActiveSubscription,
                'package_title' => $packageTitle,
                'monthly_price_inr' => $monthlyPriceInr,
                'first_month' => [
                    'already_purchased' => false,
                    'is_free_eligible' => false,
                    'eligible_coupon_codes' => [],
                    'suggested_coupon_code' => null,
                    'message' => 'Your state/district is not eligible for 1st month free. First month price is ₹'.$monthlyPriceInr.'.',
                ],
                'renewal' => [
                    'message' => 'For next months, eligible coupons can provide % renewal discounts.',
                ],
            ]);
        }

        $suggested = $eligibleFreeCoupons->first();

            return $this->ok([
            'verified' => true,
            'has_active_subscription' => $hasActiveSubscription,
            'package_title' => $packageTitle,
            'monthly_price_inr' => $monthlyPriceInr,
            'first_month' => [
                'already_purchased' => false,
                'is_free_eligible' => true,
                'eligible_coupon_codes' => $eligibleFreeCoupons->map(fn (CompanyCoupon $c) => $c->code)->values()->all(),
                'suggested_coupon_code' => $suggested->code,
                'message' => 'You are eligible for 1st month free. Use coupon code to activate.',
            ],
            'renewal' => [
                'message' => 'For next months, eligible coupons can provide % renewal discounts.',
            ],
            ]);
        } catch (\Throwable $e) {
            return $this->fail($e->getMessage() ?: 'Failed to load subscription offer.', null, 500);
        }
    }

    public function purchase(Request $request): JsonResponse
    {
        $company = $request->user()->company;

        if (! $company) {
            return $this->fail('Company profile not found.', null, 404);
        }

        $activePackage = CompanySubscriptionPackage::query()
            ->where('is_active', true)
            ->orderByDesc('sort_order')
            ->orderByDesc('id')
            ->first();

        $packageId = $activePackage?->id;
        $packageTitle = (string) ($activePackage?->title ?? 'Company Subscription');
        $monthlyPriceInr = (int) ($activePackage?->monthly_price_inr ?? 499);

        $nextCycle = (int) (CompanySubscriptionPayment::query()
            ->when($packageId !== null, fn ($q) => $q
                ->where(function ($qq) use ($packageId): void {
                    $qq->where('company_subscription_package_id', $packageId)
                        ->orWhereNull('company_subscription_package_id');
                })
            )
            ->where('company_id', $company->id)
            ->max('cycle_number') ?? 0) + 1;

        try {
            // Monthly Price + 18% GST (1 INR = 100 paise)
            $amountInPaise = (int) round($monthlyPriceInr * 1.18 * 100);
            $merchantOrderId = substr('SUB_'.Str::upper(Str::random(8)).'_'.time(), 0, 63);

            $order = $this->phonePe->createSdkOrder($merchantOrderId, $amountInPaise, [
                'udf1' => 'company_subscription',
                'udf2' => (string) $company->id,
                'udf3' => (string) ($packageId ?? ''),
            ]);

            CompanySubscriptionPayment::create([
                'company_id' => $company->id,
                'company_subscription_package_id' => $packageId,
                'cycle_number' => $nextCycle,
                'coupon_code_used' => null,
                'amount_inr' => (int) round($monthlyPriceInr * 1.18),
                'is_free' => false,
                'payment_status' => 'pending',
                'phonepe_merchant_order_id' => $merchantOrderId,
                'phonepe_order_id' => $order['orderId'],
                'purchased_at' => null,
            ]);

            return $this->ok([
                'merchant_order_id' => $merchantOrderId,
                'order_id' => $order['orderId'],
                'token' => $order['token'],
                'merchant_id' => $this->phonePe->merchantId(),
                'environment' => $this->phonePe->sdkEnvironment(),
                'amount' => $amountInPaise,
                'currency' => 'INR',
                'package_title' => $packageTitle,
            ], 'PhonePe order created successfully.');
        } catch (\Throwable $e) {
            Log::error('Company PhonePe order creation failed: '.$e->getMessage(), ['exception' => $e]);

            return $this->fail('PhonePe order creation failed: '.$e->getMessage(), null, 500);
        }
    }

    public function confirmStatus(Request $request): JsonResponse
    {
        $validated = $request->validate([
            'merchant_order_id' => ['required', 'string', 'max:64'],
        ]);

        $company = $request->user()->company;
        if (! $company) {
            return $this->fail('Company profile not found.', null, 404);
        }

        try {
            $result = $this->fulfillment->confirmCompanyPayment(
                $validated['merchant_order_id'],
                $company->id,
            );
        } catch (\Throwable $e) {
            return $this->fail('Verification error: '.$e->getMessage(), null, 500);
        }

        if ($result['status'] === 'not_found') {
            return $this->fail($result['message'], null, 404);
        }

        if ($result['status'] === 'failed') {
            return $this->fail($result['message'], [
                'payment_status' => 'failed',
                'merchant_order_id' => $validated['merchant_order_id'],
            ], 400);
        }

        if ($result['status'] === 'pending') {
            return $this->ok([
                'payment_status' => 'pending',
                'merchant_order_id' => $validated['merchant_order_id'],
            ], $result['message']);
        }

        return $this->ok([
            'payment_status' => 'successful',
            'merchant_order_id' => $validated['merchant_order_id'],
            'payment_id' => $result['payment']?->id,
        ], $result['message']);
    }

    public function history(Request $request): JsonResponse
    {
        $company = $request->user()->company;
        if (! $company) {
            return $this->fail('Company profile not found.', null, 404);
        }

        $rows = CompanySubscriptionPayment::query()
            ->with('package:id,title')
            ->where('company_id', $company->id)
            ->orderByDesc('id')
            ->limit(60)
            ->get()
            ->map(fn (CompanySubscriptionPayment $p) => [
                'id' => $p->id,
                'cycle_number' => (int) $p->cycle_number,
                'amount_inr' => (int) $p->amount_inr,
                'is_free' => (bool) $p->is_free,
                'coupon_code_used' => $p->coupon_code_used,
                'payment_status' => $p->payment_status,
                'purchased_at' => $p->purchased_at?->toISOString(),
                'package_id' => $p->company_subscription_package_id,
                'package_title' => $p->package?->title,
                'phonepe_merchant_order_id' => $p->phonepe_merchant_order_id,
                'phonepe_transaction_id' => $p->phonepe_transaction_id,
            ])
            ->values()
            ->all();

        return $this->ok(['items' => $rows]);
    }
}

