"use client";

import { FeedingAdequacyCard } from "@/features/dashboard/components/FeedingAdequacyCard";
import { DailySummaryCard } from "@/features/dashboard/components/DailySummaryCard";
import { FeedingChart } from "@/features/dashboard/components/FeedingChart";
import { SleepChart } from "@/features/dashboard/components/SleepChart";
import { TimelineView } from "@/features/dashboard/components/TimelineView";

export default function DashboardPage() {
  return (
    <div className="space-y-4">
      {/* 건강탭 스타일 — '오늘 수유량이 적정한가'를 최상단에 */}
      <FeedingAdequacyCard />
      <DailySummaryCard />
      <FeedingChart />
      <SleepChart />
      <TimelineView />
    </div>
  );
}
