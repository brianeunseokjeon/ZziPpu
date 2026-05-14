"use client";

import { useState } from "react";
import { CheckCircle2, AlertTriangle, ChevronDown, ChevronUp } from "lucide-react";
import { Card, CardContent } from "@/shared/components/ui/card";
import type { DailyReview } from "../types/aiReview";

interface Props {
  review: DailyReview;
}

const SECTIONS = [
  {
    key: "feeding_analysis" as const,
    label: "수유",
    emoji: "🍼",
    color: "blue",
    bg: "bg-blue-50",
    border: "border-blue-200",
    tab: "bg-blue-100 text-blue-700",
    activeTab: "bg-blue-500 text-white",
  },
  {
    key: "sleep_analysis" as const,
    label: "수면",
    emoji: "😴",
    color: "purple",
    bg: "bg-purple-50",
    border: "border-purple-200",
    tab: "bg-purple-100 text-purple-700",
    activeTab: "bg-purple-500 text-white",
  },
  {
    key: "diaper_analysis" as const,
    label: "배변",
    emoji: "🧷",
    color: "orange",
    bg: "bg-orange-50",
    border: "border-orange-200",
    tab: "bg-orange-100 text-orange-700",
    activeTab: "bg-orange-500 text-white",
  },
  {
    key: "play_analysis" as const,
    label: "놀이",
    emoji: "🤸",
    color: "green",
    bg: "bg-green-50",
    border: "border-green-200",
    tab: "bg-green-100 text-green-700",
    activeTab: "bg-green-500 text-white",
  },
];

export function DailyReviewCard({ review }: Props) {
  const [activeTab, setActiveTab] = useState(0);
  const [showRecommendations, setShowRecommendations] = useState(true);

  const section = SECTIONS[activeTab];

  return (
    <div className="space-y-3">
      {/* Overall Assessment */}
      <Card>
        <CardContent className="pt-5">
          <div className="bg-gradient-to-br from-blue-50 to-purple-50 rounded-xl p-4 border border-blue-100">
            <p className="text-sm font-semibold text-blue-800 mb-1">전체 평가</p>
            <p className="text-sm text-gray-700 leading-relaxed">{review.overall_assessment}</p>
          </div>
        </CardContent>
      </Card>

      {/* Alerts */}
      {review.alerts.length > 0 && (
        <Card className="border-orange-200">
          <CardContent className="pt-5">
            <div className="flex items-center gap-2 mb-3">
              <AlertTriangle className="w-4 h-4 text-orange-500" />
              <p className="text-sm font-semibold text-orange-700">주의 사항</p>
            </div>
            <div className="space-y-2">
              {review.alerts.map((alert, i) => (
                <div
                  key={i}
                  className="bg-orange-50 border border-orange-200 rounded-xl px-4 py-2.5 text-sm text-orange-800"
                >
                  {alert}
                </div>
              ))}
            </div>
          </CardContent>
        </Card>
      )}

      {/* Section Tabs */}
      <Card>
        <CardContent className="pt-5">
          {/* Tab Bar */}
          <div className="flex gap-2 mb-4 overflow-x-auto pb-1">
            {SECTIONS.map((s, i) => (
              <button
                key={s.key}
                onClick={() => setActiveTab(i)}
                className={`flex-shrink-0 flex items-center gap-1.5 px-3 py-1.5 rounded-xl text-sm font-medium transition-colors ${
                  activeTab === i ? s.activeTab : s.tab
                }`}
              >
                <span>{s.emoji}</span>
                <span>{s.label}</span>
              </button>
            ))}
          </div>

          {/* Tab Content */}
          <div className={`${section.bg} ${section.border} border rounded-xl p-4`}>
            <p className="text-sm text-gray-700 leading-relaxed">{review[section.key]}</p>
          </div>
        </CardContent>
      </Card>

      {/* Recommendations */}
      {review.recommendations.length > 0 && (
        <Card>
          <CardContent className="pt-5">
            <button
              onClick={() => setShowRecommendations((v) => !v)}
              className="flex items-center justify-between w-full mb-3"
            >
              <div className="flex items-center gap-2">
                <CheckCircle2 className="w-4 h-4 text-green-500" />
                <p className="text-sm font-semibold text-green-700">추천 사항</p>
              </div>
              {showRecommendations ? (
                <ChevronUp className="w-4 h-4 text-gray-400" />
              ) : (
                <ChevronDown className="w-4 h-4 text-gray-400" />
              )}
            </button>
            {showRecommendations && (
              <div className="space-y-2">
                {review.recommendations.map((rec, i) => (
                  <div key={i} className="flex items-start gap-2.5">
                    <CheckCircle2 className="w-4 h-4 text-green-400 mt-0.5 flex-shrink-0" />
                    <p className="text-sm text-gray-700 leading-relaxed">{rec}</p>
                  </div>
                ))}
              </div>
            )}
          </CardContent>
        </Card>
      )}
    </div>
  );
}
