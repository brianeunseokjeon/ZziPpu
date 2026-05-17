"use client";

import { Trash2 } from "lucide-react";
import { useDiapers, useDeleteDiaper } from "../api/diaperApi";
import { useUIStore } from "@/shared/stores/uiStore";
import { formatTime } from "@/lib/date-utils";
import { DiaperType } from "../types/diaper";
import { Badge } from "@/shared/components/ui/badge";
import { STOOL_COLORS } from "@/config/constants";

function diaperLabel(type: DiaperType) {
  if (type === DiaperType.Pee) return "소변";
  if (type === DiaperType.Poop) return "대변";
  return "둘 다";
}

function diaperEmoji(type: DiaperType) {
  if (type === DiaperType.Pee) return "💧";
  if (type === DiaperType.Poop) return "💩";
  return "💧💩";
}


export function DiaperList() {
  const { activeBabyId, selectedDate } = useUIStore();
  const { data: diapers, isLoading } = useDiapers(activeBabyId, selectedDate);
  const { mutate: deleteDiaper } = useDeleteDiaper();

  if (isLoading) {
    return (
      <div className="space-y-2">
        {[1, 2].map((i) => (
          <div key={i} className="h-16 bg-gray-100 rounded-2xl animate-pulse" />
        ))}
      </div>
    );
  }

  if (!diapers || diapers.length === 0) {
    return (
      <div className="text-center py-10 text-gray-400">
        <p className="text-4xl mb-2">🧷</p>
        <p className="text-sm">오늘 배변 기록이 없어요</p>
      </div>
    );
  }

  const sorted = [...diapers].sort(
    (a, b) => new Date(b.recordedAt).getTime() - new Date(a.recordedAt).getTime()
  );

  return (
    <div className="space-y-2">
      {sorted.map((d) => {
        const colorInfo = d.stoolColor
          ? STOOL_COLORS.find((c) => c.value === d.stoolColor)
          : null;

        return (
          <div
            key={d.id}
            className="flex items-center justify-between bg-white rounded-2xl px-4 py-3 border border-gray-100"
          >
            <div className="flex items-center gap-3">
              <div className="w-10 h-10 rounded-full bg-orange-50 flex items-center justify-center text-xl">
                {diaperEmoji(d.diaperType)}
              </div>
              <div>
                <div className="flex items-center gap-2">
                  <Badge variant="diaper">{diaperLabel(d.diaperType)}</Badge>
                  {colorInfo && (
                    <span className="flex items-center gap-1 text-xs text-gray-500">
                      <span
                        className="w-3 h-3 rounded-full border border-gray-200"
                        style={{ backgroundColor: colorInfo.hex }}
                      />
                      {colorInfo.label}
                    </span>
                  )}
                </div>
                <p className="text-xs text-gray-400 mt-0.5">{formatTime(d.recordedAt)}</p>
                {d.memo && <p className="text-xs text-gray-500 mt-0.5">{d.memo}</p>}
              </div>
            </div>
            <button
              onClick={() => deleteDiaper({ babyId: activeBabyId, diaperId: d.id })}
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
