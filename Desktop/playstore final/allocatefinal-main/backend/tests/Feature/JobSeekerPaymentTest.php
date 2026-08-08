<?php

namespace Tests\Feature;

use App\Models\SeekerPackage;
use App\Models\SeekerPackagePurchase;
use App\Models\User;
use App\Services\PhonePe\PhonePeClient;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Laravel\Sanctum\Sanctum;
use Mockery;
use Tests\TestCase;

class JobSeekerPaymentTest extends TestCase
{
    use RefreshDatabase;

    protected function setUp(): void
    {
        parent::setUp();
        config([
            'services.phonepe.client_id' => 'test_client',
            'services.phonepe.client_secret' => 'test_secret',
            'services.phonepe.client_version' => '1',
            'services.phonepe.merchant_id' => 'TESTMERCHANT',
            'services.phonepe.env' => 'sandbox',
            'services.phonepe.webhook_username' => 'hook_user',
            'services.phonepe.webhook_password' => 'hook_pass',
        ]);
    }

    protected function tearDown(): void
    {
        Mockery::close();
        parent::tearDown();
    }

    public function test_create_order_requires_authentication(): void
    {
        $response = $this->postJson('/api/v1/job-seeker/payments/create-order', [
            'package_key' => 'basic_resume',
        ]);

        $response->assertStatus(401);
    }

    public function test_create_order_fails_with_invalid_package(): void
    {
        $user = User::factory()->create(['role' => 'job_seeker']);
        Sanctum::actingAs($user);

        $response = $this->postJson('/api/v1/job-seeker/payments/create-order', [
            'package_key' => 'invalid_package_key',
        ]);

        $response->assertStatus(404);
    }

    public function test_create_order_succeeds_and_creates_pending_purchase(): void
    {
        $user = User::factory()->create(['role' => 'job_seeker']);
        Sanctum::actingAs($user);

        $pkg = SeekerPackage::create([
            'key' => 'basic_resume',
            'title' => 'Basic Resume',
            'description' => 'Test',
            'kind' => 'resume',
            'price_inr' => 99,
            'duration_days' => 30,
            'applications_included' => 0,
            'resume_builds_included' => 5,
            'is_active' => true,
        ]);

        $mock = Mockery::mock(PhonePeClient::class);
        $mock->shouldReceive('createSdkOrder')
            ->once()
            ->andReturn([
                'orderId' => 'OMO_test_123',
                'state' => 'PENDING',
                'expireAt' => null,
                'token' => 'order_token_abc',
            ]);
        $mock->shouldReceive('merchantId')->andReturn('TESTMERCHANT');
        $mock->shouldReceive('sdkEnvironment')->andReturn('SANDBOX');
        $this->app->instance(PhonePeClient::class, $mock);

        $response = $this->postJson('/api/v1/job-seeker/payments/create-order', [
            'package_key' => 'basic_resume',
        ]);

        $response->assertOk()
            ->assertJsonPath('success', true)
            ->assertJsonPath('data.order_id', 'OMO_test_123')
            ->assertJsonPath('data.amount', 9900)
            ->assertJsonPath('data.merchant_id', 'TESTMERCHANT')
            ->assertJsonPath('data.environment', 'SANDBOX');

        $merchantOrderId = $response->json('data.merchant_order_id');
        $this->assertNotEmpty($merchantOrderId);

        $this->assertDatabaseHas('seeker_package_purchases', [
            'user_id' => $user->id,
            'package_key' => 'basic_resume',
            'payment_status' => 'pending',
            'phonepe_merchant_order_id' => $merchantOrderId,
            'phonepe_order_id' => 'OMO_test_123',
            'activated_at' => null,
            'expires_at' => null,
        ]);
    }

    public function test_confirm_status_succeeds_and_activates_credits(): void
    {
        $user = User::factory()->create(['role' => 'job_seeker']);
        Sanctum::actingAs($user);

        $pkg = SeekerPackage::create([
            'key' => 'basic_resume',
            'title' => 'Basic Resume',
            'description' => 'Test',
            'kind' => 'resume',
            'price_inr' => 99,
            'duration_days' => 30,
            'applications_included' => 0,
            'resume_builds_included' => 5,
            'is_active' => true,
        ]);

        $purchase = SeekerPackagePurchase::create([
            'user_id' => $user->id,
            'seeker_package_id' => $pkg->id,
            'package_key' => $pkg->key,
            'title' => $pkg->title,
            'kind' => $pkg->kind,
            'price_inr' => $pkg->price_inr,
            'duration_days' => $pkg->duration_days,
            'applications_granted' => 0,
            'resume_builds_granted' => 5,
            'payment_status' => 'pending',
            'phonepe_merchant_order_id' => 'SKR_TEST_123',
            'phonepe_order_id' => 'OMO_test_123',
            'activated_at' => null,
            'expires_at' => null,
        ]);

        $mock = Mockery::mock(PhonePeClient::class);
        $mock->shouldReceive('getOrderStatus')
            ->once()
            ->with('SKR_TEST_123')
            ->andReturn([
                'orderId' => 'OMO_test_123',
                'state' => 'COMPLETED',
                'paymentDetails' => [
                    ['transactionId' => 'TXN_999', 'state' => 'COMPLETED'],
                ],
            ]);
        $mock->shouldReceive('extractTransactionId')
            ->andReturnUsing(fn (array $status) => 'TXN_999');
        $this->app->instance(PhonePeClient::class, $mock);

        $response = $this->postJson('/api/v1/job-seeker/payments/confirm-status', [
            'merchant_order_id' => 'SKR_TEST_123',
        ]);

        $response->assertOk()
            ->assertJsonPath('success', true)
            ->assertJsonPath('data.payment_status', 'successful');

        $this->assertDatabaseHas('seeker_package_purchases', [
            'id' => $purchase->id,
            'payment_status' => 'successful',
            'phonepe_transaction_id' => 'TXN_999',
        ]);

        $this->assertDatabaseHas('job_seeker_profiles', [
            'user_id' => $user->id,
            'resume_builds_remaining' => 5,
            'resume_package_key' => 'basic_resume',
        ]);
    }

