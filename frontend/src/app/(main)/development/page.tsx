"use client";

import { useEffect, useState } from "react";
import { Loader2 } from "lucide-react";
import { useBabyInfo } from "@/features/baby/hooks/useBabyInfo";
import { useCurrentStage, useStages } from "@/features/development/api/developmentApi";
import { MilestoneTimeline } from "@/features/development/components/MilestoneTimeline";
import { DateCalculator } from "@/features/development/components/DateCalculator";
import { StageDetail } from "@/features/development/components/StageDetail";

export default function DevelopmentPage() {
  const { ageDays, name } = useBabyInfo();
  const { data: stages } = useStages();
  const { data: bundle, isLoading } = useCurrentStage(ageDays);

  // 시기 네비게이션 — 현재 보는 stage 인덱스
  const [stageIdx, setStageIdx] = useState<number | null>(null);

  // bundle 도착 시 현재 시기를 기본으로
  useEffect(() => {
    if (stages && bundle && stageIdx === null) {
      const idx = stages.findIndex((s) => s.label === bundle.current.label);
      if (idx >= 0) setStageIdx(idx);
    }
  }, [stages, bundle, stageIdx]);

  const stage = stages && stageIdx !== null ? stages[stageIdx] : null;
  const prev = stages && stageIdx !== null && stageIdx > 0 ? stages[stageIdx - 1] : null;
  const next =
    stages && stageIdx !== null && stageIdx < stages.length - 1 ? stages[stageIdx + 1] : null;

  return (
    <div className="space-y-4 pb-8">
      {/* 헤더 */}
      <div className="bg-gradient-to-br from-blue-50 to-purple-50 rounded-2xl p-4 border border-blue-100">
        <p className="text-xs text-blue-700 font-medium">발달 가이드</p>
        <h1 className="text-lg font-bold text-gray-900 mt-0.5">
          {name} (생후 {ageDays}일)
        </h1>
        <p className="text-xs text-gray-600 mt-1">
          대한소아청소년과학회 + AAP 최신 가이드 기반
        </p>
      </div>

      {/* 마일스톤 타임라인 */}
      <MilestoneTimeline />

      {/* 날짜 계산기 */}
      <DateCalculator />

      {/* 발달 단계 상세 */}
      {isLoading || !stage ? (
        <div className="flex items-center justify-center py-8 text-gray-400">
          <Loader2 className="w-5 h-5 animate-spin mr-2" />
          <span className="text-sm">발달 가이드 불러오는 중...</span>
        </div>
      ) : (
        <StageDetail
          stage={stage}
          previousLabel={prev?.label ?? null}
          nextLabel={next?.label ?? null}
          onPrev={prev ? () => setStageIdx((i) => (i !== null ? i - 1 : 0)) : undefined}
          onNext={next ? () => setStageIdx((i) => (i !== null ? i + 1 : 0)) : undefined}
        />
      )}
    </div>
  );
}
