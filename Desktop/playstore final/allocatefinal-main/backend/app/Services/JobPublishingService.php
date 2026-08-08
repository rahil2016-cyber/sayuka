<?php

namespace App\Services;

use App\Enums\CompanyVerificationStatus;
use App\Enums\JobPostStatus;
use App\Models\Company;
use App\Models\JobPost;

final class JobPublishingService
{
    public function __construct(
        private readonly PlatformSettingService $settings
    ) {}

    /**
     * New job visibility. When [config joballocate.auto_publish_new_jobs] is true,
     * jobs go live immediately (until admin moderation is enabled).
     * Otherwise: verified companies publish; others stay pending_review.
     */
    public function initialStatusForNewJob(Company $company): array
    {
        if ($this->settings->autoPublishJobs()) {
            return [
                'status' => JobPostStatus::Published,
                'published_at' => now(),
            ];
        }

        if ($company->verification_status === CompanyVerificationStatus::Verified) {
            return [
                'status' => JobPostStatus::Published,
                'published_at' => now(),
            ];
        }

        return [
            'status' => JobPostStatus::PendingReview,
            'published_at' => null,
        ];
    }

    public function publish(JobPost $job): void
    {
        $job->update([
            'status' => JobPostStatus::Published,
            'published_at' => now(),
            'review_note' => null,
        ]);

        $this->notifyMatchingJobSeekers($job);
    }

    public function notifyMatchingJobSeekers(JobPost $job): void
    {
        try {
            $notifier = app(NotificationSender::class);
            $query = \App\Models\JobSeekerProfile::query()->with('user');

            if (filled($job->industry_type)) {
                $query->where('industry_type', $job->industry_type);
            }

            // Limit broadcast to top 200 matching active candidates to avoid timeout
            $profiles = $query->limit(200)->get();

            foreach ($profiles as $profile) {
                if ($profile->user && $profile->user->is_active) {
                    $notifier->newJobMatch($profile->user, $job->title, $job->id);
                }
            }
        } catch (\Throwable $e) {
            \Illuminate\Support\Facades\Log::warning('[JobPublishingService] Failed to send job match notifications: ' . $e->getMessage());
        }
    }

    public function reject(JobPost $job, ?string $note = null): void
    {
        $job->update([
            'status' => JobPostStatus::Rejected,
            'published_at' => null,
            'review_note' => $note,
        ]);
    }

    public function unpublish(JobPost $job, ?string $note = null): void
    {
        $job->update([
            'status' => JobPostStatus::PendingReview,
            'published_at' => null,
            'review_note' => $note,
        ]);
    }
}
