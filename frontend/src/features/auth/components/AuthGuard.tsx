"use client";

import { useEffect, useState } from "react";
import { useRouter } from "next/navigation";
import { useAuthStore } from "@/features/auth/store/authStore";

/**
 * 클라이언트 인증 가드. `(main)` 레이아웃에서 children을 감싼다.
 * - DEV_MODE 백엔드는 토큰 없이도 응답하므로, 토큰 없으면 일단 통과시키되 NEXT_PUBLIC_REQUIRE_AUTH=true 일 때만 강제.
 * - 운영(Phase 6.B 활성)에서는 .env에 `NEXT_PUBLIC_REQUIRE_AUTH=true` 설정.
 */
export function AuthGuard({ children }: { children: React.ReactNode }) {
  const router = useRouter();
  const accessToken = useAuthStore((s) => s.accessToken);
  const [ready, setReady] = useState(false);

  const requireAuth = process.env.NEXT_PUBLIC_REQUIRE_AUTH === "true";

  useEffect(() => {
    if (requireAuth && !accessToken) {
      router.replace("/login");
      return;
    }
    setReady(true);
  }, [accessToken, requireAuth, router]);

  if (!ready && requireAuth) {
    return null;
  }
  return <>{children}</>;
}
