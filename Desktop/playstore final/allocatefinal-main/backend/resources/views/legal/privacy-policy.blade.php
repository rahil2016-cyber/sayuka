@extends('legal.layout', [
    'title' => 'Privacy Policy',
    'badge' => 'PRIVACY & DATA PROTECTION',
    'meta' => 'Effective Date: August 2026 | Service Domain: https://joballocate.tech',
])

@section('content')
    <h2>1. Overview</h2>
    <p>
        JobAllocate is dedicated to protecting your privacy. This Privacy Policy explains how we collect, use,
        store, and protect your personal information when you use our website at
        <a href="https://joballocate.tech"><strong>https://joballocate.tech</strong></a>
        and our mobile applications.
    </p>

    <h2>2. Information We Collect</h2>
    <p>We collect information that is strictly necessary to provide our services:</p>
    <ul>
        <li><strong>Account Data:</strong> Name, registered email address, mobile phone number, and profile details.</li>
        <li><strong>Professional Information:</strong> Resumes, work history, skill sets, education, and job preferences uploaded by job seekers.</li>
        <li><strong>Employer Credentials:</strong> Company name, verification documents, GST/Registration details, and job opening specifications.</li>
        <li><strong>Technical Information:</strong> Device tokens for notifications, IP addresses, log data, and browser type for security monitoring.</li>
    </ul>

    <h2>3. How We Use Your Information</h2>
    <ul>
        <li>To enable job application workflows between job seekers and verified employers.</li>
        <li>To perform OTP authentication, secure sign-in, and account verification.</li>
        <li>To process subscription payments securely via PhonePe.</li>
        <li>To deliver account updates, job alert notifications, and operational support.</li>
        <li>We <strong>do not sell</strong> your personal data to third parties under any circumstances.</li>
    </ul>

    <h2>4. Data Security &amp; Storage</h2>
    <p>
        We implement robust administrative, technical, and physical security measures, including SSL encryption
        in transit and secure database storage. Access to personal data is restricted to authorized personnel only.
    </p>

    <h2>5. Data Retention &amp; Account Deletion Policy</h2>
    <p>
        Users have the right to request deletion of their account and associated personal data at any time.
        You can submit an account deletion request through our web form or by contacting support.
        Pending deletion requests are reviewed and processed within 24 hours.
    </p>

    <h2>6. Third-Party Services</h2>
    <p>
        We work with trusted service providers such as Firebase (for OTP and authentication) and PhonePe
        (for secure payment processing). These services handle data in accordance with their respective
        security and privacy standards.
    </p>

    <h2>7. Contact Information</h2>
    <p>
        If you have questions or concerns regarding our privacy practices or wish to exercise your data rights,
        please contact us at
        <a href="mailto:support@joballocate.tech"><strong>support@joballocate.tech</strong></a>.
    </p>
@endsection
