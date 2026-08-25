<?php

namespace App\Providers;

use App\Services\PhonePe\PhonePeClient;
use Illuminate\Cache\RateLimiting\Limit;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\RateLimiter;
use Illuminate\Support\ServiceProvider;
use Symfony\Component\HttpFoundation\Response;

class AppServiceProvider extends ServiceProvider
{
    /**
     * Register any application services.
     */
    public function register(): void
    {
        $this->app->singleton(PhonePeClient::class);
    }

    /**
     * Bootstrap any application services.
     */
    public function boot(): void
    {
        $this->configureRateLimiting();
    }

    /**
     * Production auth / public API rate limits.
     *
     * Keys combine IP + identifier (when present) so shared NAT and targeted
     * credential stuffing are both constrained.
     */
    private function configureRateLimiting(): void
    {
        RateLimiter::for('api', function (Request $request) {
            return Limit::perMinute(120)
                ->by($request->user()?->id ?: $request->ip())
                ->response(fn (Request $request, array $headers) => $this->tooManyAttempts($headers));
        });

        // Password login (job seeker / employer).
        RateLimiter::for('auth-login', function (Request $request) {
            $id = $this->authIdentifierKey($request);

            return [
                Limit::perMinute(5)
                    ->by('login|ip|'.$request->ip())
                    ->response(fn (Request $request, array $headers) => $this->tooManyAttempts($headers, 'login')),
                Limit::perMinute(5)
                    ->by('login|id|'.$id)
                    ->response(fn (Request $request, array $headers) => $this->tooManyAttempts($headers, 'login')),
                Limit::perHour(40)
                    ->by('login|hour|'.$request->ip())
                    ->response(fn (Request $request, array $headers) => $this->tooManyAttempts($headers, 'login_hour')),
            ];
        });

        // Admin password login — stricter.
        RateLimiter::for('auth-admin-login', function (Request $request) {
            $user = strtolower(trim((string) $request->input('username', $request->input('identifier', ''))));

            return [
                Limit::perMinute(3)
                    ->by('admin-login|ip|'.$request->ip())
                    ->response(fn (Request $request, array $headers) => $this->tooManyAttempts($headers, 'login')),
                Limit::perMinute(3)
                    ->by('admin-login|user|'.$user.'|'.$request->ip())
                    ->response(fn (Request $request, array $headers) => $this->tooManyAttempts($headers, 'login')),
                Limit::perHour(20)
                    ->by('admin-login|hour|'.$request->ip())
                    ->response(fn (Request $request, array $headers) => $this->tooManyAttempts($headers, 'login_hour')),
            ];
        });

        // OTP send (legacy backend OTP — also protects if re-enabled).
        RateLimiter::for('auth-otp-send', function (Request $request) {
            $id = $this->authIdentifierKey($request);

            return [
                Limit::perMinute(3)
                    ->by('otp-send|ip|'.$request->ip())
                    ->response(fn (Request $request, array $headers) => $this->tooManyAttempts($headers, 'otp')),
                Limit::perMinute(2)
                    ->by('otp-send|id|'.$id)
                    ->response(fn (Request $request, array $headers) => $this->tooManyAttempts($headers, 'otp')),
                Limit::perHour(15)
                    ->by('otp-send|hour|'.$request->ip())
                    ->response(fn (Request $request, array $headers) => $this->tooManyAttempts($headers, 'otp_hour')),
            ];
        });

        // OTP verify / brute-force codes.
        RateLimiter::for('auth-otp-verify', function (Request $request) {
            $id = $this->authIdentifierKey($request);

            return [
                Limit::perMinute(8)
                    ->by('otp-verify|ip|'.$request->ip())
                    ->response(fn (Request $request, array $headers) => $this->tooManyAttempts($headers, 'otp_verify')),
                Limit::perMinute(5)
                    ->by('otp-verify|id|'.$id)
                    ->response(fn (Request $request, array $headers) => $this->tooManyAttempts($headers, 'otp_verify')),
                Limit::perHour(40)
                    ->by('otp-verify|hour|'.$request->ip())
                    ->response(fn (Request $request, array $headers) => $this->tooManyAttempts($headers, 'otp_verify_hour')),
            ];
        });

        // Firebase authenticate = OTP login + create account (app primary auth).
        RateLimiter::for('auth-firebase', function (Request $request) {
            $role = strtolower(trim((string) $request->input('role', '')));

            return [
                Limit::perMinute(10)
                    ->by('firebase|ip|'.$request->ip())
                    ->response(fn (Request $request, array $headers) => $this->tooManyAttempts($headers, 'auth')),
                Limit::perMinute(8)
                    ->by('firebase|role|'.$role.'|'.$request->ip())
                    ->response(fn (Request $request, array $headers) => $this->tooManyAttempts($headers, 'auth')),
                Limit::perHour(60)
                    ->by('firebase|hour|'.$request->ip())
                    ->response(fn (Request $request, array $headers) => $this->tooManyAttempts($headers, 'auth_hour')),
            ];
        });

        // Forgot / reset password after Firebase phone proof.
        RateLimiter::for('auth-password-reset', function (Request $request) {
            return [
                Limit::perMinute(5)
                    ->by('pw-reset|ip|'.$request->ip())
                    ->response(fn (Request $request, array $headers) => $this->tooManyAttempts($headers, 'password_reset')),
                Limit::perHour(15)
                    ->by('pw-reset|hour|'.$request->ip())
                    ->response(fn (Request $request, array $headers) => $this->tooManyAttempts($headers, 'password_reset_hour')),
            ];
        });

        // Authenticated password change / set.
        RateLimiter::for('auth-password-change', function (Request $request) {
            $key = $request->user()?->id ?: $request->ip();

            return [
                Limit::perMinute(6)
                    ->by('pw-change|'.$key)
                    ->response(fn (Request $request, array $headers) => $this->tooManyAttempts($headers, 'password_change')),
                Limit::perHour(20)
                    ->by('pw-change|hour|'.$key)
                    ->response(fn (Request $request, array $headers) => $this->tooManyAttempts($headers, 'password_change_hour')),
            ];
        });

        // Referral / promo validation (public).
        RateLimiter::for('auth-refer-validate', function (Request $request) {
            return [
                Limit::perMinute(20)
                    ->by('refer-validate|ip|'.$request->ip())
                    ->response(fn (Request $request, array $headers) => $this->tooManyAttempts($headers)),
                Limit::perHour(100)
                    ->by('refer-validate|hour|'.$request->ip())
                    ->response(fn (Request $request, array $headers) => $this->tooManyAttempts($headers)),
            ];
        });
    }

