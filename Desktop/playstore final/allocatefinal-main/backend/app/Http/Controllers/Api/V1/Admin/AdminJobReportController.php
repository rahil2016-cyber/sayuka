<?php

namespace App\Http\Controllers\Api\V1\Admin;

use App\Http\Concerns\ApiResponses;
use App\Http\Controllers\Controller;
use App\Models\JobReport;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class AdminJobReportController extends Controller
{
    use ApiResponses;

    /**
     * GET /admin/job-reports
     * List all job reports (newest first). Filter by status if needed.
     */
    public function index(Request $request): JsonResponse
    {
        $validated = $request->validate([
            'status'   => ['nullable', 'in:pending,reviewed,dismissed'],
            'per_page' => ['nullable', 'integer', 'min:1', 'max:100'],
        ]);

        $q = JobReport::with([
            'jobPost:id,title,company_id',
            'jobPost.company:id,name',
            'user:id,name,email',
        ])->latest();

        if (! empty($validated['status'])) {
            $q->where('status', $validated['status']);
        }

        $perPage = (int) ($validated['per_page'] ?? 20);
        $rows = $q->paginate($perPage);

        return $this->ok(
            $rows->items(),
            'OK',
            [
                'current_page' => $rows->currentPage(),
                'last_page'    => $rows->lastPage(),
                'per_page'     => $rows->perPage(),
                'total'        => $rows->total(),
            ]
        );
    }

    /**
     * PATCH /admin/job-reports/{reportId}
     * Update status and/or admin_note.
     */
    public function update(Request $request, int $reportId): JsonResponse
    {
        $report = JobReport::find($reportId);
        if (! $report) {
            return $this->fail('Report not found.', null, 404);
        }

        $validated = $request->validate([
            'status'     => ['nullable', 'in:pending,reviewed,dismissed'],
            'admin_note' => ['nullable', 'string', 'max:2000'],
        ]);

        $report->update(array_filter($validated, fn ($v) => $v !== null));

        return $this->ok($report->fresh(), 'Report updated.');
    }
}
