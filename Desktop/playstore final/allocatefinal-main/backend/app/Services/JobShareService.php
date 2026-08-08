<?php

namespace App\Services;

use App\Models\JobPost;

final class JobShareService
{
    public const DEFAULT_PLAY_STORE_URL = 'https://play.google.com/store/apps/details?id=com.joballocate.in';

    public function __construct(
        private readonly PlatformSettingService $platformSettings
    ) {}

    /**
     * @return array{
     *   job_id: int,
     *   job_title: string,
     *   company_name: string,
     *   location: string|null,
     *   app_link: string,
     *   web_link: string|null,
     *   share_text: string,
     *   play_store_available: bool
     * }
     */
    public function payloadForJob(JobPost $job): array
    {
        $links = $this->platformSettings->appLinkSettings();
        $scheme = $links['deep_link_scheme'] ?: 'joballocate';
        $jobId = (int) $job->id;
        $appLink = "{$scheme}://job/{$jobId}";

        // Always a public smart-link page (opens app or Play Store) — never an API/admin path.
        $webBase = trim((string) ($links['job_share_web_base_url'] ?? ''));
        if ($webBase === '') {
            $webBase = rtrim((string) config('app.url', 'https://joballocate.tech'), '/');
        }
        $webLink = rtrim($webBase, '/').'/share/job/'.$jobId;

        $title = (string) $job->title;
        $company = (string) ($job->company?->name ?? 'Company');
        $location = $job->location ? (string) $job->location : null;

        $shareText = $this->buildShareText($title, $company, $location, $webLink);

        $storeUrl = trim((string) ($links['app_download_url'] ?? ''));
        if ($storeUrl === '') {
            $storeUrl = self::DEFAULT_PLAY_STORE_URL;
        }

        return [
            'job_id' => $jobId,
            'job_title' => $title,
            'company_name' => $company,
            'location' => $location,
            'app_link' => $appLink,
            'web_link' => $webLink,
            'share_text' => $shareText,
            'play_store_available' => $storeUrl !== '',
            'play_store_url' => $storeUrl,
        ];
    }

    private function buildShareText(
        string $title,
        string $company,
        ?string $location,
        string $webLink
    ): string {
        // One HTTPS link only — WhatsApp/SMS make it tappable; landing page opens app or store.
        return implode("\n", [
            'Check out this job on JobAllocate!',
            '',
            $title,
            'at '.$company.($location ? ' · '.$location : ''),
            '',
            $webLink,
        ]);
    }
}
