"use client";

import {
  Activity, Brain, Ear, Heart, MessageCircle, Smile,
  AlertTriangle, BookOpen, Sparkles, Milk, Moon, Gamepad2, ChevronLeft, ChevronRight,
} from "lucide-react";
import type { DevelopmentStage, Priority } from "../types/development";
import { cn } from "@/lib/utils";

const PRIORITY_STYLE: Record<Priority, { bg: string; border: string; badge: string; label: string }> = {
  high: { bg: "bg-red-50", border: "border-red-200", badge: "bg-red-500 text-white", label: "필수" },
  medium: { bg: "bg-yellow-50", border: "border-yellow-200", badge: "bg-yellow-500 text-white", label: "권장" },
  low: { bg: "bg-gray-50", border: "border-gray-200", badge: "bg-gray-400 text-white", label: "참고" },
};

const K_DST = [
  { key: "grossMotor", label: "대근육", icon: Activity, color: "text-orange-500" },
  { key: "fineMotor", label: "소근육", icon: Heart, color: "text-pink-500" },
  { key: "cognition", label: "인지", icon: Brain, color: "text-purple-500" },
  { key: "language", label: "언어", icon: MessageCircle, color: "text-blue-500" },
  { key: "social", label: "사회성", icon: Smile, color: "text-yellow-500" },
  { key: "selfCare", label: "자조", icon: Ear, color: "text-green-500" },
] as const;

interface Props {
  stage: DevelopmentStage;
  previousLabel?: string | null;
  nextLabel?: string | null;
  onPrev?: () => void;
  onNext?: () => void;
  isPreview?: boolean;  // 이전/다음 미리보기 모드 (액션·위험은 숨김)
}

export function StageDetail({ stage, previousLabel, nextLabel, onPrev, onNext, isPreview }: Props) {
  return (
    <div className="space-y-4">
      {/* 시기 네비게이션 */}
      <div className="flex items-center justify-between gap-2 bg-white rounded-2xl border border-gray-100 p-3">
        <button
          onClick={onPrev}
          disabled={!previousLabel}
          className="flex items-center gap-1 text-xs text-gray-500 disabled:text-gray-300 hover:text-blue-500"
        >
          <ChevronLeft className="w-3.5 h-3.5" />
          <span className="truncate max-w-[80px]">{previousLabel ?? "처음"}</span>
        </button>
        <div className="text-sm font-bold text-gray-800 text-center flex-1">{stage.label}</div>
        <button
          onClick={onNext}
          disabled={!nextLabel}
          className="flex items-center gap-1 text-xs text-gray-500 disabled:text-gray-300 hover:text-blue-500"
        >
          <span className="truncate max-w-[80px]">{nextLabel ?? "마지막"}</span>
          <ChevronRight className="w-3.5 h-3.5" />
        </button>
      </div>

      <p className="text-sm text-gray-600 px-1">{stage.summary}</p>

      {/* K-DST 6영역 */}
      <div className="bg-white rounded-2xl border border-gray-100 p-4 space-y-3">
        <div className="flex items-center gap-2">
          <Sparkles className="w-4 h-4 text-indigo-500" />
          <h3 className="text-sm font-semibold text-gray-800">발달 이정표 (K-DST 6영역)</h3>
        </div>
        <div className="grid grid-cols-1 gap-2">
          {K_DST.map(({ key, label, icon: Icon, color }) => {
            const items = stage[key] as string[];
            if (!items.length) return null;
            return (
              <div key={key} className="bg-gray-50 rounded-xl p-3">
                <div className={cn("flex items-center gap-1.5 mb-1.5", color)}>
                  <Icon className="w-4 h-4" />
                  <span className="text-xs font-semibold">{label}</span>
                </div>
                <ul className="text-xs text-gray-700 space-y-0.5 ml-5 list-disc">
                  {items.map((it, i) => <li key={i}>{it}</li>)}
                </ul>
              </div>
            );
          })}
        </div>
      </div>

      {/* 수유 / 수면 / 놀이 요약 */}
      <div className="bg-white rounded-2xl border border-gray-100 p-4 space-y-2.5">
        <div className="flex items-start gap-2 text-sm">
          <Milk className="w-4 h-4 text-blue-500 flex-shrink-0 mt-0.5" />
          <div>
            <span className="font-medium text-gray-700">수유 </span>
            <span className="text-gray-600">{stage.feedingSummary}</span>
          </div>
        </div>
        <div className="flex items-start gap-2 text-sm">
          <Moon className="w-4 h-4 text-purple-500 flex-shrink-0 mt-0.5" />
          <div>
            <span className="font-medium text-gray-700">수면 </span>
            <span className="text-gray-600">{stage.sleepSummary}</span>
          </div>
        </div>
        <div className="flex items-start gap-2 text-sm">
          <Gamepad2 className="w-4 h-4 text-green-500 flex-shrink-0 mt-0.5" />
          <div>
            <span className="font-medium text-gray-700">터미타임 </span>
            <span className="text-gray-600">{stage.playSummary}</span>
          </div>
        </div>
      </div>

      {/* 부모 행동 가이드 */}
      {!isPreview && stage.parentActions.length > 0 && (
        <div className="space-y-2">
          <h3 className="text-sm font-semibold text-gray-800 px-1 flex items-center gap-1.5">
            💪 이 시기 부모가 해줘야 할 것
          </h3>
          {stage.parentActions.map((a, i) => {
            const style = PRIORITY_STYLE[a.priority];
            return (
              <div
                key={i}
                className={cn("rounded-xl border-2 p-3", style.bg, style.border)}
              >
                <div className="flex items-start gap-2">
                  <div className="text-2xl flex-shrink-0">{a.icon}</div>
                  <div className="flex-1 min-w-0">
                    <div className="flex items-center gap-2 flex-wrap">
                      <h4 className="text-sm font-semibold text-gray-900">{a.title}</h4>
                      <span className={cn("text-[10px] px-1.5 py-0.5 rounded-full", style.badge)}>
                        {style.label}
                      </span>
                    </div>
                    <p className="text-xs text-gray-700 mt-1 leading-relaxed">{a.detail}</p>
                    <p className="text-[10px] text-gray-500 mt-1.5">
                      <BookOpen className="w-2.5 h-2.5 inline -mt-0.5 mr-0.5" />
                      {a.source}
                    </p>
                  </div>
                </div>
              </div>
            );
          })}
        </div>
      )}

      {/* 위험 신호 */}
      {!isPreview && stage.warningSigns.length > 0 && (
        <div className="bg-red-50 border-2 border-red-200 rounded-2xl p-4 space-y-2">
          <div className="flex items-center gap-2 text-red-700">
            <AlertTriangle className="w-4 h-4" />
            <h3 className="text-sm font-semibold">이런 게 보이면 즉시 소아과 상담</h3>
          </div>
          <ul className="text-xs text-red-800 space-y-1 ml-5 list-disc">
            {stage.warningSigns.map((w, i) => <li key={i}>{w}</li>)}
          </ul>
        </div>
      )}

      {/* 출처 */}
      <div className="bg-gray-50 rounded-xl p-3">
        <p className="text-[10px] text-gray-400 uppercase font-semibold mb-1">출처</p>
        <ul className="text-[11px] text-gray-600 space-y-0.5">
          {stage.sources.map((s, i) => (
            <li key={i}>• {s}</li>
          ))}
        </ul>
      </div>
    </div>
  );
}
