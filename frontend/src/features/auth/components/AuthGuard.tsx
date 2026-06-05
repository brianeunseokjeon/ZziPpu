"use client";

import { useEffect, useState } from "react";
import { useRouter } from "next/navigation";
import { Loader2 } from "lucide-react";
import { useAuthStore } from "@/features/auth/store/authStore";

/**
 * 클라이언트 인증 가드. `(main)` 레이아웃에서 children을 감싼다.
 *
 * ⚠️ zustand persist 는 localStorage 에서 **비동기로 복원(hydration)** 된다.
 * 복원 전 첫 렌더에는 accessToken 이 초기값(null)이므로, 이 시점에 리다이렉트하면
 * 새로고침마다 로그인이 풀린다. → hydration 완료를 기다린 뒤에만 판단한다.
 */
export function AuthGuard({ children }: { children: React.ReactNode }) {
  const router = useRouter();
  const accessToken = useAuthStore((s) => s.accessToken);
  const requireAuth = process.env.NEXT_PUBLIC_REQUIRE_AUTH === "true";

  // localStorage 복원 완료 여부
  const [hydrated, setHydrated] = useState(false);
  useEffect(() => {
    if (useAuthStore.persist.hasHydrated()) setHydrated(true);
    const unsub = useAuthStore.persist.onFinishHydration(() => setHydrated(true));
    return unsub;
  }, []);

  useEffect(() => {
    if (!hydrated) return; // 복원 전엔 판단 보류 (조기 리다이렉트 방지)
    if (requireAuth && !accessToken) {
      router.replace("/login");
    }
  }, [hydrated, accessToken, requireAuth, router]);

  // 인증 필요 + (복원 전 || 미인증) → 깜빡임 없이 로딩 표시
  if (requireAuth && (!hydrated || !accessToken)) {
    return (
      <div className="flex-1 flex items-center justify-center py-20">
        <Loader2 className="w-6 h-6 animate-spin text-gray-300" />
      </div>
    );
  }
  return <>{children}</>;
}
