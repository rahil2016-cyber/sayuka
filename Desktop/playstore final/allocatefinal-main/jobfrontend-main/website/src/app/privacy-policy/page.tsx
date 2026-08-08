import { Metadata } from "next";
import { PrivacyPolicyPage } from "@/pages/privacy-policy-page";

export const metadata: Metadata = {
  title: "Privacy Policy - JobAllocate",
  description: "Privacy policy detailing data collection, account security, and data protection practices of JobAllocate.",
};

export default function PrivacyPolicyRoute() {
  return <PrivacyPolicyPage />;
}
