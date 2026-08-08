# JobAllocate API (v1)

Base URL: `{APP_URL}/api/v1` (e.g. `http://127.0.0.1:8000/api/v1`).

All JSON responses use:

```json
{ "success": true, "message": "...", "data": {}, "meta": null }
```

Errors: `success: false`, optional `errors` object.

## Auth (mock OTP)

OTP codes are random 6-digit values stored in the **cache** (replace with SMS/email later).

- If `APP_DEBUG=true` **or** `OTP_EXPOSE_CODE=true`, `POST /auth/send-otp` includes `data.mock_otp` for testing.
- `POST /auth/verify-otp` consumes the code (one-time).

### `POST /auth/send-otp`

Body (JSON):

- `identifier` — email or phone
- `intent` — `register` | `login`
- `role` — `job_seeker` | `company`

### `POST /auth/verify-otp`

- `identifier`, `code` (6 chars), `intent`, `role` (same as send)
- Register only: `name` (required)
- Register + company: `company_name` (required)

Returns `data.token` (Bearer) and `data.user`.

### `POST /auth/logout` (Bearer)

Revokes current token.

### `GET /me` (Bearer)

Current user + `company` / `job_seeker_profile` when present.

---

## Public jobs

- `GET /jobs` — query: `search`, `location`, `per_page` (published jobs only; jobs past **deadline** or at **max applicants** are auto-closed before listing). Each item includes `applications_count`, `application_deadline_at`, `max_applications` when set.
- `GET /jobs/{id}` — published job + company (same fields; deadline/cap enforced on apply)

---

## Company (`Authorization: Bearer`, role `company`)

- `GET /company/profile` / `PUT /company/profile`
- `GET /company/job-posts` — all statuses for this company
- `POST /company/job-posts` — create job (verified companies: **published** immediately; others: **pending_review**). Optional: `application_deadline_at` (ISO 8601 datetime — after this, job **auto-closes** for new applicants), `max_applications` (positive int — when application count reaches this, job **auto-closes**).
- `PUT /company/job-posts/{id}` — update fields. To **manually close** without other edits: body `{ "status": "closed" }` only. Otherwise include fields to change; send `application_deadline_at` / `max_applications` as `null` to clear. You cannot set `max_applications` below the current number of applications.
- `GET /company/job-posts/{jobId}/applications`
- `PATCH /company/job-posts/{jobId}/applications/{applicationId}` — body: `status` (`applied|shortlisted|interview|rejected|hired`), optional `employer_note`

---

## Job seeker (`role` `job_seeker`)

- `GET /job-seeker/profile` / `PUT /job-seeker/profile` — profile includes `package_key`, `applications_remaining`, `package_activated_at`, `package_expires_at` when set
- `GET /job-seeker/packages/catalog` — list plans (Basic / Standard / Premium: price, application limit, duration days)
- `POST /job-seeker/packages/select` — body: `{ "package_key": "basic" | "standard" | "premium" }` — activates package **without payment** (dev/admin helper; production apps use PhonePe)
- `POST /job-seeker/payments/create-order` — body: `{ "package_key" }` — creates PhonePe SDK order; returns `merchant_order_id`, `order_id`, `token`, `merchant_id`, `environment` (`SANDBOX`|`PRODUCTION`), `amount` (paise)
- `POST /job-seeker/payments/confirm-status` — body: `{ "merchant_order_id" }` — calls PhonePe Order Status API; activates package when `COMPLETED`
- `POST /job-seeker/resume/pdf-create-order` — body: `{ "resume_template_id", "resume_template_title" }` — PhonePe order for PDF export; confirm via `payments/confirm-status`
- `GET /job-seeker/applications`
- `POST /job-seeker/jobs/{jobId}/apply` — body: optional `cover_letter` — **requires an active package** (not expired, `applications_remaining` ≥ 1); decrements remaining count on success

### Company subscription (PhonePe)

- `POST /company/subscription/purchase` — creates PhonePe SDK order (same response shape as seeker create-order)
- `POST /company/subscription/confirm-status` — body: `{ "merchant_order_id" }`
- `GET /company/subscription/history`

### PhonePe webhook (public)

- `POST /payments/webhook` — PhonePe S2S callbacks (`checkout.order.completed` / `checkout.order.failed`)
- Auth: SHA256 username:password (configure `PHONEPE_WEBHOOK_USERNAME` / `PHONEPE_WEBHOOK_PASSWORD` to match dashboard SHA webhook)

### Env (sandbox)

```
PHONEPE_CLIENT_ID=
PHONEPE_CLIENT_SECRET=
PHONEPE_CLIENT_VERSION=1
PHONEPE_MERCHANT_ID=
PHONEPE_ENV=sandbox
PHONEPE_WEBHOOK_USERNAME=
PHONEPE_WEBHOOK_PASSWORD=
```

---

## Super admin (`role` `super_admin`)

Seed: `php artisan db:seed --class=Database\\Seeders\\SuperAdminSeeder`  
Default user: `superadmin@joballocate.local` (password set for DB only; **issue a token in tinker** until admin OTP exists):

```php
php artisan tinker
>>> \App\Models\User::where('role', 'super_admin')->first()->createToken('admin')->plainTextToken
```

Endpoints:

- `GET /admin/dashboard` — aggregate counts
- `PATCH /admin/companies/{companyId}/verification` — body: `verification_status` (`unverified|pending|verified|rejected`), optional `rejection_reason`
- `PATCH /admin/job-posts/{jobId}/moderation` — body: `action` (`publish` | `reject`), optional `review_note`

---

## Notes

- **Job seeker packages:** Applying to a job requires an activated package (`POST .../packages/select`). Each apply consumes one from `applications_remaining` until the package **expires** (`package_expires_at`) or applications run out.
- Tiered publishing: only **verified** companies get jobs published without review; others go to `pending_review` until an admin publishes them.
- Phone-only identifiers use a synthetic email internally: `phone_{digits}@internal.joballocate`.
