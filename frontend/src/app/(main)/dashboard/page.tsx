"use client";

import { DailySummaryCard } from "@/features/dashboard/components/DailySummaryCard";
import { FeedingChart } from "@/features/dashboard/components/FeedingChart";
import { SleepChart } from "@/features/dashboard/components/SleepChart";
import { TimelineView } from "@/features/dashboard/components/TimelineView";

export default function DashboardPage() {
  return (
    <div className="space-y-4">
      <DailySummaryCard />
      <FeedingChart />
      <SleepChart />
      <TimelineView />
    </div>
  );
}
