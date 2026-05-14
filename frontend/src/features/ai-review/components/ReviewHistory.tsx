"use client";

import { useState } from "react";
import { ChevronDown, ChevronUp, CalendarDays } from "lucide-react";
import { Card, CardContent } from "@/shared/components/ui/card";
import type { DailyReview } from "../types/aiReview";

interface Props {
  reviews: DailyReview[];
}

function getLast7Days(): string[] {
  const days: string[] = [];
  for (let i = 0; i < 7; i++) {
    const d = new Date();
    d.setDate(d.getDate() - i);
    days.push(d.toISOString().slice(0, 10));
  }
  return days;
}

function formatDisplayDate(dateStr: string): string {
  const d = new Date(dateStr + "T00:00:00");
  const today = new Date();
  today.setHours(0, 0, 0, 0);
  const diff = Math.round((today.getTime() - d.getTime()) / (1000 * 60 * 60 * 24));
  const weekdays = ["일", "월", "화", "수", "목", "금", "토"];
  const weekday = weekdays[d.getDay()];
  const mmdd = `${d.getMonth() + 1}/${d.getDate()}(${weekday})`;

  if (diff === 0) return `오늘 ${mmdd}`;
  if (diff === 1) return `어제 ${mmdd}`;
  return mmdd;
}

export function ReviewHistory({ reviews }: Props) {
  const [expandedDate, setExpandedDate] = useState<string | null>(null);
  const last7 = getLast7Days();
  const reviewMap = new Map(reviews.map((r) => [r.review_date, r]));

  const toggle = (date: string) =>
    setExpandedDate((prev) => (prev === date ? null : date));

  return (
    <Card>
      <CardContent className="pt-5">
        <div className="flex items-center gap-2 mb-4">
          <CalendarDays className="w-4 h-4 text-gray-500" />
          <h3 className="text-sm font-semibold text-gray-700">최근 7일 리뷰</h3>
        </div>
        <div className="space-y-2">
          {last7.map((date) => {
            const review = reviewMap.get(date);
            const isExpanded = expandedDate === date;

            return (
              <div key={date}>
                <button
                  onClick={() => review && toggle(date)}
                  className={`w-full flex items-center justify-between px-4 py-3 rounded-xl transition-colors ${
                    review
                      ? "bg-blue-50 hover:bg-blue-100 cursor-pointer"
                      : "bg-gray-50 cursor-default"
                  }`}
                >
                  <span
                    className={`text-sm font-medium ${
                      review ? "text-blue-700" : "text-gray-400"
                    }`}
                  >
                    {formatDisplayDate(date)}
                  </span>
                  {review ? (
                    <div className="flex items-center gap-2">
                      {review.alerts.length > 0 && (
                        <span className="w-2 h-2 rounded-full bg-orange-400" />
                      )}
                      {isExpanded ? (
                        <ChevronUp className="w-4 h-4 text-blue-400" />
                      ) : (
                        <ChevronDown className="w-4 h-4 text-blue-400" />
                      )}
                    </div>
                  ) : (
                    <span className="text-xs text-gray-400">리뷰 없음</span>
                  )}
                </button>

                {review && isExpanded && (
                  <div className="mt-2 ml-2 pl-3 border-l-2 border-blue-200 space-y-2 pb-1">
                    <p className="text-xs text-gray-600 leading-relaxed">
                      {review.overall_assessment}
                    </p>
                    {review.alerts.length > 0 && (
                      <div className="space-y-1">
                        {review.alerts.map((a, i) => (
                          <p key={i} className="text-xs text-orange-600">
                            ⚠️ {a}
                          </p>
                        ))}
                      </div>
                    )}
                  </div>
                )}
              </div>
            );
          })}
        </div>
      </CardContent>
    </Card>
  );
}
