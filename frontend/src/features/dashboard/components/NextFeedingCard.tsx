"use client";

import { useEffect, useState } from "react";
import { Milk, Moon } from "lucide-react";
import { useUIStore } from "@/shared/stores/uiStore";
import { usePredictions } from "../api/dashboardApi";
import { formatTime, formatDuration } from "@/lib/date-utils";
import { cn } from "@/lib/utils";

function diffMinutes(iso: string, now: number): number {
  return Math.round((new Date(iso).getTime() - now) / 60000);
}

export function NextFeedingCard() {
  const { activeBabyId } = useUIStore();
  const { data, isLoading } = usePredictions(activeBabyId);

  // 카운트다운을 1분마다 다시 계산하기 위한 틱.
  const [now, setNow] = useState(() => Date.now());
  useEffect(() => {
    const id = setInterval(() => setNow(Date.now()), 30_000);
    return () => clearInterval(id);
  }, []);

  if (isLoading || !data?.nextFeedingAt) return null;

  const minsToFeed = diffMinutes(data.nextFeedingAt, now);
  const overdue = minsToFeed <= 0;
  const feedTime = formatTime(data.nextFeedingAt);

  return (
    <div
      className={cn(
        "rounded-2xl p-3.5 border flex items-center gap-3",
        overdue
          ? "bg-gradient-to-r from-red-50 to-orange-50 border-red-200"
          : "bg-gradient-to-r from-sky-50 to-cyan-50 border-sky-200"
      )}
    >
      <span
        className={cn(
          "w-10 h-10 rounded-full flex items-center justify-center flex-shrink-0",
          overdue ? "bg-red-100" : "bg-sky-100"
        )}
      >
        <Milk className={cn("w-5 h-5", overdue ? "text-red-500" : "text-sky-500")} />
      </span>
      <div className="min-w-0 flex-1">
        {overdue ? (
          <>
            <p className="text-sm font-bold text-red-700">
              수유 시간이에요 {minsToFeed < 0 && `(${formatDuration(-minsToFeed)} 지남)`}
            </p>
            <p className="text-xs text-red-500 mt-0.5">
              예상 시각 {feedTime} · 최근 {data.feedingBasedOn}회 기준
            </p>
          </>
        ) : (
          <>
            <p className="text-sm font-semibold text-sky-800">
              다음 수유 예상 <span className="font-bold">{feedTime}</span>
            </p>
            <p className="text-xs text-sky-500 mt-0.5">
              약 {formatDuration(minsToFeed)} 후
              {data.feedingIntervalMinutes
                ? ` · 평소 ${formatDuration(data.feedingIntervalMinutes)} 간격`
                : ""}
            </p>
          </>
        )}
        {data.nextSleepAt && (
          <p className="text-xs text-gray-400 mt-1 flex items-center gap-1">
            <Moon className="w-3 h-3" /> 다음 수면 예상 {formatTime(data.nextSleepAt)}
          </p>
        )}
      </div>
    </div>
  );
}
