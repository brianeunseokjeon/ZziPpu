"use client";

/**
 * TimelineScrollView — 채팅형 기록 타임라인.
 *
 * - 오늘이 맨 아래, 위로 스크롤하면 과거 날짜 로드
 * - 마운트 시 자동으로 하단(오늘)으로 스크롤
 * - 상단 도달 시 이전 날짜 자동 prepend + 스크롤 위치 복원
 * - 상단 고정 날짜 레이블 (현재 보고 있는 날짜 표시)
 */

import { useState, useEffect, useRef, useLayoutEffect, useCallback } from "react";
import { useUIStore } from "@/shared/stores/uiStore";
import { getDateString } from "@/lib/date-utils";
import { DayTimeline } from "./DayTimeline";
import { ChevronDown } from "lucide-react";

const MAX_DAYS = 60;

function getDateNDaysAgo(n: number): string {
  // UTC+9 고정 오프셋으로 KST 날짜 계산 (SSR/CSR 모두 동일)
  const kst = new Date(Date.now() + 9 * 60 * 60 * 1000);
  return getDateString(new Date(Date.UTC(kst.getUTCFullYear(), kst.getUTCMonth(), kst.getUTCDate() - n)));
}

function formatRelativeDate(dateStr: string): string {
  const today = getDateNDaysAgo(0);
  const yesterday = getDateNDaysAgo(1);
  const dayBefore = getDateNDaysAgo(2);
  if (dateStr === today) return "오늘";
  if (dateStr === yesterday) return "어제";
  if (dateStr === dayBefore) return "그제";
  const dt = new Date(dateStr + "T00:00:00");
  const dow = ["일", "월", "화", "수", "목", "금", "토"][dt.getDay()];
  const [, m, d] = dateStr.split("-");
  return `${Number(m)}월 ${Number(d)}일 (${dow})`;
}

