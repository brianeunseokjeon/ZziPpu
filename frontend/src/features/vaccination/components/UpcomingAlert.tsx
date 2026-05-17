"use client";

import { AlertTriangle } from "lucide-react";
import { useUpcomingVaccinations } from "../api/vaccinationApi";
import { MOCK_BABY_ID } from "@/config/constants";
import { formatDate } from "@/lib/date-utils";

export function UpcomingAlert() {
  const { data: upcoming } = useUpcomingVaccinations(MOCK_BABY_ID);

  if (!upcoming || upcoming.length === 0) return null;

  const overdue = upcoming.filter((v) => v.isOverdue);
  const pending = upcoming.filter((v) => !v.isOverdue);

  return (
    <div
      className={`rounded-2xl p-4 border ${
        overdue.length > 0
          ? "bg-red-50 border-red-200"
          : "bg-orange-50 border-orange-200"
      }`}
    >
      <div className="flex items-start gap-3">
        <AlertTriangle
          className={`w-5 h-5 mt-0.5 shrink-0 ${
            overdue.length > 0 ? "text-red-500" : "text-orange-500"
          }`}
        />
        <div className="flex-1 min-w-0">
          <p
            className={`text-sm font-semibold ${
              overdue.length > 0 ? "text-red-700" : "text-orange-700"
            }`}
          >
            {overdue.length > 0
              ? `접종 기한이 지난 항목이 ${overdue.length}개 있어요`
              : `30일 이내 예방접종 ${upcoming.length}건`}
          </p>
          <div className="mt-1.5 space-y-0.5">
            {upcoming.slice(0, 3).map((v) => (
              <p
                key={v.id}
                className={`text-xs ${
                  v.isOverdue ? "text-red-600" : "text-orange-600"
                }`}
              >
                {v.vaccineName} {v.doseNumber}차 · {formatDate(v.scheduledDate)}
                {v.isOverdue && " (기한 초과)"}
              </p>
            ))}
            {upcoming.length > 3 && (
              <p className="text-xs text-gray-400">
                외 {upcoming.length - 3}건 더 있어요
              </p>
            )}
          </div>
        </div>
      </div>
    </div>
  );
}
