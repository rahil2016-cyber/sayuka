import { Metadata } from "next";
import { TermsAndConditionsPage } from "@/pages/terms-and-conditions-page";

export const metadata: Metadata = {
  title: "Terms and Conditions - JobAllocate",
  description: "Terms and conditions for using JobAllocate services, job seeker platform, and employer features.",
};

export default function TermsAndConditionsRoute() {
  return <TermsAndConditionsPage />;
}
