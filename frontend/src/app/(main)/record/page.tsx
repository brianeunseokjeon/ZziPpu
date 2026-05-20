/**
 * /record → 홈으로 리다이렉트.
 *
 * Phase 9에서 기록 기능이 홈으로 통합되어 /record 탭이 폐지됨.
 * 개별 기록 페이지(/record/feeding, /record/sleep 등)는 그대로 유지.
 */
import { redirect } from "next/navigation";

export default function RecordPage() {
  redirect("/");
}
