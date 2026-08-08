import Link from "next/link";
import { BrandLogo } from "@/components/common/brand-logo";

function TermsAndConditionsPage() {
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
            LEGAL AGREEMENT
          </div>
          <h1 className="text-3xl font-black text-slate-900">Terms and Conditions</h1>
          <p className="mt-2 text-sm font-semibold text-[var(--text-hint)]">
            Last Updated: August 2026 | Effective Date: August 2026
          </p>

          <div className="mt-6 space-y-6 text-sm font-medium leading-relaxed text-slate-700">
            <div>
              <h2 className="text-lg font-bold text-slate-900">1. Acceptance of Terms</h2>
              <p className="mt-2">
                By accessing or using <strong>JobAllocate</strong> (accessible at{" "}
                <a href="https://joballocate.tech" className="text-[var(--primary)] underline">
                  https://joballocate.tech
                </a>{" "}
                and through our mobile application), you agree to be bound by these Terms and Conditions. If you do not agree to these terms, please do not use our platform.
              </p>
            </div>

            <div>
              <h2 className="text-lg font-bold text-slate-900">2. Eligibility & Account Registration</h2>
              <p className="mt-2">
                JobAllocate offers job posting and application services for companies and job seekers. Users must be at least 18 years of age to register an account. You are responsible for maintaining the accuracy of your account information and the security of your login credentials.
              </p>
            </div>

            <div>
              <h2 className="text-lg font-bold text-slate-900">3. Employer Responsibilities</h2>
              <ul className="mt-2 list-disc pl-5 space-y-1">
                <li>Employers must provide authentic and verified business credentials prior to publishing job postings.</li>
                <li>All posted job listings must represent genuine employment opportunities and strictly comply with applicable labor laws.</li>
                <li>Fraudulent job postings, misleading salary information, or requests for upfront fees from applicants are strictly prohibited and will result in immediate termination of the account without refund.</li>
              </ul>
            </div>

            <div>
              <h2 className="text-lg font-bold text-slate-900">4. Job Seeker Responsibilities</h2>
              <ul className="mt-2 list-disc pl-5 space-y-1">
                <li>Job seekers must provide truthful information in their profiles, resumes, and job applications.</li>
                <li>Misrepresentation of work experience, qualifications, or identity may lead to account suspension.</li>
              </ul>
            </div>

            <div>
              <h2 className="text-lg font-bold text-slate-900">5. Subscriptions and Payments</h2>
              <p className="mt-2">
                JobAllocate offers premium features, employer subscription plans, and featured listings. All payments made through PhonePe or authorized gateways are subject to our Payment Terms and Refund Policy.
              </p>
            </div>

            <div>
              <h2 className="text-lg font-bold text-slate-900">6. Intellectual Property & Acceptable Use</h2>
              <p className="mt-2">
                All content, trademarks, platform code, and branding on JobAllocate are the exclusive property of JobAllocate. Users agree not to scrape, copy, modify, or reverse-engineer any part of the service.
              </p>
            </div>

            <div>
              <h2 className="text-lg font-bold text-slate-900">7. Limitation of Liability</h2>
              <p className="mt-2">
                JobAllocate acts as a venue connecting job seekers and employers. We do not guarantee employment outcomes or guarantee that employers will hire applicants. JobAllocate shall not be liable for direct, indirect, or consequential damages resulting from platform use.
              </p>
            </div>

            <div>
              <h2 className="text-lg font-bold text-slate-900">8. Governing Law & Contact</h2>
              <p className="mt-2">
                These terms are governed by and construed in accordance with the laws of India. For any inquiries regarding these terms, please reach out to us at{" "}
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

export { TermsAndConditionsPage };
export default TermsAndConditionsPage;
