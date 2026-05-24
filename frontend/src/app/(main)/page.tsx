"use client";

/**
 * 홈 — 고정 상단 기록 버튼 + 채팅형 타임라인 스크롤.
 *
 * 전체 페이지 스크롤 없음.
 * 위: 빠른 기록 UI (flex-shrink-0)
 * 아래: 타임라인 (flex-1, 내부 스크롤, 오늘이 맨 아래)
 */

import { MilestoneBanner } from "@/features/baby/components/MilestoneBanner";
import { QuickRepeatRow } from "@/features/recording/components/QuickRepeatRow";
import { BigActionGrid } from "@/features/recording/components/BigActionGrid";
import { VoiceCommandHero } from "@/features/recording/components/VoiceCommandHero";
import { TimelineScrollView } from "@/features/recording/components/TimelineScrollView";

export default function HomePage() {
  return (
    <div className="flex-1 flex flex-col overflow-hidden min-h-0">
      {/* ── 고정 상단: 빠른 기록 버튼 ── */}
      <div className="flex-shrink-0 px-4 pt-3 pb-2 space-y-2.5 bg-gray-50 border-b border-gray-100">
        <MilestoneBanner />
        <QuickRepeatRow />
        <BigActionGrid />
        <VoiceCommandHero />
      </div>

      {/* ── 기록 타임라인 (채팅형 스크롤) ── */}
      <TimelineScrollView />
    </div>
  );
}
