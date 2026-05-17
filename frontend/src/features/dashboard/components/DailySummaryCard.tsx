"use client";

import { useDailySummary } from "../api/dashboardApi";
import { useUIStore } from "@/shared/stores/uiStore";
import { formatDuration } from "@/lib/date-utils";
import { Card, CardContent } from "@/shared/components/ui/card";

interface StatItemProps {
  emoji: string;
  label: string;
  value: string;
  sub?: string;
  color: string;
}

function StatItem({ emoji, label, value, sub, color }: StatItemProps) {
  return (
    <div className={`flex flex-col gap-1 p-3 rounded-2xl ${color}`}>
      <span className="text-2xl">{emoji}</span>
      <p className="text-xs text-gray-500 font-medium">{label}</p>
      <p className="text-lg font-bold text-gray-900 leading-tight">{value}</p>
      {sub && <p className="text-xs text-gray-400">{sub}</p>}
    </div>
  );
}

export function DailySummaryCard() {
  const { activeBabyId, selectedDate } = useUIStore();
  const { data: summary, isLoading } = useDailySummary(activeBabyId, selectedDate);

  if (isLoading) {
    return (
      <Card>
        <CardContent className="pt-5">
          <div className="grid grid-cols-2 gap-3">
            {[1, 2, 3, 4].map((i) => (
              <div key={i} className="h-24 bg-gray-100 rounded-2xl animate-pulse" />
            ))}
          </div>
        </CardContent>
      </Card>
    );
  }

  const fallback = {
    totalFeedingMl: 0,
    feedingCount: 0,
    totalSleepMinutes: 0,
    sleepCount: 0,
    diaperCount: 0,
    poopCount: 0,
    peeCount: 0,
    totalPlayMinutes: 0,
    tummyTimeMinutes: 0,
    lastFeedingAt: undefined,
    lastDiaperAt: undefined,
    lastSleepAt: undefined,
  };

  const s = summary ?? fallback;

  return (
    <Card>
      <CardContent className="pt-5">
        <div className="grid grid-cols-2 gap-3">
          <StatItem
            emoji="🍼"
            label="총 수유량"
            value={`${s.totalFeedingMl}ml`}
            sub={`${s.feedingCount}회`}
            color="bg-blue-50"
          />
          <StatItem
            emoji="😴"
            label="총 수면"
            value={s.totalSleepMinutes > 0 ? formatDuration(s.totalSleepMinutes) : "-"}
            sub={`${s.sleepCount}회`}
            color="bg-purple-50"
          />
          <StatItem
            emoji="🧷"
            label="배변"
            value={`${s.diaperCount}회`}
            sub={`대변 ${s.poopCount}회`}
            color="bg-orange-50"
          />
          <StatItem
            emoji="🤸"
            label="터미타임"
            value={s.tummyTimeMinutes > 0 ? formatDuration(s.tummyTimeMinutes) : "-"}
            sub={`놀이 ${s.totalPlayMinutes > 0 ? formatDuration(s.totalPlayMinutes) : "0분"}`}
            color="bg-green-50"
          />
        </div>
      </CardContent>
    </Card>
  );
}
