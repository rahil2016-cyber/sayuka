<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\User;
use App\Services\NotificationSender;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

/**
 * Admin-only broadcast notification panel.
 *
 * Route:
 *  POST /api/v1/admin/send-notification
 *
 * Payload:
 *  {
 *    "title":    "string",
 *    "body":     "string",
 *    "audience": "all | job_seekers | employers | premium_employers"
 *  }
 *
 * Notes:
 *  - Requires super_admin Bearer token.
 *  - Push only reaches users who have registered an FCM device token.
 *  - Employer role in DB is `company` (audience value stays `employers` for the API).
 */
class AdminNotificationController extends Controller
{
    public function __construct(private NotificationSender $sender) {}

    public function send(Request $request): JsonResponse
    {
        $validated = $request->validate([
            'title'    => 'required|string|max:255',
            'body'     => 'required|string|max:1000',
            'audience' => 'nullable|string|in:all,job_seekers,employers,students,premium_employers,user',
            'user_id'  => 'nullable|integer|exists:users,id',
        ]);

        $audienceKey = $validated['audience'] ?? ($validated['user_id'] ? 'user' : 'all');
        $users = $this->resolveAudience($audienceKey, $validated['user_id'] ?? null);

        $count = $this->sender->broadcast(
            $users,
            $validated['title'],
            $validated['body'],
            ['type' => 'announcement']
        );

        return response()->json([
            'message'          => 'Notifications dispatched.',
            'recipients_count' => $count,
            'audience'         => $audienceKey,
        ]);
    }

    private function resolveAudience(string $audience, ?int $userId = null)
    {
        if ($userId !== null || $audience === 'user') {
            return User::query()->where('id', $userId)->get();
        }

        return match ($audience) {
            'job_seekers', 'students' => User::query()->where('role', 'job_seeker')->get(),
            'employers' => User::query()->where('role', 'company')->get(),
            'premium_employers' => $this->premiumEmployers(),
            // App users only (exclude admin accounts).
            default => User::query()->whereIn('role', ['job_seeker', 'company'])->get(),
        };
    }

    /**
     * Return users whose company has an active premium subscription.
     */
    private function premiumEmployers()
    {
        return User::query()
            ->where('role', 'company')
            ->whereHas('company', function ($q) {
                $q->whereHas('subscriptionPayments', function ($sq) {
                    $sq->where('payment_status', 'successful')
                        ->where('purchased_at', '>=', now()->subDays(31));
                });
            })
            ->get();
    }
}
