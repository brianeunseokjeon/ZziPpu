"use client";

import { Info } from "lucide-react";
import { Card, CardContent } from "@/shared/components/ui/card";
import { useUIStore } from "@/shared/stores/uiStore";
import { useDailySummary } from "../api/dashboardApi";
import { useGrowthRecords } from "@/features/growth/api/growthApi";
import { WeightInline } from "@/features/growth/components/WeightInline";
import { calcFeedingGuideline, STATUS_META } from "../lib/feedingGuideline";

export function FeedingAdequacyCard() {
  const { activeBabyId, selectedDate } = useUIStore();
  const { data: summary } = useDailySummary(activeBabyId, selectedDate);
  const { data: records } = useGrowthRecords(activeBabyId);

  const latest = records?.find((r) => r.weight_g != null);
  const weightG = latest?.weight_g ?? null;
  const actualMl = summary?.totalFeedingMl ?? 0;

  const g = calcFeedingGuideline(weightG, actualMl);
  const meta = STATUS_META[g.status];

  // 게이지: 권장 상한의 1.3배를 100%로 스케일 (초과도 보이게)
  const scaleMax = g.hasWeight ? g.recommendedMax * 1.3 : Math.max(actualMl, 1);
  const fillPct = Math.min(100, (actualMl / scaleMax) * 100);
  const minPct = g.hasWeight ? (g.recommendedMin / scaleMax) * 100 : 0;
  const maxPct = g.hasWeight ? (g.recommendedMax / scaleMax) * 100 : 0;

  return (
    <Card>
      <CardContent className="pt-5">
        {/* 헤더 */}
        <div className="flex items-center justify-between mb-3">
          <div className="flex items-center gap-2">
            <span className="text-lg">🍼</span>
            <h2 className="text-sm font-bold text-gray-900">오늘의 수유량</h2>
          </div>
          <span className={`text-xs font-semibold px-2.5 py-1 rounded-full ${meta.tone}`}>
            {meta.label}
          </span>
        </div>

        {/* 큰 숫자 */}
        <div className="flex items-end gap-2 mb-1">
          <span className="text-4xl font-bold text-gray-900 leading-none tabular-nums">
            {actualMl}
          </span>
          <span className="text-base text-gray-400 mb-0.5">ml</span>
          <span className="text-xs text-gray-400 mb-1.5 ml-1">
            (분유 {summary?.feedingCount ?? 0}회 기준)
          </span>
        </div>

        {/* 게이지 */}
        {g.hasWeight ? (
          <>
            <div className="relative h-3 rounded-full bg-gray-100 my-3 overflow-visible">
              {/* 권장 정상 구간 (min~max) */}
              <div
                className="absolute top-0 h-3 bg-emerald-100 rounded-full"
                style={{ left: `${minPct}%`, width: `${Math.max(0, maxPct - minPct)}%` }}
              />
              {/* 실제 채움 */}
              <div
                className={`absolute top-0 h-3 rounded-full ${meta.bar}`}
                style={{ width: `${fillPct}%` }}
              />
            </div>
            <p className="text-xs text-gray-500">
              권장{" "}
              <span className="font-semibold text-gray-700">
                {g.recommendedMin}~{g.recommendedMax}ml
              </span>
              /일
              {g.capped && <span className="text-gray-400"> · AAP 상한 960ml 적용</span>}
            </p>
          </>
        ) : (
          <p className="text-xs text-gray-500 my-3 leading-relaxed">
            체중을 입력하면 우리 아이에게 맞는 <b>권장 수유량</b>을 알려드려요.
          </p>
        )}

        {/* 체중 입력 */}
        <div className="flex items-center justify-between mt-3 pt-3 border-t border-gray-50">
          <span className="text-xs text-gray-400">현재 체중</span>
          <WeightInline babyId={activeBabyId} weightG={weightG} />
        </div>

        {/* 면책 문구 */}
        <div className="mt-3 flex gap-1.5 rounded-xl bg-amber-50 border border-amber-100 px-3 py-2">
          <Info className="w-3.5 h-3.5 text-amber-500 flex-shrink-0 mt-0.5" />
          <p className="text-[11px] text-amber-700 leading-relaxed">
            본 권장량은 체중 1kg당 150~180ml/일 기준 일반 가이드입니다. 모유·혼합수유 여부, 아기 개별
            식욕에 따라 ±20% 차이는 정상이에요. AAP(미국소아과학회) 권장 1일 최대 약 960ml 이내. 체중
            증가 추이가 정상이면 식욕에 맞춰 조절하고, 의문점은 소아과 상담을 권합니다.{" "}
            <span className="font-medium">AAP(미국소아과학회)·HealthyChildren.org 기준. 의학적 진단이 아닌 참고용입니다.</span>
          </p>
        </div>
      </CardContent>
    </Card>
  );
}
