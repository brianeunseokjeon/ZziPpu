"use client";

import { useSleepRecords } from "@/features/sleep/api/sleepApi";
import { useUIStore } from "@/shared/stores/uiStore";
import { formatDuration } from "@/lib/date-utils";
import { Card, CardHeader, CardTitle, CardContent } from "@/shared/components/ui/card";

export function SleepChart() {
  const { activeBabyId, selectedDate } = useUIStore();
  const { data: records, isLoading } = useSleepRecords(activeBabyId, selectedDate);

  if (isLoading) {
    return (
      <Card>
        <CardHeader>
          <CardTitle className="text-base">수면</CardTitle>
        </CardHeader>
        <CardContent>
          <div className="h-16 bg-gray-100 rounded-xl animate-pulse" />
        </CardContent>
      </Card>
    );
  }

  const dayStart = new Date(`${selectedDate}T00:00:00`).getTime();
  const dayEnd = new Date(`${selectedDate}T23:59:59`).getTime();
  const totalMs = dayEnd - dayStart;

  function toPercent(ts: number) {
    return ((ts - dayStart) / totalMs) * 100;
  }

  function toWidth(start: number, end: number) {
    return ((end - start) / totalMs) * 100;
  }

  const totalMinutes =
    records?.reduce((acc, r) => {
      if (!r.endedAt) return acc;
      const diff = Math.round(
        (new Date(r.endedAt).getTime() - new Date(r.startedAt).getTime()) / 60000
      );
      return acc + diff;
    }, 0) ?? 0;

  return (
    <Card>
      <CardHeader>
        <CardTitle className="text-base">
          😴 수면 패턴
          {totalMinutes > 0 && (
            <span className="ml-2 text-sm font-normal text-gray-500">
              총 {formatDuration(totalMinutes)}
            </span>
          )}
        </CardTitle>
      </CardHeader>
      <CardContent>
        {!records || records.length === 0 ? (
          <div className="h-12 flex items-center justify-center text-gray-400 text-sm">
            수면 기록이 없어요
          </div>
        ) : (
          <>
            <div className="relative h-8 bg-gray-100 rounded-full overflow-hidden">
              {records.map((r) => {
                if (!r.endedAt) return null;
                const startTs = new Date(r.startedAt).getTime();
                const endTs = new Date(r.endedAt).getTime();
                const left = Math.max(0, toPercent(startTs));
                const width = Math.min(100 - left, toWidth(startTs, endTs));
                return (
                  <div
                    key={r.id}
                    className="absolute top-0 bottom-0 bg-purple-400 rounded-full"
                    style={{ left: `${left}%`, width: `${width}%` }}
                    title={`${formatDuration(
                      Math.round((endTs - startTs) / 60000)
                    )}`}
                  />
                );
              })}
            </div>
            <div className="flex justify-between text-xs text-gray-400 mt-1">
              <span>0시</span>
              <span>6시</span>
              <span>12시</span>
              <span>18시</span>
              <span>24시</span>
            </div>
          </>
        )}
      </CardContent>
    </Card>
  );
}
