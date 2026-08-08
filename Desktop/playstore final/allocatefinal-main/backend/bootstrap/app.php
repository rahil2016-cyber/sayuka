<?php

use Illuminate\Foundation\Application;
use Illuminate\Foundation\Configuration\Exceptions;
use Illuminate\Foundation\Configuration\Middleware;
use Illuminate\Foundation\Http\Exceptions\MaintenanceModeException;
use Symfony\Component\HttpKernel\Exception\HttpExceptionInterface;

return Application::configure(basePath: dirname(__DIR__))
    ->withRouting(
        web: __DIR__.'/../routes/web.php',
        api: __DIR__.'/../routes/api.php',
        commands: __DIR__.'/../routes/console.php',
        health: '/up',
    )
    ->withMiddleware(function (Middleware $middleware): void {
        $middleware->alias([
            'role' => \App\Http\Middleware\EnsureUserRole::class,
        ]);
    })
    ->withExceptions(function (Exceptions $exceptions): void {
        $exceptions->render(function (\Throwable $e, $request) {
            // Force JSON responses for API routes (prevents HTML 503 pages breaking Flutter JSON decoding).
            $isApi = $request->is('api/*') || $request->expectsJson();
            if (! $isApi) {
                return null;
            }

            if ($e instanceof \Illuminate\Auth\AuthenticationException ||
                $e instanceof \Illuminate\Validation\ValidationException ||
                $e instanceof \Illuminate\Database\Eloquent\ModelNotFoundException ||
                $e instanceof \Illuminate\Auth\Access\AuthorizationException) {
                return null;
            }

            // Throttle middleware already returns JSON via RateLimiter::response();
            // keep a safe fallback if a bare 429 HttpException is thrown.
            if ($e instanceof \Illuminate\Http\Exceptions\ThrottleRequestsException) {
                return response()->json([
                    'success' => false,
                    'message' => 'Too many requests. Please wait a moment and try again.',
                    'data' => null,
                ], 429, $e->getHeaders());
            }

            $status = 500;
            $message = 'Server error.';

            if ($e instanceof MaintenanceModeException) {
                $status = 503;
                $message = 'Service temporarily unavailable.';
            } elseif ($e instanceof HttpExceptionInterface) {
                $status = $e->getStatusCode();
                if ($status === 429) {
                    $message = 'Too many requests. Please wait a moment and try again.';
                } else {
                    $message = $e->getMessage() ?: 'Request failed.';
                }
            } elseif ($e instanceof \Illuminate\Database\QueryException) {
                $raw = strtolower($e->getMessage());
                if (str_contains($raw, 'database is locked') || str_contains($raw, 'sqlstate[hy000]')) {
                    $status = 503;
                    $message = 'Server is busy. Please try again.';
                } else {
                    $message = 'A database error occurred. Please try again.';
                }
            } else {
                // Never leak raw stack / SQL / paths to mobile clients.
                $raw = $e->getMessage();
                $looksTechnical = $raw !== '' && (
                    str_contains(strtolower($raw), 'sqlstate') ||
                    str_contains(strtolower($raw), 'database/') ||
                    str_contains($raw, '/var/') ||
                    strlen($raw) > 180
                );
                $message = $looksTechnical ? $message : ($raw ?: $message);
            }

            return response()->json([
                'success' => false,
                'message' => $message,
                'data' => null,
            ], $status);
        });
    })->create();
