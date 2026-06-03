"use client";

import { useState } from "react";
import { Trash2, Pencil } from "lucide-react";
import { useFeedings, useDeleteFeeding } from "../api/feedingApi";
import { useUIStore } from "@/shared/stores/uiStore";
import { formatTime } from "@/lib/date-utils";
import { Feeding, FeedingType } from "../types/feeding";
import { Badge } from "@/shared/components/ui/badge";
import { FeedingEditModal } from "./FeedingEditModal";

function feedingLabel(type: FeedingType): string {
  switch (type) {
    case FeedingType.Formula: return "분유";
    case FeedingType.BreastLeft: return "모유(좌)";
    case FeedingType.BreastRight: return "모유(우)";
    case FeedingType.BreastBoth: return "모유(양쪽)";
  }
}

export function FeedingList() {
  const { activeBabyId, selectedDate } = useUIStore();
  const { data: feedings, isLoading } = useFeedings(activeBabyId, selectedDate);
  const { mutate: deleteFeeding } = useDeleteFeeding();
  const [editing, setEditing] = useState<Feeding | null>(null);

  if (isLoading) {
    return (
      <div className="space-y-2">
        {[1, 2, 3].map((i) => (
          <div key={i} className="h-16 bg-gray-100 rounded-2xl animate-pulse" />
        ))}
      </div>
    );
  }

  if (!feedings || feedings.length === 0) {
    return (
      <div className="text-center py-10 text-gray-400">
        <p className="text-4xl mb-2">🍼</p>
        <p className="text-sm">오늘 수유 기록이 없어요</p>
      </div>
    );
  }

  const sorted = [...feedings].sort(
    (a, b) => new Date(b.startedAt).getTime() - new Date(a.startedAt).getTime()
  );

  return (
    <>
      <div className="space-y-2">
        {sorted.map((f) => (
          <button
            key={f.id}
            type="button"
            onClick={() => setEditing(f)}
            className="w-full flex items-center justify-between bg-white rounded-2xl px-4 py-3 border border-gray-100 text-left hover:border-blue-200 hover:bg-blue-50/30 active:scale-[0.99] transition-all"
          >
            <div className="flex items-center gap-3">
              <div className="w-10 h-10 rounded-full bg-blue-50 flex items-center justify-center text-xl">
                🍼
              </div>
              <div>
                <div className="flex items-center gap-2">
                  <Badge variant="feeding">{feedingLabel(f.feedingType)}</Badge>
                  {f.amountMl && (
                    <span className="text-sm font-semibold text-gray-900">
                      {f.amountMl}ml
                    </span>
                  )}
                  {f.durationMinutes && (
                    <span className="text-sm font-semibold text-gray-900">
                      {f.durationMinutes}분
                    </span>
                  )}
                </div>
                <p className="text-xs text-gray-400 mt-0.5 flex items-center gap-1">
                  {formatTime(f.startedAt)}
                  <Pencil className="w-3 h-3 text-gray-300" />
                </p>
                {f.memo && <p className="text-xs text-gray-500 mt-0.5">{f.memo}</p>}
              </div>
            </div>
            <span
              role="button"
              tabIndex={-1}
              onClick={(e) => {
                e.stopPropagation();
                deleteFeeding({ babyId: activeBabyId, feedingId: f.id });
              }}
              className="p-2 rounded-full hover:bg-red-50 text-gray-300 hover:text-red-400 transition-colors"
            >
              <Trash2 className="w-4 h-4" />
            </span>
          </button>
        ))}
      </div>

      {editing && (
        <FeedingEditModal feeding={editing} onClose={() => setEditing(null)} />
      )}
    </>
  );
}
