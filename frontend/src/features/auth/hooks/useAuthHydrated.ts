"use client";

import { useEffect, useState } from "react";
import { useAuthStore } from "@/features/auth/store/authStore";

/**
 * authStore(zustand persist)가 localStorage 에서 복원(hydration)되었는지 추적.
 *
 * 인증 가드(AuthGuard / terms / onboarding)는 반드시 hydration 완료 후에만
 * "토큰 없음 → /login" 판단을 내려야 한다. 복원 전 첫 렌더의 초기값(null)으로
 * 리다이렉트하면 새로고침·백그라운드 복귀 시 로그인이 풀린다.
 */
export function useAuthHydrated(): boolean {
  const [hydrated, setHydrated] = useState(false);
  useEffect(() => {
    if (useAuthStore.persist.hasHydrated()) setHydrated(true);
    return useAuthStore.persist.onFinishHydration(() => setHydrated(true));
  }, []);
  return hydrated;
}
