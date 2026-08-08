<?php

namespace App\Http\Controllers\Api\V1\JobSeeker;

use App\Http\Concerns\ApiResponses;
use App\Http\Controllers\Controller;
use App\Models\JobPost;
use App\Models\JobReport;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class JobReportController extends Controller
{
    use ApiResponses;

    /**
     * POST /job-seeker/jobs/{jobId}/report
     * Allows a seeker to report a job with a reason + optional description.
     */
    public function store(Request $request, int $jobId): JsonResponse
    {
        $job = JobPost::find($jobId);
        if (! $job) {
            return $this->fail('Job not found.', null, 404);
        }

        $validated = $request->validate([
            'reason'      => ['required', 'string', 'max:100'],
            'description' => ['nullable', 'string', 'max:2000'],
        ]);

        $userId = $request->user()->id;

        // Prevent duplicate reports
        $existing = JobReport::where('job_post_id', $jobId)
            ->where('user_id', $userId)
            ->first();

        if ($existing) {
            return $this->fail('You have already reported this job.', null, 409);
        }

        $report = JobReport::create([
            'job_post_id' => $jobId,
            'user_id'     => $userId,
            'reason'      => $validated['reason'],
            'description' => $validated['description'] ?? null,
            'status'      => 'pending',
        ]);

        return $this->ok($report, 'Report submitted. Admin will review it.', [], 201);
    }
}
