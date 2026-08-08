import Link from "next/link";
import { BrandLogo } from "@/components/common/brand-logo";

function PrivacyPolicyPage() {
  return (
    <div className="min-h-screen bg-[var(--background)]">
      <div className="mx-auto w-full max-w-4xl px-4 py-10">
        <div className="flex flex-col gap-4 rounded-2xl bg-white p-4 shadow-sm sm:flex-row sm:items-center sm:justify-between">
          <BrandLogo />
          <Link
            href="/"
            className="self-start rounded-xl bg-[var(--primary)] px-4 py-2 text-sm font-extrabold text-white transition hover:bg-[var(--primary-dark)] sm:self-auto"
          >
            Back to Home
          </Link>
        </div>

        <section className="mt-6 rounded-2xl bg-white p-6 md:p-8 shadow-sm">
          <div className="inline-block rounded-full bg-blue-50 px-3 py-1 text-xs font-bold text-blue-700 mb-4">
            PRIVACY & DATA PROTECTION
          </div>
          <h1 className="text-3xl font-black text-slate-900">Privacy Policy</h1>
          <p className="mt-2 text-sm font-semibold text-[var(--text-hint)]">
            Effective Date: August 2026 | Service Domain: https://joballocate.tech
          </p>

          <div className="mt-6 space-y-6 text-sm font-medium leading-relaxed text-slate-700">
            <div>
              <h2 className="text-lg font-bold text-slate-900">1. Overview</h2>
              <p className="mt-2">
                JobAllocate is dedicated to protecting your privacy. This Privacy Policy explains how we collect, use, store, and protect your personal information when you use our website at{" "}
                <a href="https://joballocate.tech" className="text-[var(--primary)] underline font-bold">
                  https://joballocate.tech
                </a>{" "}
                and our mobile applications.
              </p>
            </div>

            <div>
              <h2 className="text-lg font-bold text-slate-900">2. Information We Collect</h2>
              <p className="mt-2">We collect information that is strictly necessary to provide our services:</p>
              <ul className="mt-2 list-disc pl-5 space-y-1">
                <li><strong>Account Data:</strong> Name, registered email address, mobile phone number, and profile details.</li>
                <li><strong>Professional Information:</strong> Resumes, work history, skill sets, education, and job preferences uploaded by job seekers.</li>
                <li><strong>Employer Credentials:</strong> Company name, verification documents, GST/Registration details, and job opening specifications.</li>
                <li><strong>Technical Information:</strong> Device tokens for notifications, IP addresses, log data, and browser type for security monitoring.</li>
              </ul>
            </div>

            <div>
              <h2 className="text-lg font-bold text-slate-900">3. How We Use Your Information</h2>
              <ul className="mt-2 list-disc pl-5 space-y-1">
                <li>To enable job application workflows between job seekers and verified employers.</li>
                <li>To perform OTP authentication, secure sign-in, and account verification.</li>
                <li>To process subscription payments securely via PhonePe.</li>
                <li>To deliver account updates, job alert notifications, and operational support.</li>
                <li>We <strong>do not sell</strong> your personal data to third parties under any circumstances.</li>
              </ul>
            </div>

            <div>
              <h2 className="text-lg font-bold text-slate-900">4. Data Security & Storage</h2>
              <p className="mt-2">
                We implement robust administrative, technical, and physical security measures, including SSL encryption in transit and secure database storage. Access to personal data is restricted to authorized personnel only.
              </p>
            </div>

            <div>
              <h2 className="text-lg font-bold text-slate-900">5. Data Retention & Account Deletion Policy</h2>
              <p className="mt-2">
                Users have the right to request deletion of their account and associated personal data at any time. You can submit an account deletion request through our web form or by contacting support. Pending deletion requests are reviewed and processed within 24 hours.
              </p>
            </div>

            <div>
              <h2 className="text-lg font-bold text-slate-900">6. Third-Party Services</h2>
              <p className="mt-2">
                We work with trusted service providers such as Firebase (for OTP and authentication) and PhonePe (for secure payment processing). These services handle data in accordance with their respective security and privacy standards.
              </p>
            </div>

            <div>
              <h2 className="text-lg font-bold text-slate-900">7. Contact Information</h2>
              <p className="mt-2">
                If you have questions or concerns regarding our privacy practices or wish to exercise your data rights, please contact us at{" "}
                <a href="mailto:support@joballocate.tech" className="text-[var(--primary)] underline font-bold">
                  support@joballocate.tech
                </a>.
              </p>
            </div>
          </div>
        </section>
      </div>
    </div>
  );
}

export { PrivacyPolicyPage };
export default PrivacyPolicyPage;
