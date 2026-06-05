"use client";

import { VoiceMicButton } from "@/shared/components/VoiceMicButton";

/**
 * 플로팅 음성 버튼 — 음성 명령 전용.
 * (기존 '+' 빠른추가 액션은 제거. 빠른 기록은 홈의 BigActionGrid 로 대체)
 * 하단 탭바(56px) + safe-area + 12px 여백, z-50.
 */
export function QuickActionFAB() {
  return (
    <div className="fixed bottom-[calc(56px+env(safe-area-inset-bottom)+12px)] right-4 z-50">
      <VoiceMicButton />
    </div>
  );
}
