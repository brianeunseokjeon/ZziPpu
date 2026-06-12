"use client";

import { Trash2 } from "lucide-react";
import { useGrowthRecords, useDeleteGrowthRecord } from "../api/growthApi";
import { useUIStore } from "@/shared/stores/uiStore";
import { formatDate } from "@/lib/date-utils";
import type { GrowthRecord } from "../types/growth";

function formatWeight(g: number | null): string | null {
  if (g === null) return null;
  return `${(g / 1000).toFixed(2)}kg`;
}

function summarize(r: GrowthRecord): string {
  const parts: string[] = [];
  if (r.weightG !== null) parts.push(formatWeight(r.weightG)!);
  if (r.heightCm !== null) parts.push(`${r.heightCm}cm`);
  if (r.headCircumferenceCm !== null)
    parts.push(`머리 ${r.headCircumferenceCm}cm`);
  return parts.join(" · ") || "-";
}

export function GrowthList() {
  const activeBabyId = useUIStore((s) => s.activeBabyId);
  const { data: records, isLoading } = useGrowthRecords(activeBabyId);
  const { mutate: deleteRecord } = useDeleteGrowthRecord();

  if (isLoading) {
    return (
      <div className="space-y-2">
        {[1, 2, 3].map((i) => (
          <div key={i} className="h-16 bg-gray-100 rounded-2xl animate-pulse" />
        ))}
      </div>
    );
  }

  if (!records || records.length === 0) {
    return (
      <div className="text-center py-10 text-gray-400">
        <p className="text-4xl mb-2">🌱</p>
        <p className="text-sm">성장 기록이 없어요</p>
      </div>
    );
  }

  const sorted = [...records].sort(
    (a, b) =>
      new Date(b.recordedAt).getTime() - new Date(a.recordedAt).getTime()
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
              🌱
            </div>
            <div>
              <p className="text-sm font-semibold text-gray-800">
                {summarize(r)}
              </p>
              <p className="text-xs text-gray-400 mt-0.5">
                {formatDate(r.recordedAt)}
              </p>
              {r.memo && (
                <p className="text-xs text-gray-500 mt-0.5">{r.memo}</p>
              )}
            </div>
          </div>
          <button
            onClick={() =>
              deleteRecord({ babyId: activeBabyId, recordId: r.id })
            }
            className="p-2 rounded-full hover:bg-red-50 text-gray-300 hover:text-red-400 transition-colors"
          >
            <Trash2 className="w-4 h-4" />
          </button>
        </div>
      ))}
    </div>
  );
}