    public function test_confirm_status_failed_updates_payment_status(): void
    {
        $user = User::factory()->create(['role' => 'job_seeker']);
        Sanctum::actingAs($user);

        $pkg = SeekerPackage::create([
            'key' => 'basic_resume',
            'title' => 'Basic Resume',
            'description' => 'Test',
            'kind' => 'resume',
            'price_inr' => 99,
            'duration_days' => 30,
            'applications_included' => 0,
            'resume_builds_included' => 5,
            'is_active' => true,
        ]);

        $purchase = SeekerPackagePurchase::create([
            'user_id' => $user->id,
            'seeker_package_id' => $pkg->id,
            'package_key' => $pkg->key,
            'title' => $pkg->title,
            'kind' => $pkg->kind,
            'price_inr' => $pkg->price_inr,
            'duration_days' => $pkg->duration_days,
            'applications_granted' => 0,
            'resume_builds_granted' => 5,
            'payment_status' => 'pending',
            'phonepe_merchant_order_id' => 'SKR_FAIL_123',
            'phonepe_order_id' => 'OMO_fail',
            'activated_at' => null,
            'expires_at' => null,
        ]);

        $mock = Mockery::mock(PhonePeClient::class);
        $mock->shouldReceive('getOrderStatus')
            ->once()
            ->andReturn([
                'orderId' => 'OMO_fail',
                'state' => 'FAILED',
                'paymentDetails' => [],
            ]);
        $mock->shouldReceive('extractTransactionId')->andReturn(null);
        $this->app->instance(PhonePeClient::class, $mock);

        $response = $this->postJson('/api/v1/job-seeker/payments/confirm-status', [
            'merchant_order_id' => 'SKR_FAIL_123',
        ]);

        $response->assertStatus(400);

        $this->assertDatabaseHas('seeker_package_purchases', [
            'id' => $purchase->id,
            'payment_status' => 'failed',
        ]);
    }

    public function test_webhook_fails_without_authorization(): void
    {
        $response = $this->postJson('/api/v1/payments/webhook', [
            'event' => 'checkout.order.completed',
        ]);

        $response->assertStatus(401);
    }

    public function test_webhook_processes_completed_event_and_activates_package(): void
    {
        $user = User::factory()->create(['role' => 'job_seeker']);

        $pkg = SeekerPackage::create([
            'key' => 'basic_resume',
            'title' => 'Basic Resume',
            'description' => 'Test',
            'kind' => 'resume',
            'price_inr' => 99,
            'duration_days' => 30,
            'applications_included' => 0,
            'resume_builds_included' => 5,
            'is_active' => true,
        ]);

        $purchase = SeekerPackagePurchase::create([
            'user_id' => $user->id,
            'seeker_package_id' => $pkg->id,
            'package_key' => $pkg->key,
            'title' => $pkg->title,
            'kind' => $pkg->kind,
            'price_inr' => $pkg->price_inr,
            'duration_days' => $pkg->duration_days,
            'applications_granted' => 0,
            'resume_builds_granted' => 5,
            'payment_status' => 'pending',
            'phonepe_merchant_order_id' => 'SKR_WEBHOOK_123',
            'phonepe_order_id' => 'OMO_webhook',
            'activated_at' => null,
            'expires_at' => null,
        ]);

        $auth = hash('sha256', 'hook_user:hook_pass');

        $response = $this->withHeaders([
            'Authorization' => $auth,
        ])->postJson('/api/v1/payments/webhook', [
            'event' => 'checkout.order.completed',
            'payload' => [
                'orderId' => 'OMO_webhook',
                'merchantOrderId' => 'SKR_WEBHOOK_123',
                'state' => 'COMPLETED',
                'paymentDetails' => [
                    [
                        'transactionId' => 'TXN_WEBHOOK_1',
                        'state' => 'COMPLETED',
                    ],
                ],
            ],
        ]);

        $response->assertOk()
            ->assertJsonPath('success', true);

        $this->assertDatabaseHas('seeker_package_purchases', [
            'id' => $purchase->id,
            'payment_status' => 'successful',
            'phonepe_transaction_id' => 'TXN_WEBHOOK_1',
        ]);

        $this->assertDatabaseHas('job_seeker_profiles', [
            'user_id' => $user->id,
            'resume_builds_remaining' => 5,
            'resume_package_key' => 'basic_resume',
        ]);
    }
}
