"use client";

import { Trash2 } from "lucide-react";
import { useSleepRecords, useDeleteSleep } from "../api/sleepApi";
import { useUIStore } from "@/shared/stores/uiStore";
import { formatTime, formatDuration } from "@/lib/date-utils";
import { Badge } from "@/shared/components/ui/badge";

export function SleepList() {
  const { activeBabyId, selectedDate } = useUIStore();
  const { data: records, isLoading } = useSleepRecords(activeBabyId, selectedDate);
  const { mutate: deleteSleep } = useDeleteSleep();

  if (isLoading) {
    return (
      <div className="space-y-2">
        {[1, 2].map((i) => (
          <div key={i} className="h-16 bg-gray-100 rounded-2xl animate-pulse" />
        ))}
      </div>
    );
  }

  if (!records || records.length === 0) {
    return (
      <div className="text-center py-10 text-gray-400">
        <p className="text-4xl mb-2">😴</p>
        <p className="text-sm">오늘 수면 기록이 없어요</p>
      </div>
    );
  }

  const sorted = [...records].sort(
    (a, b) => new Date(b.startedAt).getTime() - new Date(a.startedAt).getTime()
  );

  return (
    <div className="space-y-2">
      {sorted.map((r) => (
        <div
          key={r.id}
          className="flex items-center justify-between bg-white rounded-2xl px-4 py-3 border border-gray-100"
        >
          <div className="flex items-center gap-3">
            <div className="w-10 h-10 rounded-full bg-purple-50 flex items-center justify-center text-xl">
              😴
            </div>
            <div>
              <div className="flex items-center gap-2">
                <span className="text-sm text-gray-600">
                  {formatTime(r.startedAt)}
                  {r.endedAt && ` ~ ${formatTime(r.endedAt)}`}
                </span>
                {r.endedAt && (
                  <Badge variant="sleep">
                    {r.durationMinutes
                      ? formatDuration(r.durationMinutes)
                      : formatDuration(
                          Math.round(
                            (new Date(r.endedAt).getTime() -
                              new Date(r.startedAt).getTime()) /
                              60000
                          )
                        )}
                  </Badge>
                )}
                {!r.endedAt && (
                  <Badge variant="sleep">수면 중</Badge>
                )}
              </div>
              {r.memo && <p className="text-xs text-gray-500 mt-0.5">{r.memo}</p>}
            </div>
          </div>
          <button
            onClick={() => deleteSleep({ babyId: activeBabyId, sleepId: r.id })}
            className="p-2 rounded-full hover:bg-red-50 text-gray-300 hover:text-red-400 transition-colors"
          >
            <Trash2 className="w-4 h-4" />
          </button>
        </div>
      ))}
    </div>
  );
}
