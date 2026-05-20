"use client";

/**
 * VaccinationScheduleCard — 다가오는/지난 예방접종 일정 카드.
 *
 * 발달 탭 상단에 표시 (Phase 10에서 홈 → 발달로 이동).
 */

import Link from "next/link";
import { ChevronRight, Syringe } from "lucide-react";
import { useVaccinations } from "@/features/vaccination/api/vaccinationApi";
import { formatDate } from "@/lib/date-utils";
import { MOCK_BABY_ID } from "@/config/constants";

export function VaccinationScheduleCard() {
  const { data: allVaccinations } = useVaccinations(MOCK_BABY_ID);

  const allPending = (allVaccinations ?? [])
    .filter((v) => !v.administeredDate)
    .sort((a, b) => new Date(a.scheduledDate).getTime() - new Date(b.scheduledDate).getTime());

  const overdue = allPending.filter((v) => v.isOverdue);
  const upcoming = allPending.filter((v) => !v.isOverdue);
  const pending = [...overdue, ...upcoming].slice(0, 4);

  return (
    <Link href="/vaccination">
      <div className="bg-white rounded-2xl border border-gray-100 overflow-hidden">
        <div
          className={`px-4 py-3 flex items-center justify-between ${
            overdue.length > 0 ? "bg-red-50" : "bg-teal-50"
          }`}
        >
          <div className="flex items-center gap-2">
            <Syringe
              className={`w-4 h-4 ${overdue.length > 0 ? "text-red-500" : "text-teal-600"}`}
            />
            <span
              className={`text-sm font-semibold ${
                overdue.length > 0 ? "text-red-700" : "text-teal-700"
              }`}
            >
              예방접종 일정
            </span>
            {overdue.length > 0 && (
              <span className="text-xs bg-red-500 text-white rounded-full px-1.5 py-0.5 font-medium">
                기한 초과 {overdue.length}건
              </span>
            )}
          </div>
          <ChevronRight className="w-4 h-4 text-gray-400" />
        </div>

        {pending.length === 0 ? (
          <div className="px-4 py-3 text-xs text-gray-400">예정된 접종이 없어요</div>
        ) : (
          <div className="divide-y divide-gray-50">
            {pending.map((v) => (
              <div
                key={v.id}
                className="px-4 py-2.5 flex items-center justify-between"
              >
                <div className="flex items-center gap-2.5">
                  <span className="text-lg">💉</span>
                  <div>
                    <p className="text-xs font-semibold text-gray-800">
                      {v.vaccineName}{" "}
                      <span className="text-gray-400 font-normal">
                        {v.doseNumber}차
                      </span>
                    </p>
                    <p className="text-xs text-gray-400">
                      {formatDate(v.scheduledDate)}
                    </p>
                  </div>
                </div>
                <span
                  className={`text-xs font-medium px-2 py-0.5 rounded-full ${
                    v.isOverdue
                      ? "bg-red-100 text-red-600"
                      : v.daysUntil === 0
                      ? "bg-orange-100 text-orange-600"
                      : v.daysUntil !== null && v.daysUntil <= 7
                      ? "bg-yellow-100 text-yellow-700"
                      : "bg-blue-50 text-blue-500"
                  }`}
                >
                  {v.isOverdue
                    ? `D+${Math.abs(v.daysUntil ?? 0)}`
                    : v.daysUntil === 0
                    ? "오늘"
                    : `D-${v.daysUntil}`}
                </span>
              </div>
            ))}
          </div>
        )}
      </div>
    </Link>
  );
}
