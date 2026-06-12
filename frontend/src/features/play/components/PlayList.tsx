"use client";

import { Trash2 } from "lucide-react";
import { usePlayRecords, useDeletePlay } from "../api/playApi";
import { useUIStore } from "@/shared/stores/uiStore";
import { formatTime, formatDuration } from "@/lib/date-utils";
import { Badge } from "@/shared/components/ui/badge";
import { PLAY_TYPES } from "@/config/constants";
import type { PlayType } from "../types/play";

function getPlayInfo(type: PlayType) {
  return PLAY_TYPES.find((p) => p.value === type) ?? PLAY_TYPES[0];
}

export function PlayList() {
  const { activeBabyId, selectedDate } = useUIStore();
  const { data: records, isLoading } = usePlayRecords(activeBabyId, selectedDate);
  const { mutate: deletePlay } = useDeletePlay();

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
        <p className="text-4xl mb-2">🎈</p>
        <p className="text-sm">오늘 터미타임 기록이 없어요</p>
      </div>
    );
  }

  const sorted = [...records].sort(
    (a, b) => new Date(b.startedAt).getTime() - new Date(a.startedAt).getTime()
  );

  return (
    <div className="space-y-2">
      {sorted.map((r) => {
        const info = getPlayInfo(r.playType);
        return (
          <div
            key={r.id}
            className="flex items-center justify-between bg-white rounded-2xl px-4 py-3 border border-gray-100"
          >
            <div className="flex items-center gap-3">
              <div className="w-10 h-10 rounded-full bg-green-50 flex items-center justify-center text-xl">
                {info.emoji}
              </div>
              <div>
                <div className="flex items-center gap-2">
                  <Badge variant="play">{info.label}</Badge>
                  <span className="text-sm font-semibold text-gray-900">
                    {formatDuration(r.durationMinutes)}
                  </span>
                </div>
                <p className="text-xs text-gray-400 mt-0.5">{formatTime(r.startedAt)}</p>
                {r.memo && <p className="text-xs text-gray-500 mt-0.5">{r.memo}</p>}
              </div>
            </div>
            <button
              onClick={() => deletePlay({ babyId: activeBabyId, playId: r.id })}
              className="p-2 rounded-full hover:bg-red-50 text-gray-300 hover:text-red-400 transition-colors"
            >
              <Trash2 className="w-4 h-4" />
            </button>
          </div>
        );
      })}
    </div>
  );
}
