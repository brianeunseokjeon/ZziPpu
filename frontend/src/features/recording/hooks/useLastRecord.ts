/**
 * 최근 수유 / 배변 기록을 조회하는 훅.
 *
 * 오늘 기록 + 어제 기록을 모두 조회하고, 가장 최신 항목을 반환.
 * QuickRepeatRow 에서 "또 100ml" 버튼 표시 여부 및 값 결정에 사용.
 */
import { useMemo } from "react";
import { useFeedings } from "@/features/feeding/api/feedingApi";
import { useDiapers } from "@/features/diaper/api/diaperApi";
import type { Feeding } from "@/features/feeding/types/feeding";
import type { DiaperRecord } from "@/features/diaper/types/diaper";
import { DiaperType } from "@/features/diaper/types/diaper";
import { getDateString } from "@/lib/date-utils";

function yesterdayString(): string {
  const d = new Date();
  d.setDate(d.getDate() - 1);
  return getDateString(d);
}

function latestByDate<T extends { startedAt?: string; recordedAt?: string }>(
  arr: T[]
): T | null {
  if (!arr.length) return null;
  return arr.reduce((prev, cur) => {
    const prevTime = new Date(prev.startedAt ?? prev.recordedAt ?? 0).getTime();
    const curTime = new Date(cur.startedAt ?? cur.recordedAt ?? 0).getTime();
    return curTime > prevTime ? cur : prev;
  });
}

interface LastRecords {
  lastFeeding: Feeding | null;
  lastPee: DiaperRecord | null;
  lastPoo: DiaperRecord | null;
}

export function useLastRecord(babyId: string): LastRecords {
  const today = getDateString(new Date());
  const yesterday = yesterdayString();

  const { data: feedingsToday } = useFeedings(babyId, today);
  const { data: feedingsYesterday } = useFeedings(babyId, yesterday);
  const { data: diapersToday } = useDiapers(babyId, today);
  const { data: diapersYesterday } = useDiapers(babyId, yesterday);

  return useMemo(() => {
    const allFeedings: Feeding[] = [
      ...(feedingsToday ?? []),
      ...(feedingsYesterday ?? []),
    ];
    const allDiapers: DiaperRecord[] = [
      ...(diapersToday ?? []),
      ...(diapersYesterday ?? []),
    ];

    const lastFeeding = latestByDate(allFeedings);
    const peeRecords = allDiapers.filter(
      (d) => d.diaperType === DiaperType.Pee || d.diaperType === DiaperType.Both
    );
    const pooRecords = allDiapers.filter(
      (d) => d.diaperType === DiaperType.Poop || d.diaperType === DiaperType.Both
    );

    return {
      lastFeeding: lastFeeding ?? null,
      lastPee: latestByDate(peeRecords) ?? null,
      lastPoo: latestByDate(pooRecords) ?? null,
    };
  }, [feedingsToday, feedingsYesterday, diapersToday, diapersYesterday]);
}
