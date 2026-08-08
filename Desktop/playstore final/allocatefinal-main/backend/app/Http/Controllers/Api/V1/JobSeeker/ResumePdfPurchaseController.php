<?php

namespace App\Http\Controllers\Api\V1\JobSeeker;

use App\Http\Concerns\ApiResponses;
use App\Http\Controllers\Controller;
use App\Models\SeekerPackage;
use App\Models\SeekerPackagePurchase;
use App\Services\PhonePe\PhonePeClient;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Log;
use Illuminate\Support\Str;

/**
 * Paid resume PDF export via PhonePe (sandbox/production).
 */
class ResumePdfPurchaseController extends Controller
{
    use ApiResponses;

    public const PACKAGE_KEY = 'resume_pdf_export_20';

    public function __construct(
        protected PhonePeClient $phonePe,
    ) {}

    public function createOrder(Request $request): JsonResponse
    {
        $validated = $request->validate([
            'resume_template_id' => ['required', 'integer', 'min:1'],
            'resume_template_title' => ['required', 'string', 'max:200'],
        ]);

        $package = SeekerPackage::query()->where('key', self::PACKAGE_KEY)->first();
        if (! $package) {
            return $this->fail('Resume PDF package is not configured.', null, 404);
        }

        $user = $request->user();
        $profile = $user->jobSeekerProfile;

        if (! $profile || ! $profile->canBuildResume()) {
            return $this->fail('Resume download is restricted to users with an active subscription.', null, 403);
        }

        try {
            $price = (int) $package->price_inr;
            $amountInPaise = max(100, $price * 100);
            $merchantOrderId = substr('PDF_'.Str::upper(Str::random(8)).'_'.time(), 0, 63);

            $order = $this->phonePe->createSdkOrder($merchantOrderId, $amountInPaise, [
                'udf1' => 'resume_pdf',
                'udf2' => (string) $user->id,
                'udf3' => (string) $validated['resume_template_id'],
            ]);

            SeekerPackagePurchase::query()->create([
                'user_id' => $user->id,
                'seeker_package_id' => $package->id,
                'package_key' => self::PACKAGE_KEY,
                'title' => 'Resume PDF — '.$validated['resume_template_title'],
                'kind' => 'resume_pdf',
                'price_inr' => $price,
                'duration_days' => 0,
                'applications_granted' => 0,
                'resume_builds_granted' => 0,
                'payment_status' => 'pending',
                'phonepe_merchant_order_id' => $merchantOrderId,
                'phonepe_order_id' => $order['orderId'],
                'resume_template_id' => $validated['resume_template_id'],
                'resume_template_title' => $validated['resume_template_title'],
                'activated_at' => null,
                'expires_at' => null,
            ]);

            return $this->ok([
                'merchant_order_id' => $merchantOrderId,
                'order_id' => $order['orderId'],
                'token' => $order['token'],
                'merchant_id' => $this->phonePe->merchantId(),
                'environment' => $this->phonePe->sdkEnvironment(),
                'amount' => $amountInPaise,
                'currency' => 'INR',
                'price_inr' => $price,
                'resume_template_id' => $validated['resume_template_id'],
                'resume_template_title' => $validated['resume_template_title'],
            ], 'PhonePe PDF order created successfully.');
        } catch (\Throwable $e) {
            Log::error('PhonePe resume PDF order creation failed: '.$e->getMessage(), ['exception' => $e]);

            return $this->fail('PhonePe order creation failed: '.$e->getMessage(), null, 500);
        }
    }

    /**
     * Legacy alias — kept for older clients; prefers create-order + confirm-status.
     */
    public function purchase(Request $request): JsonResponse
    {
        return $this->createOrder($request);
    }
}
