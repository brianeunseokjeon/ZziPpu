/**
 * /ai 인덱스 — 일일 리뷰로 리다이렉트.
 *
 * AI 탭 내부는 layout.tsx 의 서브탭(리뷰/채팅/저장)으로 네비게이션.
 */
import { redirect } from "next/navigation";

export default function AIIndexPage() {
  redirect("/ai/review");
}
