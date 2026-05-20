/**
 * 한 날짜의 모든 활동 기록을 한 번에 조회하는 통합 훅.
 *
 * 4개 단일 날짜 API (`?date=YYYY-MM-DD`)를 TanStack Query 캐시 활용해 호출.
 * DayTimeline 컴포넌트가 24h 그리드 렌더링에 사용.
 */
import { useFeedings } from "@/features/feeding/api/feedingApi";
import { useDiapers } from "@/features/diaper/api/diaperApi";
import { useSleepRecords } from "@/features/sleep/api/sleepApi";
import { usePlayRecords } from "@/features/play/api/playApi";
import type { Feeding } from "@/features/feeding/types/feeding";
import type { DiaperRecord } from "@/features/diaper/types/diaper";
import type { SleepRecord } from "@/features/sleep/types/sleep";
import type { PlayRecord } from "@/features/play/types/play";

export interface DayRecords {
  feedings: Feeding[];
  diapers: DiaperRecord[];
  sleeps: SleepRecord[];
  plays: PlayRecord[];
  isLoading: boolean;
  isEmpty: boolean;
}

export function useDayRecords(babyId: string, date: string): DayRecords {
  const f = useFeedings(babyId, date);
  const d = useDiapers(babyId, date);
  const s = useSleepRecords(babyId, date);
  const p = usePlayRecords(babyId, date);

  const feedings = f.data ?? [];
  const diapers = d.data ?? [];
  const sleeps = s.data ?? [];
  const plays = p.data ?? [];

  return {
    feedings,
    diapers,
    sleeps,
    plays,
    isLoading: f.isLoading || d.isLoading || s.isLoading || p.isLoading,
    isEmpty:
      feedings.length === 0 &&
      diapers.length === 0 &&
      sleeps.length === 0 &&
      plays.length === 0,
  };
}
