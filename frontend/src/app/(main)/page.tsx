"use client";

/**
 * 홈 — 고정 상단 기록 버튼 + 채팅형 타임라인 스크롤.
 *
 * 전체 페이지 스크롤 없음.
 * 위: 빠른 기록 UI (flex-shrink-0)
 * 아래: 타임라인 (flex-1, 내부 스크롤, 오늘이 맨 아래)
 *
 * selectedDate가 오늘이 아니면(과거 날짜) → 해당 일자 포커스 뷰:
 * "지금" 중심 위젯은 숨기고, BigActionGrid(과거 기록 모드)와
 * 단일 일자 타임라인만 보여준다.
 */

import { ArrowLeft } from "lucide-react";
import { useUIStore } from "@/shared/stores/uiStore";
import { getDateString, formatDate } from "@/lib/date-utils";
import { BigActionGrid } from "@/features/recording/components/BigActionGrid";
import { TimelineScrollView } from "@/features/recording/components/TimelineScrollView";
import { DayTimeline } from "@/features/recording/components/DayTimeline";

export default function HomePage() {
  const { activeBabyId, selectedDate, setSelectedDate } = useUIStore();
  const isToday = selectedDate === getDateString(new Date());

  /* ── 과거 날짜 포커스 뷰 ── */
  if (!isToday) {
    return (
      <div className="flex-1 flex flex-col overflow-hidden min-h-0">
        <div className="flex-shrink-0 px-4 pt-3 pb-2 space-y-2.5 bg-gray-50 border-b border-gray-100">
          {/* 과거 날짜 헤더 + 오늘로 돌아가기 */}
          <div className="flex items-center justify-between">
            <span className="text-sm font-bold text-gray-700">
              📅 {formatDate(`${selectedDate}T12:00:00+09:00`)} 기록
            </span>
            <button
              onClick={() => setSelectedDate(getDateString(new Date()))}
              className="flex items-center gap-1 text-xs font-medium text-blue-500 active:opacity-70"
            >
              <ArrowLeft className="w-3.5 h-3.5" /> 오늘로
            </button>
          </div>
          <BigActionGrid />
        </div>

        {/* 선택한 일자만 표시 */}
        <div className="flex-1 min-h-0 overflow-y-auto overscroll-contain scroll-container bg-white">
          {activeBabyId && <DayTimeline babyId={activeBabyId} date={selectedDate} />}
          <div className="h-4" />
        </div>
      </div>
    );
  }

  /* ── 오늘(기본) 뷰 ── */
  return (
    <div className="flex-1 flex flex-col overflow-hidden min-h-0">
      {/* ── 고정 상단: 빠른 기록 버튼 (심플) ── */}
      <div className="flex-shrink-0 px-4 pt-3 pb-2 bg-gray-50 border-b border-gray-100">
        <BigActionGrid />
      </div>

      {/* ── 기록 타임라인 (채팅형 스크롤) ── */}
      <TimelineScrollView />
    </div>
  );
}
