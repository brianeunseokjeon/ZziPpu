"use client";

import { MilestoneBanner } from "@/features/baby/components/MilestoneBanner";
import { QuickRepeatRow } from "@/features/recording/components/QuickRepeatRow";
import { BigActionGrid } from "@/features/recording/components/BigActionGrid";
import { VoiceCommandHero } from "@/features/recording/components/VoiceCommandHero";
import { TimelineScrollView } from "@/features/recording/components/TimelineScrollView";

export default function HomePage() {
  return (
    <div className="space-y-4 pb-8">
      {/* 마일스톤 배너 (다가오는 백일 등) */}
      <MilestoneBanner />

      {/* 빠른 1탭 기록 */}
      <QuickRepeatRow />

      {/* 2×3 큰 기록 버튼 */}
      <BigActionGrid />

      {/* 음성 명령 */}
      <VoiceCommandHero />

      {/* 24h 타임라인 — 오늘부터 무한 스크롤 */}
      <TimelineScrollView />
    </div>
  );
}
