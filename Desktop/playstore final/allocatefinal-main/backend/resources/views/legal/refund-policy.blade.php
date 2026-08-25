@extends('legal.layout', [
    'title' => 'Refund and Cancellation Policy',
    'badge' => 'CANCELLATION & REFUNDS',
    'meta' => 'Last Updated: August 2026 | Effective Date: August 2026',
])

@section('content')
    <h2>1. Overview</h2>
    <p>
        At <strong>JobAllocate</strong> (operated via
        <a href="https://joballocate.tech"><strong>https://joballocate.tech</strong></a>),
        we aim to ensure complete transparency in our pricing and billing services. This policy outlines the
        conditions under which refunds or cancellations are handled for employer subscriptions, job posting
        credits, and candidate services.
    </p>

    <h2>2. Subscription Plans &amp; Digital Services</h2>
    <p>
        JobAllocate provides digital services, including employer subscription packages, candidate resume
        highlighting, and job posting services.
    </p>
    <ul>
        <li>Digital services and subscription credits are activated immediately upon successful payment confirmation.</li>
        <li>Once a digital subscription or credit is partially or fully utilized (e.g., job posted or resumes unlocked), payments are non-refundable.</li>
    </ul>

    <h2>3. Eligible Refund Scenarios</h2>
    <p>Refunds will be evaluated and issued under the following circumstances:</p>
    <ul>
        <li><strong>Duplicate Billing:</strong> Multiple charges for the same transaction due to a technical network or payment gateway glitch.</li>
        <li><strong>Payment Without Service Delivery:</strong> Payment deducted successfully from your account, but subscription credits were not credited due to technical error within 24 hours.</li>
        <li><strong>Verification Rejection:</strong> In the event an employer account payment is made but the employer fails company verification due to administrative criteria, a full refund will be initiated minus payment gateway processing fees.</li>
    </ul>

    <h2>4. Refund Request Process &amp; Timeline</h2>
    <ul>
        <li>To request a refund, email our support team at <a href="mailto:support@joballocate.tech"><strong>support@joballocate.tech</strong></a> with your Payment ID, Order ID, Registered Email, and Reason for Refund.</li>
        <li>Refund requests must be submitted within <strong>7 business days</strong> of the original payment date.</li>
        <li>Approved refunds will be processed back to the original payment source (bank account/UPI/credit card) within <strong>5 to 7 working days</strong>.</li>
    </ul>

    <h2>5. Cancellation Policy</h2>
    <p>
        Users may cancel recurring subscription plans at any time from their account dashboard.
        Cancellation stops future auto-renewals; active plan benefits will remain available until the end of
        the current billing cycle.
    </p>

    <h2>6. Support &amp; Inquiries</h2>
    <p>For any questions or payment assistance, please contact us at:</p>
    <p>
        <strong>Email:</strong> support@joballocate.tech<br>
        <strong>Website:</strong> <a href="https://joballocate.tech">https://joballocate.tech</a>
    </p>
@endsection
