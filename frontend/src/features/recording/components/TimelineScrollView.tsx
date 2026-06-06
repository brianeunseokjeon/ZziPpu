"use client";

/**
 * TimelineScrollView — 피드형 기록 타임라인.
 *
 * - 오늘이 맨 위, 아래로 스크롤하면 과거 날짜 로드
 * - 하단 도달 시 이전 날짜 자동 append
 */

import { useState, useEffect, useRef, useCallback } from "react";
import { useUIStore } from "@/shared/stores/uiStore";
import { getDateString } from "@/lib/date-utils";
import { DayTimeline } from "./DayTimeline";
import { ChevronUp } from "lucide-react";

const MAX_DAYS = 60;

function getDateNDaysAgo(n: number): string {
  const kst = new Date(Date.now() + 9 * 60 * 60 * 1000);
  return getDateString(new Date(Date.UTC(kst.getUTCFullYear(), kst.getUTCMonth(), kst.getUTCDate() - n)));
}

function formatSectionDate(dateStr: string): string {
  const today    = getDateNDaysAgo(0);
  const yesterday = getDateNDaysAgo(1);
  const dayBefore = getDateNDaysAgo(2);
  if (dateStr === today)     return "오늘";
  if (dateStr === yesterday) return "어제";
  if (dateStr === dayBefore) return "그제";
  const dt  = new Date(dateStr + "T00:00:00");
  const dow = ["일", "월", "화", "수", "목", "금", "토"][dt.getDay()];
  const [, m, d] = dateStr.split("-");
  return `${Number(m)}월 ${Number(d)}일 (${dow})`;
}

export function TimelineScrollView() {
  const { activeBabyId } = useUIStore();

  const [oldestOffset, setOldestOffset]         = useState(6);
  const totalDays = oldestOffset + 1;

  const containerRef      = useRef<HTMLDivElement>(null);
  const innerRef          = useRef<HTMLDivElement>(null);
  const bottomSentinelRef = useRef<HTMLDivElement>(null);
  const sectionRefs       = useRef<Map<string, HTMLDivElement>>(new Map());
  const isLoadingOlder    = useRef(false);

  // "오늘로" 플로팅 버튼 — 아래로 200px 이상 스크롤 시 표시
  const [showScrollToToday, setShowScrollToToday] = useState(false);

  /* ─── 하단 sentinel → 과거 날짜 append ─── */
  const loadOlder = useCallback(() => {
    if (isLoadingOlder.current || totalDays >= MAX_DAYS) return;
    isLoadingOlder.current = true;
    setOldestOffset((p) => p + 1);
    setTimeout(() => { isLoadingOlder.current = false; }, 400);
  }, [totalDays]);

  useEffect(() => {
    const sentinel  = bottomSentinelRef.current;
    const container = containerRef.current;
    if (!sentinel || !container) return;
    const observer = new IntersectionObserver(
      (entries) => { if (entries[0]?.isIntersecting) loadOlder(); },
      { root: container, rootMargin: "0px 0px 100px 0px", threshold: 0 }
    );
    observer.observe(sentinel);
    return () => observer.disconnect();
  }, [loadOlder]);

  /* ─── 스크롤: "오늘로" 버튼 표시 여부 ─── */
  const onScroll = useCallback(() => {
    const el = containerRef.current;
    if (!el) return;
    setShowScrollToToday(el.scrollTop > 200);
  }, []);

  const scrollToToday = useCallback(() => {
    containerRef.current?.scrollTo({ top: 0, behavior: "smooth" });
  }, []);

  if (!activeBabyId) return null;

  const dates = Array.from({ length: totalDays }, (_, i) => getDateNDaysAgo(i));

  return (
    <div className="relative flex-1 min-h-0 overflow-hidden w-full">
      {/* ── 스크롤 컨테이너 ── */}
      <div
        ref={containerRef}
        onScroll={onScroll}
        className="h-full overflow-y-auto overscroll-contain scroll-container"
      >
        <div ref={innerRef}>
          {dates.map((date) => {
            const isToday = date === getDateNDaysAgo(0);
            return (
              <div
                key={date}
                ref={(el) => {
                  if (el) sectionRefs.current.set(date, el);
                  else     sectionRefs.current.delete(date);
                }}
              >
                {/* 날짜 구분 헤더 */}
                <div className="sticky top-0 z-10 bg-white/95 backdrop-blur-sm border-b border-gray-100 px-4 py-2 flex items-center gap-2">
                  <span className={`text-xs font-semibold ${isToday ? "text-blue-500" : "text-gray-500"}`}>
                    {formatSectionDate(date)}
                  </span>
                  {!isToday && (
                    <span className="text-[10px] text-gray-400">{date}</span>
                  )}
                </div>

                <div className="bg-white">
                  <DayTimeline babyId={activeBabyId} date={date} />
                </div>
              </div>
            );
          })}

          {totalDays >= MAX_DAYS && (
            <div className="text-center py-3 text-xs text-gray-400">
              최대 {MAX_DAYS}일 전까지 표시됩니다
            </div>
          )}

          {totalDays < MAX_DAYS && <div ref={bottomSentinelRef} className="h-px" />}
          <div className="h-[calc(env(safe-area-inset-bottom)+1rem)]" />
        </div>
      </div>

      {/* ── 플로팅 "오늘로↑" 버튼 — 아래로 스크롤 시에만 표시 ── */}
      {showScrollToToday && (
        <button
          onClick={scrollToToday}
          className="absolute bottom-4 right-4 flex items-center gap-1.5 px-3 py-1.5 bg-white border border-gray-200 rounded-full shadow-md text-[11px] font-medium text-blue-500 active:opacity-70 z-20"
        >
          <ChevronUp className="w-3.5 h-3.5" />
          오늘로
        </button>
      )}
    </div>
  );
}