    private function authIdentifierKey(Request $request): string
    {
        $raw = (string) (
            $request->input('identifier')
            ?? $request->input('phone')
            ?? $request->input('email')
            ?? ''
        );

        $normalized = strtolower(preg_replace('/\s+/', '', trim($raw)) ?? '');

        return $normalized !== ''
            ? $normalized.'|'.$request->ip()
            : 'none|'.$request->ip();
    }

    private function tooManyAttempts(array $headers, string $context = 'default'): Response
    {
        $message = match ($context) {
            'login' => 'Too many login attempts. Please wait a minute and try again.',
            'login_hour' => 'Too many login attempts from this device. Please try again later.',
            'otp' => 'Too many OTP requests. Please wait before requesting another code.',
            'otp_hour' => 'OTP request limit reached. Please try again in an hour.',
            'otp_verify' => 'Too many incorrect OTP attempts. Please wait a minute and try again.',
            'otp_verify_hour' => 'OTP verification limit reached. Please try again later.',
            'auth' => 'Too many sign-in attempts. Please wait a minute and try again.',
            'auth_hour' => 'Too many account attempts from this device. Please try again later.',
            'password_reset' => 'Too many password reset attempts. Please wait a minute and try again.',
            'password_reset_hour' => 'Password reset limit reached. Please try again later.',
            'password_change', 'password_change_hour' => 'Too many password change attempts. Please wait and try again.',
            default => 'Too many requests. Please wait a moment and try again.',
        };

        return response()->json([
            'success' => false,
            'message' => $message,
            'data' => null,
        ], 429, $headers);
    }
}
