"use client";

import { Bot, RefreshCw, Sparkles } from "lucide-react";
import { Card, CardContent } from "@/shared/components/ui/card";
import { Button } from "@/shared/components/ui/button";
import { MOCK_BABY_ID } from "@/config/constants";
import {
  useGenerateReview,
  useAIReviews,
  DailyReviewCard,
  ReviewHistory,
} from "@/features/ai-review";

function getTodayString(): string {
  const d = new Date();
  return d.toISOString().slice(0, 10);
}

function formatKoreanDate(dateStr: string): string {
  const d = new Date(dateStr + "T00:00:00");
  return d.toLocaleDateString("ko-KR", {
    year: "numeric",
    month: "long",
    day: "numeric",
    weekday: "short",
  });
}

export default function AIReviewPage() {
  const today = getTodayString();
  const { data: reviews = [], isLoading: reviewsLoading } = useAIReviews(MOCK_BABY_ID);
  const generateMutation = useGenerateReview(MOCK_BABY_ID, today);

  const todayReview = reviews.find((r) => r.reviewDate === today);

  const handleGenerate = () => {
    generateMutation.mutate();
  };

  return (
    <div className="space-y-4">
      {/* Header */}
      <Card>
        <CardContent className="pt-5">
          <div className="flex items-center justify-between">
            <div className="flex items-center gap-3">
              <div className="w-10 h-10 rounded-full bg-gradient-to-br from-blue-400 to-purple-500 flex items-center justify-center">
                <Bot className="w-5 h-5 text-white" />
              </div>
              <div>
                <h2 className="text-base font-bold text-gray-900">AI 육아 리뷰</h2>
                <p className="text-xs text-gray-500">{formatKoreanDate(today)}</p>
              </div>
            </div>
            <Button
              size="sm"
              onClick={handleGenerate}
              disabled={generateMutation.isPending}
              className="flex items-center gap-1.5"
            >
              {generateMutation.isPending ? (
                <RefreshCw className="w-3.5 h-3.5 animate-spin" />
              ) : (
                <Sparkles className="w-3.5 h-3.5" />
              )}
              {todayReview ? "재생성" : "리뷰 생성"}
            </Button>
          </div>
        </CardContent>
      </Card>

      {/* Loading State */}
      {generateMutation.isPending && (
        <Card>
          <CardContent className="pt-6">
            <div className="flex flex-col items-center gap-4 py-8 text-center">
              <div className="w-12 h-12 rounded-full bg-gradient-to-br from-blue-100 to-purple-100 flex items-center justify-center">
                <RefreshCw className="w-6 h-6 text-blue-400 animate-spin" />
              </div>
              <div>
                <p className="text-sm font-semibold text-gray-700">
                  AI가 오늘의 육아를 분석하고 있어요...
                </p>
                <p className="text-xs text-gray-400 mt-1">잠시만 기다려 주세요</p>
              </div>
            </div>
          </CardContent>
        </Card>
      )}

      {/* Error State */}
      {generateMutation.isError && (
        <Card className="border-red-200">
          <CardContent className="pt-4">
            <p className="text-sm text-red-600 text-center py-2">
              리뷰 생성 중 오류가 발생했습니다. 다시 시도해 주세요.
            </p>
          </CardContent>
        </Card>
      )}

      {/* Today Review */}
      {!generateMutation.isPending && todayReview && (
        <DailyReviewCard review={todayReview} />
      )}

      {/* Empty State */}
      {!generateMutation.isPending && !todayReview && !reviewsLoading && (
        <Card>
          <CardContent className="pt-6">
            <div className="flex flex-col items-center gap-4 py-8 text-center">
              <div className="w-14 h-14 rounded-full bg-blue-50 flex items-center justify-center">
                <Sparkles className="w-7 h-7 text-blue-300" />
              </div>
              <div>
                <p className="text-sm font-semibold text-gray-700 mb-1">
                  오늘의 리뷰가 아직 없어요
                </p>
                <p className="text-xs text-gray-400 leading-relaxed">
                  수유, 수면, 배변 기록을 바탕으로
                  <br />
                  AI가 오늘의 육아를 분석해 드립니다
                </p>
              </div>
              <Button onClick={handleGenerate} className="flex items-center gap-2">
                <Sparkles className="w-4 h-4" />
                지금 리뷰 생성하기
              </Button>
            </div>
          </CardContent>
        </Card>
      )}

      {/* Review History */}
      {!reviewsLoading && <ReviewHistory reviews={reviews} />}
    </div>
  );
}
