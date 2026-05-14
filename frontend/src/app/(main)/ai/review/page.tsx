import { Bot } from "lucide-react";
import { Card, CardContent } from "@/shared/components/ui/card";

export default function AIReviewPage() {
  return (
    <div className="space-y-4">
      <Card>
        <CardContent className="pt-6">
          <div className="flex flex-col items-center gap-4 py-8 text-center">
            <div className="w-16 h-16 rounded-full bg-gradient-to-br from-blue-400 to-purple-500 flex items-center justify-center">
              <Bot className="w-8 h-8 text-white" />
            </div>
            <div>
              <h2 className="text-xl font-bold text-gray-900 mb-2">AI 육아 리뷰</h2>
              <p className="text-gray-500 text-sm leading-relaxed">
                아기의 수유, 수면, 배변 패턴을 AI가 분석하여
                <br />
                맞춤형 인사이트를 제공합니다.
              </p>
            </div>
            <div className="bg-amber-50 border border-amber-200 rounded-2xl px-5 py-3 text-sm text-amber-700 font-medium">
              🚧 Phase 2에서 준비됩니다
            </div>
          </div>
        </CardContent>
      </Card>

      <Card>
        <CardContent className="pt-4">
          <h3 className="font-semibold text-gray-800 mb-3">준비 중인 기능</h3>
          <div className="space-y-2">
            {[
              "📊 일일/주간 패턴 분석 리포트",
              "🍼 수유 간격 및 양 최적화 제안",
              "😴 수면 품질 평가 및 개선 팁",
              "⚠️ 주의가 필요한 이상 패턴 감지",
            ].map((item) => (
              <div key={item} className="flex items-center gap-2 text-sm text-gray-600 py-1">
                <span>{item}</span>
              </div>
            ))}
          </div>
        </CardContent>
      </Card>
    </div>
  );
}
