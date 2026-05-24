"use client";

/**
 * Main layout — iOS/Android 하이브리드 앱 기준.
 *
 * 전체 화면을 flex 컬럼으로 잡아 body 스크롤 없음.
 * - 홈(/): overflow-hidden → 페이지 내부에서 타임라인만 스크롤
 * - 기타 페이지: overflow-y-auto → 페이지 전체 스크롤
 */

import { usePathname } from "next/navigation";
import { Header } from "@/shared/components/layout/Header";
import { BottomTabBar } from "@/shared/components/layout/BottomTabBar";
import { QuickActionFAB } from "@/shared/components/QuickActionFAB";
import { AuthGuard } from "@/features/auth/components/AuthGuard";
import { ActiveSessionBanner } from "@/features/recording/components/ActiveSessionBanner";

export default function MainLayout({
  children,
}: {
  children: React.ReactNode;
}) {
  const pathname = usePathname();
  const isHome = pathname === "/";

  return (
    <AuthGuard>
      {/* fixed inset-0: 부모 height 체인 무관하게 뷰포트 전체 점유 */}
      <div className="fixed inset-0 flex flex-col overflow-hidden bg-gray-50">
        {/* 상단 고정 영역 */}
        <Header />
        <ActiveSessionBanner />

        {/* 페이지 콘텐츠 */}
        <main
          className={
            isHome
              ? /* 홈: flex col + overflow-hidden → 타임라인이 자체 스크롤 */
                "flex-1 min-h-0 max-w-md mx-auto w-full overflow-hidden flex flex-col"
              : /* 기타: 페이지 전체 스크롤 */
                "flex-1 min-h-0 max-w-md mx-auto w-full overflow-y-auto overscroll-contain scroll-container px-4 py-4"
          }
        >
          {children}
        </main>

        {/* 하단 고정 영역 */}
        <BottomTabBar />
        <QuickActionFAB />
      </div>
    </AuthGuard>
  );
}
