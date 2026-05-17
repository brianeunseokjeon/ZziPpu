"use client";

import { useState } from "react";
import {
  CheckCircle2,
  AlertTriangle,
  AlertCircle,
  ThumbsUp,
  Lightbulb,
  ChevronDown,
  ChevronUp,
} from "lucide-react";
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
    bg: "bg-blue-50",
    border: "border-blue-200",
    tab: "bg-blue-100 text-blue-700",
    activeTab: "bg-blue-500 text-white",
  },
  {
    key: "sleep_analysis" as const,
    label: "수면",
    emoji: "😴",
    bg: "bg-purple-50",
    border: "border-purple-200",
    tab: "bg-purple-100 text-purple-700",
    activeTab: "bg-purple-500 text-white",
  },
  {
    key: "diaper_analysis" as const,
    label: "배변",
    emoji: "🧷",
    bg: "bg-orange-50",
    border: "border-orange-200",
    tab: "bg-orange-100 text-orange-700",
    activeTab: "bg-orange-500 text-white",
  },
  {
    key: "play_analysis" as const,
    label: "놀이",
    emoji: "🤸",
    bg: "bg-green-50",
    border: "border-green-200",
    tab: "bg-green-100 text-green-700",
    activeTab: "bg-green-500 text-white",
  },
];

function SectionList({
  items,
  icon: Icon,
  iconClass,
  itemClass,
}: {
  items: string[];
  icon: React.ElementType;
  iconClass: string;
  itemClass: string;
}) {
  if (!items || items.length === 0) return null;
  return (
    <div className="space-y-2">
      {items.map((item, i) => (
        <div key={i} className={`flex items-start gap-2.5 rounded-xl px-3 py-2.5 ${itemClass}`}>
          <Icon className={`w-4 h-4 mt-0.5 flex-shrink-0 ${iconClass}`} />
          <p className="text-sm leading-relaxed">{item}</p>
        </div>
      ))}
    </div>
  );
}

export function DailyReviewCard({ review }: Props) {
  const [activeTab, setActiveTab] = useState(0);
  const [showDetails, setShowDetails] = useState(false);

  const section = SECTIONS[activeTab];
  const hasPositives = review.positives?.length > 0;
  const hasConsiderations = review.considerations?.length > 0;
  const hasConcerns = review.concerns?.length > 0;
  const hasCritical = review.critical_warnings?.length > 0;

  return (
    <div className="space-y-3">
      {hasCritical && (
        <Card className="border-red-300">
          <CardContent className="pt-5">
            <div className="flex items-center gap-2 mb-3">
              <AlertCircle className="w-5 h-5 text-red-600" />
              <p className="text-sm font-bold text-red-700">즉시 확인 필요</p>
            </div>
            <SectionList
              items={review.critical_warnings}
              icon={AlertCircle}
              iconClass="text-red-500"
              itemClass="bg-red-50 border border-red-200 text-red-800"
            />
          </CardContent>
        </Card>
      )}

      <Card>
        <CardContent className="pt-5">
          <div className="bg-gradient-to-br from-blue-50 to-purple-50 rounded-xl p-4 border border-blue-100">
            <p className="text-sm font-semibold text-blue-800 mb-1">오늘의 총평</p>
            <p className="text-sm text-gray-700 leading-relaxed">{review.overall_assessment}</p>
          </div>
        </CardContent>
      </Card>

      {hasPositives && (
        <Card className="border-green-200">
          <CardContent className="pt-5">
            <div className="flex items-center gap-2 mb-3">
              <ThumbsUp className="w-4 h-4 text-green-600" />
              <p className="text-sm font-semibold text-green-700">오늘 잘 한 점</p>
            </div>
            <SectionList
              items={review.positives}
              icon={CheckCircle2}
              iconClass="text-green-500"
              itemClass="bg-green-50 border border-green-100 text-green-800"
            />
          </CardContent>
        </Card>
      )}

      {hasConcerns && (
        <Card className="border-yellow-200">
          <CardContent className="pt-5">
            <div className="flex items-center gap-2 mb-3">
              <AlertTriangle className="w-4 h-4 text-yellow-600" />
              <p className="text-sm font-semibold text-yellow-700">주의가 필요한 점</p>
            </div>
            <SectionList
              items={review.concerns}
              icon={AlertTriangle}
              iconClass="text-yellow-500"
              itemClass="bg-yellow-50 border border-yellow-100 text-yellow-800"
            />
          </CardContent>
        </Card>
      )}

      {hasConsiderations && (
        <Card>
          <CardContent className="pt-5">
            <div className="flex items-center gap-2 mb-3">
              <Lightbulb className="w-4 h-4 text-blue-500" />
              <p className="text-sm font-semibold text-blue-700">앞으로 고려할 것</p>
            </div>
            <SectionList
              items={review.considerations}
              icon={Lightbulb}
              iconClass="text-blue-400"
              itemClass="bg-blue-50 border border-blue-100 text-blue-800"
            />
          </CardContent>
        </Card>
      )}

      <Card>
        <CardContent className="pt-5">
          <button
            onClick={() => setShowDetails((v) => !v)}
            className="flex items-center justify-between w-full mb-3"
          >
            <p className="text-sm font-semibold text-gray-700">영역별 상세 분석</p>
            {showDetails ? (
              <ChevronUp className="w-4 h-4 text-gray-400" />
            ) : (
              <ChevronDown className="w-4 h-4 text-gray-400" />
            )}
          </button>

          {showDetails && (
            <>
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
              <div className={`${section.bg} ${section.border} border rounded-xl p-4`}>
                <p className="text-sm text-gray-700 leading-relaxed">{review[section.key]}</p>
              </div>
            </>
          )}
        </CardContent>
      </Card>

      {review.recommendations.length > 0 && (
        <Card>
          <CardContent className="pt-5">
            <div className="flex items-center gap-2 mb-3">
              <CheckCircle2 className="w-4 h-4 text-teal-500" />
              <p className="text-sm font-semibold text-teal-700">내일을 위한 추천</p>
            </div>
            <div className="space-y-2">
              {review.recommendations.map((rec, i) => (
                <div key={i} className="flex items-start gap-2.5">
                  <CheckCircle2 className="w-4 h-4 text-teal-400 mt-0.5 flex-shrink-0" />
                  <p className="text-sm text-gray-700 leading-relaxed">{rec}</p>
                </div>
              ))}
            </div>
          </CardContent>
        </Card>
      )}
    </div>
  );
}
