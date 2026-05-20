"use client";

import { useMemo } from "react";
import { Calendar, CheckCircle2 } from "lucide-react";
import { useMilestones } from "../api/developmentApi";
import { useBabyInfo } from "@/features/baby/hooks/useBabyInfo";
import {
  daysUntilMilestone,
  getDateForAgeDays,
  formatKoreanDate,
} from "@/lib/milestoneMath";
import { cn } from "@/lib/utils";

const CATEGORY_STYLE = {
  celebration: "bg-pink-50 border-pink-200 text-pink-700",
  checkup: "bg-blue-50 border-blue-200 text-blue-700",
  developmental: "bg-green-50 border-green-200 text-green-700",
} as const;

export function MilestoneTimeline() {
  const { birthDate } = useBabyInfo();
  const { data: milestones, isLoading } = useMilestones();

  const items = useMemo(() => {
    if (!milestones) return [];
    return milestones
      .map((m) => ({
        ...m,
        dday: daysUntilMilestone(birthDate, m.days),
        date: getDateForAgeDays(birthDate, m.days),
      }))
      .sort((a, b) => a.days - b.days);
  }, [milestones, birthDate]);

  if (isLoading) {
    return (
      <div className="bg-white rounded-2xl p-4 shadow-sm border border-gray-100">
        <div className="text-sm text-gray-400">마일스톤 불러오는 중...</div>
      </div>
    );
  }

  const upcoming = items.filter((m) => m.dday >= 0).slice(0, 6);
  const past = items.filter((m) => m.dday < 0).slice(-3);

  return (
    <div className="bg-white rounded-2xl p-4 shadow-sm border border-gray-100 space-y-3">
      <div className="flex items-center gap-2">
        <Calendar className="w-4 h-4 text-blue-500" />
        <h3 className="text-sm font-semibold text-gray-800">다가오는 마일스톤</h3>
      </div>

      {upcoming.length === 0 ? (
        <p className="text-sm text-gray-400">예정된 마일스톤이 없습니다.</p>
      ) : (
        <div className="flex gap-2 overflow-x-auto pb-1 -mx-1 px-1">
          {upcoming.map((m) => (
            <div
              key={`up-${m.days}`}
              className={cn(
                "flex-shrink-0 w-32 rounded-xl border-2 p-3",
                CATEGORY_STYLE[m.category]
              )}
            >
              <div className="text-2xl">{m.emoji}</div>
              <div className="text-sm font-bold mt-1">{m.label}</div>
              <div className="text-xs opacity-75 mt-0.5">
                {m.dday === 0 ? "오늘!" : `D-${m.dday}`}
              </div>
              <div className="text-[10px] opacity-60 mt-1">
                {formatKoreanDate(m.date).split("(")[0].trim()}
              </div>
            </div>
          ))}
        </div>
      )}

      {past.length > 0 && (
        <details className="text-xs text-gray-500">
          <summary className="cursor-pointer hover:text-gray-700">
            <CheckCircle2 className="w-3 h-3 inline -mt-0.5 mr-1" />
            지난 마일스톤 ({past.length}개)
          </summary>
          <div className="flex gap-2 overflow-x-auto pb-1 mt-2 -mx-1 px-1">
            {past.map((m) => (
              <div
                key={`past-${m.days}`}
                className="flex-shrink-0 w-28 rounded-xl bg-gray-50 border border-gray-200 p-2.5 opacity-70"
              >
                <div className="text-lg">{m.emoji}</div>
                <div className="text-xs font-semibold text-gray-700">{m.label}</div>
                <div className="text-[10px] text-gray-400">D+{-m.dday}</div>
              </div>
            ))}
          </div>
        </details>
      )}
    </div>
  );
}
