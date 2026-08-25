import { Metadata } from "next";
import { RefundPolicyPage } from "@/pages/refund-policy-page";

export const metadata: Metadata = {
  title: "Refund Policy - JobAllocate",
  description: "Refund and cancellation policy for JobAllocate subscription packages and employer services.",
};

export default function RefundPolicyRoute() {
  return <RefundPolicyPage />;
}
