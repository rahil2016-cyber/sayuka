<?php

namespace App\Http\Controllers;

use Illuminate\View\View;

/**
 * Public legal pages — no auth. Must stay outside the admin SPA catch-all.
 */
class LegalPageController extends Controller
{
    public function terms(): View
    {
        return view('legal.terms');
    }

    public function privacyPolicy(): View
    {
        return view('legal.privacy-policy');
    }

    public function refundPolicy(): View
    {
        return view('legal.refund-policy');
    }
}
