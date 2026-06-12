import { useQueries } from "@tanstack/react-query";
import { apiClient } from "@/lib/api-client";
import type { DailySummary } from "@/features/dashboard/types/dashboard";
import { getDateString } from "@/lib/date-utils";

export interface TrendDay {
  date: string;           // YYYY-MM-DD (KST)
  label: string;          // 요일 한글 — 차트 X축용 ("월", "화", ...)
  summary: DailySummary | null;
}

const WEEKDAY_KO = ["일", "월", "화", "수", "목", "금", "토"] as const;

/** 오늘 포함 과거 N일의 YYYY-MM-DD 배열 (오래된→최신 순, KST 기준) */
function lastNDates(n: number): string[] {
  const out: string[] = [];
  for (let i = n - 1; i >= 0; i--) {
    const d = new Date();
    d.setDate(d.getDate() - i);
    out.push(getDateString(d));
  }
  return out;
}

/**
 * 최근 N일의 DailySummary를 병렬로 조회한다.
 *
 * days: 조회할 날수 (보통 rangeDays * 2 — 이번 주 + 지난주 비교용).
 *
 * - 기존 `["daily-summary", babyId, date]` 키 재사용 → 오늘 탭과 캐시 공유.
 * - 과거 날짜는 immutable → staleTime 12h.
 * - 오늘 날짜는 staleTime 30s (수시 변경 가능).
 * - null summary = 데이터 없는 날 또는 로딩 실패.
 */
export function useTrendsData(babyId: string | undefined, days: 7 | 14) {
  const dates = lastNDates(days);
  const todayDate = dates[dates.length - 1];

  const results = useQueries({
    queries: dates.map((date) => ({
      queryKey: ["daily-summary", babyId, date] as const,
      queryFn: () =>
        apiClient.get<DailySummary>(
          `/api/v1/babies/${babyId}/dashboard/daily?date=${date}`
        ),
      enabled: !!babyId,
      staleTime: date === todayDate ? 30_000 : 1000 * 60 * 60 * 12,
      gcTime: 1000 * 60 * 60 * 24,
      retry: 1,
    })),
  });

  const data: TrendDay[] = dates.map((date, i) => {
    const r = results[i];
    // KST 자정 기준으로 요일 산출 (toISOString().slice(0,10) UTC 버그 방지)
    const dow = new Date(`${date}T00:00:00+09:00`).getDay();
    return {
      date,
      label: WEEKDAY_KO[dow],
      summary: r.isSuccess ? (r.data ?? null) : null,
    };
  });

  const isLoading = results.some((r) => r.isLoading);
  const isError = results.length > 0 && results.every((r) => r.isError);

  /** 실제 summary 데이터가 들어온 날 수 */
  const loadedCount = data.filter((d) => d.summary !== null).length;

  /** 모든 쿼리를 다시 시도 */
  function refetchAll() {
    results.forEach((r) => r.refetch());
  }

  return { data, isLoading, isError, loadedCount, refetchAll };
}
