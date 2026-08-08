<?php

namespace App\Http\Controllers;

use Illuminate\Contracts\View\View;
use Illuminate\Http\Request;

/**
 * Public smart link for shared jobs.
 * Opens the Android app when installed; otherwise Play Store.
 */
class JobShareLandingController extends Controller
{
    public const PLAY_STORE_URL = 'https://play.google.com/store/apps/details?id=com.joballocate.in';

    public function show(Request $request, int $id): View
    {
        $scheme = 'joballocate';
        $deepLink = "{$scheme}://job/{$id}";
        $playStore = self::PLAY_STORE_URL;

        // No package= so any install that handles joballocate:// can open.
        // browser_fallback_url → Play Store when the app is missing.
        $intentUrl = 'intent://job/'.$id
            .'#Intent;scheme='.$scheme
            .';S.browser_fallback_url='.rawurlencode($playStore)
            .';end';

        return view('share.job', [
            'jobId' => $id,
            'deepLink' => $deepLink,
            'intentUrl' => $intentUrl,
            'playStoreUrl' => $playStore,
        ]);
    }
}