export function TimelineScrollView() {
  const { activeBabyId } = useUIStore();

  // dates: 오래된 순 (index 0 = 가장 오래됨, 마지막 = 오늘)
  // 초기 6 → 최근 7일(오늘 포함) 로드. 위로 스크롤 시 더 과거 자동 로드.
  const [oldestOffset, setOldestOffset] = useState(6);
  const totalDays = oldestOffset + 1; // 6=최근7일, 7=최근8일, ...

  // 스크롤 컨테이너 ref
  const containerRef = useRef<HTMLDivElement>(null);
  // 컨텐츠 래퍼 ref (높이 변화 감지용)
  const innerRef = useRef<HTMLDivElement>(null);
  // 상단 sentinel ref
  const topSentinelRef = useRef<HTMLDivElement>(null);
  // 각 날짜 섹션 ref (날짜 레이블 추적용)
  const sectionRefs = useRef<Map<string, HTMLDivElement>>(new Map());
  // 맨 아래(오늘) 고정 여부 — 사용자가 위로 스크롤하기 전까지 true.
  // 데이터가 비동기로 채워지며 높이가 변해도 오늘에 머물게 한다.
  const pinnedToBottomRef = useRef(true);

  // 플로팅 날짜 레이블
  const [floatingDate, setFloatingDate] = useState(getDateNDaysAgo(0));
  // 오늘로 이동 버튼 표시 여부
  const [showScrollToToday, setShowScrollToToday] = useState(false);

  // prepend 후 스크롤 위치 복원을 위한 이전 scrollHeight 저장
  const prevScrollHeightRef = useRef<number | null>(null);
  const isLoadingOlder = useRef(false);

  /* ─── 마운트 시 + 컨텐츠 높이 변화 시 하단(오늘) 고정 ─── */
  // 7일치 DayTimeline 이 비동기로 로드되며 높이가 계속 늘어난다.
  // pinnedToBottom 인 동안에는 높이가 바뀔 때마다 다시 맨 아래로 붙여
  // "항상 오늘이 보이도록" 한다. 사용자가 위로 스크롤하면 고정 해제.
  useEffect(() => {
    const el = containerRef.current;
    const inner = innerRef.current;
    if (!el || !inner) return;

    const pin = () => {
      if (pinnedToBottomRef.current) el.scrollTop = el.scrollHeight;
    };
    pin();
    // ① 컨텐츠 높이 변화(데이터 로드)마다 즉시 재고정
    const ro = new ResizeObserver(() => pin());
    ro.observe(inner);
    // ② 백업: 초기 2초간 주기적으로 최하단 유지 (ResizeObserver 가 놓치는 느린 로딩 커버)
    const interval = setInterval(pin, 150);
    const stop = setTimeout(() => clearInterval(interval), 2000);
    return () => {
      ro.disconnect();
      clearInterval(interval);
      clearTimeout(stop);
    };
  }, []);

  /* ─── prepend 후 스크롤 위치 복원 ─── */
  useLayoutEffect(() => {
    const el = containerRef.current;
    if (!el || prevScrollHeightRef.current === null) return;
    const added = el.scrollHeight - prevScrollHeightRef.current;
    if (added > 0) {
      el.scrollTop += added;
    }
    prevScrollHeightRef.current = null;
  });

  /* ─── 상단 sentinel IntersectionObserver → 이전 날짜 로드 ─── */
  const loadOlder = useCallback(() => {
    if (isLoadingOlder.current) return;
    if (totalDays >= MAX_DAYS) return;
    const el = containerRef.current;
    if (!el) return;
    isLoadingOlder.current = true;
    prevScrollHeightRef.current = el.scrollHeight;
    setOldestOffset((prev) => prev + 1);
    // 로딩 쿨다운
    setTimeout(() => { isLoadingOlder.current = false; }, 400);
  }, [totalDays]);

  useEffect(() => {
    const sentinel = topSentinelRef.current;
    const container = containerRef.current;
    if (!sentinel || !container) return;

    const observer = new IntersectionObserver(
      (entries) => {
        if (entries[0]?.isIntersecting) loadOlder();
      },
      { root: container, rootMargin: "100px 0px 0px 0px", threshold: 0 }
    );
    observer.observe(sentinel);
    return () => observer.disconnect();
  }, [loadOlder]);

  /* ─── 스크롤 이벤트: 플로팅 날짜 + "오늘로" 버튼 ─── */
  const onScroll = useCallback(() => {
    const el = containerRef.current;
    if (!el) return;

    // 오늘로 이동 버튼: 하단에서 200px 이상 위에 있을 때
    const distFromBottom = el.scrollHeight - el.scrollTop - el.clientHeight;
    setShowScrollToToday(distFromBottom > 200);

    // 사용자가 위로 올리면 하단 고정 해제, 다시 바닥 근처면 재고정
    if (distFromBottom > 150) pinnedToBottomRef.current = false;
    else if (distFromBottom < 10) pinnedToBottomRef.current = true;

    // 현재 보고 있는 날짜 계산 (스크롤 위치 기반)
    const scrollTop = el.scrollTop;
    let currentDate = getDateNDaysAgo(0); // 기본: 오늘
    for (const [date, sectionEl] of sectionRefs.current.entries()) {
      if (sectionEl.offsetTop <= scrollTop + 60) {
        currentDate = date;
      }
    }
    setFloatingDate(currentDate);
  }, []);

  const scrollToToday = useCallback(() => {
    pinnedToBottomRef.current = true;
    containerRef.current?.scrollTo({ top: containerRef.current.scrollHeight, behavior: "smooth" });
  }, []);

  if (!activeBabyId) return null;

  // dates 배열: 오래된 것부터 (index 0) → 오늘 (마지막)
  const dates = Array.from({ length: totalDays }, (_, i) =>
    getDateNDaysAgo(totalDays - 1 - i)
  );

  return (
    <div className="relative flex-1 min-h-0 flex flex-col overflow-hidden w-full">
      {/* ── 플로팅 날짜 레이블 (스크롤 중 현재 날짜 표시) ── */}
      <div className="flex-shrink-0 flex items-center justify-between px-4 py-2 bg-gray-50 border-b border-gray-100">
        <span className="text-xs font-bold text-gray-700">
          📅 {formatRelativeDate(floatingDate)}
          {floatingDate !== getDateNDaysAgo(0) && (
            <span className="ml-1.5 text-gray-400 font-normal">{floatingDate}</span>
          )}
        </span>
        {showScrollToToday && (
          <button
            onClick={scrollToToday}
            className="flex items-center gap-1 text-[11px] text-blue-500 font-medium active:opacity-70"
          >
            오늘로 <ChevronDown className="w-3 h-3" />
          </button>
        )}
      </div>

      {/* ── 스크롤 컨테이너 ── */}
      <div
        ref={containerRef}
        onScroll={onScroll}
        className="flex-1 overflow-y-auto overscroll-contain scroll-container"
      >
       <div ref={innerRef}>
        {/* 상단 sentinel — IntersectionObserver가 감지하면 이전 날짜 로드 */}
        <div ref={topSentinelRef} className="h-px" />

        {/* 최대일 도달 시 안내 */}
        {totalDays >= MAX_DAYS && (
          <div className="text-center py-3 text-xs text-gray-400">
            최대 {MAX_DAYS}일 전까지 표시됩니다
          </div>
        )}

        {/* 날짜별 섹션 — 오래된 것부터 */}
        {dates.map((date) => {
          const isToday = date === getDateNDaysAgo(0);
          return (
            <div
              key={date}
              ref={(el) => {
                if (el) sectionRefs.current.set(date, el);
                else sectionRefs.current.delete(date);
              }}
            >
              {/* 날짜 구분선 (sticky — 스크롤 컨테이너 기준) */}
              <div className="sticky top-0 z-10 bg-white/95 backdrop-blur-sm border-y border-gray-100 px-4 py-1.5 flex items-center gap-2">
                <span
                  className={`text-xs font-bold ${
                    isToday ? "text-blue-600" : "text-gray-600"
                  }`}
                >
                  {formatRelativeDate(date)}
                </span>
                {!isToday && (
                  <span className="text-[10px] text-gray-400">{date}</span>
                )}
                {isToday && (
                  <span className="text-[10px] bg-blue-100 text-blue-600 rounded-full px-1.5 py-0.5 font-medium">
                    오늘
                  </span>
                )}
              </div>

              {/* 해당 날짜 기록 */}
              <div className="bg-white">
                <DayTimeline babyId={activeBabyId} date={date} />
              </div>
            </div>
          );
        })}

        {/* 스크롤 하단 여백 */}
        <div className="h-4" />
       </div>
      </div>
    </div>
  );
}
