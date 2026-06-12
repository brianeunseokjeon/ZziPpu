"use client";

import { useState } from "react";
import { useBabyInfo } from "@/features/baby/hooks/useBabyInfo";
import { useGrowthRecords } from "@/features/growth/api/growthApi";
import { calcFeedingGuideline } from "@/features/dashboard/lib/feedingGuideline";
import { useTrendsData } from "../api/trendsApi";
import {
  calcTrend,
  generateFeedingInsight,
  generateSleepInsight,
  generateDiaperInsight,
  generateTummyInsight,
} from "../lib/trendCalc";
import { getSleepGuideline, getTummyGuideline } from "../lib/guidelines";
import { TrendRangeToggle } from "./TrendRangeToggle";
import { TrendInsightCard } from "./TrendInsightCard";

function SkeletonCard() {
  return (
    <div className="h-48 bg-gray-100 rounded-2xl animate-pulse" />
  );
}

export function TrendsDashboard() {
  const [days, setDays] = useState<7 | 14>(7);

  const { babyId, ageMonths } = useBabyInfo();

  // Fetch rangeDays * 2 so calcTrend can compare this-week vs last-week
  const fetchDays = (days * 2) as 7 | 14;
  const { data: trendDays, isLoading, isError, loadedCount, refetchAll } =
    useTrendsData(babyId, fetchDays);

  // Latest weight for AAP feeding guideline
  const { data: growthRecords } = useGrowthRecords(babyId ?? "");
  const latestWeightG =
    growthRecords
      ?.filter((r) => r.weightG !== null)
      .sort(
        (a, b) =>
          new Date(b.recordedAt).getTime() - new Date(a.recordedAt).getTime()
      )[0]?.weightG ?? null;

  // ─── Loading skeleton ─────────────────────────────────────────────────────
  if (isLoading) {
    return (
      <div className="space-y-4">
        <div className="flex items-center justify-between">
          <h2 className="text-lg font-bold text-gray-900">추세</h2>
          <TrendRangeToggle value={days} onChange={setDays} />
        </div>
        <SkeletonCard />
        <SkeletonCard />
        <SkeletonCard />
        <SkeletonCard />
      </div>
    );
  }

  // ─── Error state ──────────────────────────────────────────────────────────
  if (isError) {
    return (
      <div className="space-y-4">
        <div className="flex items-center justify-between">
          <h2 className="text-lg font-bold text-gray-900">추세</h2>
          <TrendRangeToggle value={days} onChange={setDays} />
        </div>
        <div className="flex flex-col items-center justify-center py-16 gap-4 text-center">
          <p className="text-gray-500 text-sm">
            데이터를 불러오지 못했어요. 잠시 후 다시 시도해 주세요.
          </p>
          <button
            onClick={refetchAll}
            className="text-sm font-medium text-blue-500 bg-blue-50 rounded-full px-4 py-2"
          >
            다시 시도
          </button>
        </div>
      </div>
    );
  }

  // ─── Empty state ──────────────────────────────────────────────────────────
  // Chart window = most recent `days` entries
  const chartDays = trendDays.slice(-days);
  const chartLoadedCount = chartDays.filter((d) => d.summary !== null).length;

  if (loadedCount === 0) {
    return (
      <div className="space-y-4">
        <div className="flex items-center justify-between">
          <h2 className="text-lg font-bold text-gray-900">추세</h2>
          <TrendRangeToggle value={days} onChange={setDays} />
        </div>
        <div className="flex flex-col items-center justify-center py-16 gap-3 text-center">
          <span className="text-4xl">📊</span>
          <p className="text-gray-700 font-medium">
            아직 추세를 보여드릴 기록이 없어요
          </p>
          <p className="text-gray-500 text-sm">
            며칠 기록하면 수유·수면·배변·터미타임 추세를 분석해 드릴게요.
          </p>
        </div>
      </div>
    );
  }

  // ─── Extract series (full range for calcTrend, chart slice for display) ──
  const feedingValues = trendDays.map((d) => d.summary?.totalFeedingMl ?? null);
  const sleepValues = trendDays.map((d) =>
    d.summary ? d.summary.totalSleepMinutes / 60 : null
  );
  const diaperValues = trendDays.map((d) => d.summary?.diaperCount ?? null);
  const tummyValues = trendDays.map((d) =>
    d.summary?.tummyTimeMinutes ?? null
  );

  const feedingTrend = calcTrend(feedingValues, days);
  const sleepTrend = calcTrend(sleepValues, days);
  const diaperTrend = calcTrend(diaperValues, days);
  const tummyTrend = calcTrend(tummyValues, days);

  // Chart data — only show most recent `days` entries
  const feedingData = chartDays.map((d) => ({
    date: d.date,
    label: d.label,
    value: d.summary?.totalFeedingMl ?? null,
  }));
  const sleepData = chartDays.map((d) => ({
    date: d.date,
    label: d.label,
    value: d.summary ? d.summary.totalSleepMinutes / 60 : null,
  }));
  const diaperData = chartDays.map((d) => ({
    date: d.date,
    label: d.label,
    value: d.summary?.diaperCount ?? null,
  }));
  const tummyData = chartDays.map((d) => ({
    date: d.date,
    label: d.label,
    value: d.summary?.tummyTimeMinutes ?? null,
  }));

  // ─── Guidelines ───────────────────────────────────────────────────────────
  const sleepGuideline = getSleepGuideline(ageMonths);
  const tummyGuideline = getTummyGuideline(ageMonths);

  const avgFeedingMl = feedingTrend.thisWeekAvg;
  const feedingGuideline = calcFeedingGuideline(latestWeightG, Math.round(avgFeedingMl));

  // ─── Insights ─────────────────────────────────────────────────────────────
  const feedingInsight = generateFeedingInsight(
    feedingTrend.thisWeekAvg,
    feedingTrend,
    feedingGuideline,
    ageMonths
  );
  const sleepInsight = generateSleepInsight(
    sleepTrend.thisWeekAvg,
    sleepTrend,
    sleepGuideline,
    ageMonths
  );
  const diaperInsight = generateDiaperInsight(
    diaperTrend.thisWeekAvg,
    diaperTrend,
    ageMonths
  );
  const tummyInsight = generateTummyInsight(
    tummyTrend.thisWeekAvg,
    tummyTrend,
    tummyGuideline,
    ageMonths
  );

  // ─── Value display strings ─────────────────────────────────────────────────
  const feedingValueStr =
    chartLoadedCount > 0
      ? `${Math.round(feedingTrend.thisWeekAvg)}ml`
      : "-";
  const sleepValueStr =
    chartLoadedCount > 0
      ? `${sleepTrend.thisWeekAvg.toFixed(1)}시간`
      : "-";
  const diaperValueStr =
    chartLoadedCount > 0
      ? `${diaperTrend.thisWeekAvg.toFixed(1)}회`
      : "-";
  const tummyValueStr =
    chartLoadedCount > 0
      ? `${Math.round(tummyTrend.thisWeekAvg)}분`
      : "-";

  // ─── Trend label (% chip) ─────────────────────────────────────────────────
  function trendLabel(t: ReturnType<typeof calcTrend>): string {
    if (t.percentChange === null) return t.directionLabel;
    if (t.direction === "stable") return "안정적";
    return `${Math.abs(t.percentChange)}%`;
  }

  // Feeding guideline band (if weight known)
  const feedingBand =
    feedingGuideline.hasWeight
      ? { min: feedingGuideline.recommendedMin, max: feedingGuideline.recommendedMax }
      : undefined;

  return (
    <div className="space-y-4">
      {/* Header */}
      <div className="flex items-center justify-between">
        <h2 className="text-lg font-bold text-gray-900">추세</h2>
        <TrendRangeToggle value={days} onChange={setDays} />
      </div>

      {/* Feeding */}
      <TrendInsightCard
        title="수유량"
        emoji="🍼"
        value={feedingValueStr}
        trend={feedingTrend.direction}
        trendLabel={trendLabel(feedingTrend)}
        insight={feedingInsight}
        chartData={feedingData}
        color="#3b82f6"
        unit="ml"
        guidelineMin={feedingBand?.min}
        guidelineMax={feedingBand?.max}
        accentColor="bg-blue-50"
        textColor="text-blue-700"
        upIsGood={true}
      />

      {/* Sleep */}
      <TrendInsightCard
        title="수면"
        emoji="😴"
        value={sleepValueStr}
        trend={sleepTrend.direction}
        trendLabel={trendLabel(sleepTrend)}
        insight={sleepInsight}
        chartData={sleepData}
        color="#8b5cf6"
        unit="시간"
        guidelineMin={sleepGuideline.minH}
        guidelineMax={sleepGuideline.maxH}
        accentColor="bg-purple-50"
        textColor="text-purple-700"
        upIsGood={true}
      />

      {/* Diaper */}
      <TrendInsightCard
        title="배변"
        emoji="🧷"
        value={diaperValueStr}
        trend={diaperTrend.direction}
        trendLabel={trendLabel(diaperTrend)}
        insight={diaperInsight}
        chartData={diaperData}
        color="#f59e0b"
        unit="회"
        accentColor="bg-amber-50"
        textColor="text-amber-700"
        upIsGood={false}
      />

      {/* Tummy time */}
      <TrendInsightCard
        title="터미타임"
        emoji="💪"
        value={tummyValueStr}
        trend={tummyTrend.direction}
        trendLabel={trendLabel(tummyTrend)}
        insight={tummyInsight}
        chartData={tummyData}
        color="#10b981"
        unit="분"
        guidelineMax={tummyGuideline.targetMin}
        accentColor="bg-green-50"
        textColor="text-green-700"
        upIsGood={true}
      />
    </div>
  );
}
