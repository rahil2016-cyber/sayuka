<?php

use Illuminate\Support\Facades\Route;
use Illuminate\Support\Facades\Storage;
use App\Http\Controllers\LegalPageController;
use App\Http\Controllers\PrivacyController;
use App\Http\Controllers\JobShareLandingController;

$adminSpaIndexPath = resource_path('views/index.html');

$serveAdminSpa = static function () use ($adminSpaIndexPath) {
    if (! is_file($adminSpaIndexPath)) {
        abort(503, 'Admin front-end is not deployed (missing resources/views/index.html).');
    }

    return response()->file($adminSpaIndexPath);
};

Route::get('/', $serveAdminSpa);
Route::get('/privacy', [PrivacyController::class, 'show'])->name('privacy.show');
Route::post('/privacy/account-deletion-request', [PrivacyController::class, 'submitDeletionRequest'])
    ->name('privacy.account-deletion-request');

/*
| Public legal pages (no auth). Registered before the admin SPA catch-all so
| /terms-and-conditions etc. are not swallowed by the login-gated SPA.
*/
Route::get('/terms-and-conditions', [LegalPageController::class, 'terms'])
    ->name('legal.terms');
Route::get('/privacy-policy', [LegalPageController::class, 'privacyPolicy'])
    ->name('legal.privacy-policy');
Route::get('/refund-policy', [LegalPageController::class, 'refundPolicy'])
    ->name('legal.refund-policy');

/*
| Shared job smart link: opens app if installed, else Play Store.
*/
Route::get('/share/job/{id}', [JobShareLandingController::class, 'show'])
    ->whereNumber('id')
    ->name('share.job');

/*
| Banner images: many hosts return 403 for /storage/* (permissions, nginx rules, missing symlink).
| This route streams files from storage/app/public/banner-ads — no symlink required.
*/
Route::get('/media/banner-ads/{file}', function (string $file) {
    $file = basename($file);
    if ($file === '' || ! preg_match('/^[a-zA-Z0-9._-]+$/', $file)) {
        abort(404);
    }

    $path = 'banner-ads/'.$file;
    if (! Storage::disk('public')->exists($path)) {
        abort(404);
    }

    return Storage::disk('public')->response($path, null, [
        'Cache-Control' => 'public, max-age=300, must-revalidate',
    ]);
})->where('file', '[a-zA-Z0-9._-]+');

/*
| Job seeker resumes (PDF): stream from storage/app/public/resumes — no symlink required.
*/
Route::get('/media/resumes/{file}', function (string $file) {
    $file = basename($file);
    if ($file === '' || ! preg_match('/^[a-zA-Z0-9._-]+$/', $file)) {
        abort(404);
    }

    $path = 'resumes/'.$file;
    if (! Storage::disk('public')->exists($path)) {
        abort(404);
    }

    return Storage::disk('public')->response($path, null, [
        'Cache-Control' => 'public, max-age=3600',
    ]);
})->where('file', '[a-zA-Z0-9._-]+');

/*
| Job seeker profile photos & company logos: same 403 issue as banner-ads when /storage is blocked.
| Stream from storage/app/public/profile-photos and company-logos.
*/
Route::get('/media/profile-photos/{file}', function (string $file) {
    $file = basename($file);
    if ($file === '' || ! preg_match('/^[a-zA-Z0-9._-]+$/', $file)) {
        abort(404);
    }

    $path = 'profile-photos/'.$file;
    if (! Storage::disk('public')->exists($path)) {
        abort(404);
    }

    return Storage::disk('public')->response($path, null, [
        'Cache-Control' => 'public, max-age=86400',
    ]);
})->where('file', '[a-zA-Z0-9._-]+');

Route::get('/media/company-logos/{file}', function (string $file) {
    $file = basename($file);
    if ($file === '' || ! preg_match('/^[a-zA-Z0-9._-]+$/', $file)) {
        abort(404);
    }

    $path = 'company-logos/'.$file;
    if (! Storage::disk('public')->exists($path)) {
        abort(404);
    }

    return Storage::disk('public')->response($path, null, [
        'Cache-Control' => 'public, max-age=86400',
    ]);
})->where('file', '[a-zA-Z0-9._-]+');

/*
| Admin SPA deep links (/login, /dashboard, …): must be registered after /media/* so
| those paths are not swallowed. /api/* is registered earlier (see bootstrap/app.php).
| /assets/* is normally served as static files from public/assets.
*/
Route::get('/{any}', $serveAdminSpa)
    ->where('any', '^(?!terms-and-conditions$|privacy-policy$|refund-policy$|privacy$|share\/job\/\d+$).*');
