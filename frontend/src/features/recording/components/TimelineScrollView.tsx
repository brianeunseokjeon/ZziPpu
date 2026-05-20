"use client";

/**
 * TimelineScrollView — 무한 스크롤 타임라인 컨테이너.
 *
 * 초기: 오늘 1일 표시. 사용자가 하단에 도달하면 어제, 그제, ... 로드.
 * 각 날짜 헤더는 sticky.
 * 최대 30일 cap → "더 이전 보기" 버튼.
 */

import { useState, useEffect, useRef, useCallback } from "react";
import { useUIStore } from "@/shared/stores/uiStore";
import { getDateString } from "@/lib/date-utils";
import { DayTimeline } from "./DayTimeline";

const MAX_AUTOLOAD_DAYS = 30;

function getDateStringNDaysAgo(n: number): string {
  const d = new Date();
  d.setDate(d.getDate() - n);
  return getDateString(d);
}

function formatRelativeDate(dateStr: string): string {
  const today = getDateString(new Date());
  const yesterday = getDateStringNDaysAgo(1);
  const dayBefore = getDateStringNDaysAgo(2);
  if (dateStr === today) return "오늘";
  if (dateStr === yesterday) return "어제";
  if (dateStr === dayBefore) return "그제";
  const [, m, d] = dateStr.split("-");
  const dt = new Date(dateStr);
  const dow = ["일", "월", "화", "수", "목", "금", "토"][dt.getDay()];
  return `${Number(m)}월 ${Number(d)}일 (${dow})`;
}

export function TimelineScrollView() {
  const { activeBabyId } = useUIStore();
  const [daysLoaded, setDaysLoaded] = useState(1);
  const sentinelRef = useRef<HTMLDivElement>(null);

  const loadMore = useCallback(() => {
    setDaysLoaded((n) => Math.min(MAX_AUTOLOAD_DAYS, n + 1));
  }, []);

  useEffect(() => {
    const el = sentinelRef.current;
    if (!el) return;
    if (daysLoaded >= MAX_AUTOLOAD_DAYS) return;

    const observer = new IntersectionObserver(
      (entries) => {
        if (entries[0]?.isIntersecting) loadMore();
      },
      { rootMargin: "200px" }
    );
    observer.observe(el);
    return () => observer.disconnect();
  }, [daysLoaded, loadMore]);

  if (!activeBabyId) return null;

  const dates = Array.from({ length: daysLoaded }, (_, i) => getDateStringNDaysAgo(i));

  return (
    <div className="space-y-3">
      {dates.map((date) => (
        <div key={date}>
          {/* sticky 날짜 헤더 */}
          <div
            className="sticky z-10 bg-white/95 backdrop-blur-sm border border-gray-100 rounded-2xl px-4 py-2 mb-2 shadow-sm"
            style={{ top: "calc(env(safe-area-inset-top) + 56px)" }}
          >
            <p className="text-sm font-bold text-gray-800">
              📅 {formatRelativeDate(date)}
              <span className="ml-2 text-xs font-normal text-gray-400">{date}</span>
            </p>
          </div>

          {/* 24h 그리드 */}
          <DayTimeline babyId={activeBabyId} date={date} />
        </div>
      ))}

      {/* 무한 스크롤 sentinel */}
      {daysLoaded < MAX_AUTOLOAD_DAYS && (
        <div ref={sentinelRef} className="py-4 text-center text-xs text-gray-400">
          이전 날짜 로드 중...
        </div>
      )}

      {/* cap 도달 시 "더 이전" 버튼 */}
      {daysLoaded >= MAX_AUTOLOAD_DAYS && (
        <button
          onClick={() => setDaysLoaded((n) => n + 7)}
          className="w-full py-3 bg-gray-50 text-gray-600 rounded-2xl text-sm font-medium hover:bg-gray-100"
        >
          이전 7일 더 보기
        </button>
      )}
    </div>
  );
}
