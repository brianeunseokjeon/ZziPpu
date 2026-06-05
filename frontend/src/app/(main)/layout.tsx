"use client";

/**
 * Main layout — iOS/Android 하이브리드 앱 기준.
 *
 * 전체 화면을 flex 컬럼으로 잡아 body 스크롤 없음.
 * - 홈(/): overflow-hidden → 페이지 내부에서 타임라인만 스크롤
 * - 기타 페이지: overflow-y-auto → 페이지 전체 스크롤
 */

import { useEffect } from "react";
import { usePathname } from "next/navigation";
import { Header } from "@/shared/components/layout/Header";
import { BottomTabBar } from "@/shared/components/layout/BottomTabBar";
import { QuickActionFAB } from "@/shared/components/QuickActionFAB";
import { AuthGuard } from "@/features/auth/components/AuthGuard";
import { ActiveSessionBanner } from "@/features/recording/components/ActiveSessionBanner";
import { useUIStore } from "@/shared/stores/uiStore";
import { useBabyStore } from "@/features/baby/store/babyStore";

export default function MainLayout({
  children,
}: {
  children: React.ReactNode;
}) {
  const pathname = usePathname();
  const isHome = pathname === "/";

  // babyStore(영속) 가 앱 전역 babyId 의 단일 소스.
  // 데이터 CRUD 컴포넌트들은 uiStore.activeBabyId 를 읽으므로 여기서 동기화한다.
  // (로그인/온보딩/코드참여가 babyStore.babyId 만 갱신해도 앱 전체가 따라오도록)
  const babyId = useBabyStore((s) => s.babyId);
  const setActiveBabyId = useUIStore((s) => s.setActiveBabyId);
  useEffect(() => {
    if (babyId) setActiveBabyId(babyId);
  }, [babyId, setActiveBabyId]);

  return (
    <AuthGuard>
      {/* fixed inset-0 유지(인앱브라우저 폴백) + h-[100dvh] 보강:
          iOS Safari 동적 주소창/툴바를 반영해 하단 UI 가 브라우저 UI 뒤로 안 잘리게 한다. */}
      <div className="fixed inset-0 h-[100dvh] flex flex-col overflow-hidden bg-gray-50">
        {/* 상단 고정 영역 */}
        <Header />
        <ActiveSessionBanner />

        {/* 페이지 콘텐츠 */}
        <main
          className={
            isHome
              ? /* 홈: flex col + overflow-hidden → 타임라인이 자체 스크롤 */
                "flex-1 min-h-0 max-w-md mx-auto w-full overflow-hidden flex flex-col"
              : /* 기타: 페이지 전체 스크롤 (하단 safe-area 여백으로 콘텐츠가 잘리지 않게) */
                "flex-1 min-h-0 max-w-md mx-auto w-full overflow-y-auto overscroll-contain scroll-container px-4 py-4 pb-[calc(env(safe-area-inset-bottom)+16px)]"
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
