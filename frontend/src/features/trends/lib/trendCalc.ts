import type { SleepGuideline, TummyGuideline } from "./guidelines";
import type { FeedingGuideline } from "@/features/dashboard/lib/feedingGuideline";

// ─── Core Calculation ─────────────────────────────────────────────────────────

export type TrendDirection = "up" | "down" | "stable";

export interface TrendResult {
  direction: TrendDirection;
  /** "증가 추세" | "감소 추세" | "안정적" */
  directionLabel: string;
  /** 지난주 대비 %. 지난주 데이터 없거나 lastWeekAvg===0이면 null */
  percentChange: number | null;
  thisWeekAvg: number;
  lastWeekAvg: number | null;
  /** 이번 주 구간에서 non-null 유효 데이터 일수 */
  validDays: number;
}

/**
 * 최근 14일(또는 7일) 시계열 → 이번 주 vs 지난주 추세 계산.
 *
 * - values: 오래된→최신 순. 14일 모드면 length 14, 7일 모드면 length 7.
 * - windowDays: 이번 주 구간 크기. 기본 7.
 *   - values.slice(-windowDays) = 이번 주
 *   - values.slice(-windowDays*2, -windowDays) = 지난주 (없으면 비교 생략)
 * - null = 해당 날 데이터 없음 → 평균 계산 시 제외.
 * - 0은 유효값으로 포함.
 * - |percentChange| < 10% → "stable".
 */
export function calcTrend(
  values: (number | null)[],
  windowDays: 7 | 14 = 7
): TrendResult {
  const recent = values.slice(-windowDays);
  const prior = values.slice(-(windowDays * 2), -windowDays);

  const avg = (arr: (number | null)[]): number | null => {
    const valid = arr.filter((x): x is number => x !== null);
    if (valid.length === 0) return null;
    return valid.reduce((a, b) => a + b, 0) / valid.length;
  };

  const thisWeekAvg = avg(recent) ?? 0;
  const lastWeekAvg = avg(prior);
  const validDays = recent.filter((x) => x !== null).length;

  let percentChange: number | null = null;
  if (lastWeekAvg !== null && lastWeekAvg > 0) {
    percentChange = Math.round(
      ((thisWeekAvg - lastWeekAvg) / lastWeekAvg) * 100
    );
  }

  let direction: TrendDirection = "stable";
  if (percentChange !== null) {
    if (percentChange >= 10) direction = "up";
    else if (percentChange <= -10) direction = "down";
  }

  const directionLabel =
    direction === "up"
      ? "증가 추세"
      : direction === "down"
        ? "감소 추세"
        : "안정적";

  return {
    direction,
    directionLabel,
    percentChange,
    thisWeekAvg,
    lastWeekAvg,
    validDays,
  };
}

// ─── Insight Generators ───────────────────────────────────────────────────────

function formatDelta(trend: TrendResult): string {
  const { percentChange } = trend;
  if (percentChange === null) return "";
  if (percentChange > 0) return `지난주보다 ${Math.abs(percentChange)}% 늘었어요`;
  if (percentChange < 0) return `지난주보다 ${Math.abs(percentChange)}% 줄었어요`;
  return "지난주와 비슷해요";
}

/**
 * 수유량(ml/일) 인사이트.
 * guidelineResult가 있으면 AAP 권장 범위와 비교. 체중 없으면 안내.
 */
export function generateFeedingInsight(
  thisWeekAvg: number,
  trend: TrendResult,
  guidelineResult: FeedingGuideline | null,
  _ageMonths: number
): string {
  if (trend.validDays < 3) {
    return "기록이 더 쌓이면 수유 추세를 분석해 드릴게요. 꾸준히 기록해 주세요! 📊";
  }

  const avg = Math.round(thisWeekAvg);
  const delta = formatDelta(trend);
  const deltaPart = delta ? `. ${delta}` : "";

  if (!guidelineResult || !guidelineResult.hasWeight) {
    return `이번 주 하루 평균 수유량은 ${avg}ml예요${deltaPart}. 체중을 등록하면 AAP 권장 범위와 비교해 드릴게요 🍼`;
  }

  const { recommendedMin, recommendedMax, status } = guidelineResult;
  let cmp: string;
  if (status === "ok") {
    cmp = `AAP 권장(${recommendedMin}~${recommendedMax}ml) 범위 내예요 😊`;
  } else if (status === "low") {
    cmp = `AAP 권장(${recommendedMin}~${recommendedMax}ml)보다 적어요. 체중 변화도 함께 살펴보세요 ⚠️`;
  } else {
    cmp = `AAP 권장(${recommendedMin}~${recommendedMax}ml)보다 많아요. 소아과 상담을 권장드려요 ⚠️`;
  }

  return `이번 주 하루 평균 ${avg}ml 수유했어요${deltaPart}. ${cmp}`;
}

/**
 * 수면(시간/일) 인사이트.
 * thisWeekAvgHours: 분이 아닌 시간 단위로 받음.
 */
export function generateSleepInsight(
  thisWeekAvgHours: number,
  trend: TrendResult,
  guideline: SleepGuideline,
  ageMonths: number
): string {
  if (trend.validDays < 3) {
    return "기록이 더 쌓이면 수면 추세를 분석해 드릴게요. 꾸준히 기록해 주세요! 📊";
  }

  const h = thisWeekAvgHours.toFixed(1);
  const delta = formatDelta(trend);
  const deltaPart = delta ? `. ${delta}` : "";

  const within =
    thisWeekAvgHours >= guideline.minH && thisWeekAvgHours <= guideline.maxH;

  let cmp: string;
  if (within) {
    cmp = `생후 ${ageMonths}개월 연령 권장(${guideline.minH}~${guideline.maxH}시간) 범위 내예요 😴`;
  } else if (thisWeekAvgHours < guideline.minH) {
    cmp = `생후 ${ageMonths}개월 아기는 하루 ${guideline.minH}~${guideline.maxH}시간 수면이 권장돼요. 조금 더 재워볼까요? ⚠️`;
  } else {
    cmp = `권장(${guideline.minH}~${guideline.maxH}시간)보다 길어요. 보통은 괜찮지만, 이상이 있다면 소아과 상담을 권장드려요.`;
  }

  return `이번 주 하루 평균 ${h}시간 잤어요${deltaPart}. ${cmp}`;
}

/**
 * 배변(회/일) 인사이트.
 * 공식 AAP 권장선 없음 — 추세 위주, 급격한 변화 주의 안내.
 */
export function generateDiaperInsight(
  thisWeekAvg: number,
  trend: TrendResult,
  _ageMonths: number
): string {
  if (trend.validDays < 3) {
    return "기록이 더 쌓이면 배변 추세를 분석해 드릴게요. 꾸준히 기록해 주세요! 📊";
  }

  const c = thisWeekAvg.toFixed(1);
  const delta = formatDelta(trend);
  const deltaPart = delta ? `. ${delta}` : "";

  const { percentChange, direction } = trend;
  let advice = "갑작스러운 변화가 없는지 꾸준히 살펴보세요.";
  if (direction !== "stable" && percentChange !== null && Math.abs(percentChange) >= 30) {
    advice = "변화 폭이 크네요. 아기 상태를 살펴보고 이상이 있으면 소아과 상담을 권장드려요 ⚠️";
  }

  return `이번 주 하루 평균 기저귀 ${c}회 교체했어요${deltaPart}. ${advice}`;
}

/**
 * 터미타임(분/일) 인사이트.
 */
export function generateTummyInsight(
  thisWeekAvgMin: number,
  trend: TrendResult,
  guideline: TummyGuideline,
  _ageMonths: number
): string {
  if (trend.validDays < 3) {
    return "기록이 더 쌓이면 터미타임 추세를 분석해 드릴게요. 꾸준히 기록해 주세요! 📊";
  }

  if (thisWeekAvgMin === 0 && trend.validDays >= 3) {
    return `터미타임 기록이 없어요. ${guideline.label} 권장은 하루 ${guideline.targetMin}분이에요. 깨어있을 때 짧게라도 시작해보세요 💪`;
  }

  const m = Math.round(thisWeekAvgMin);
  const delta = formatDelta(trend);
  const deltaPart = delta ? `. ${delta}` : "";

  const cmp =
    m >= guideline.minMin
      ? `목표(${guideline.targetMin}분)에 잘 맞춰가고 있어요 💪`
      : `${guideline.label} 권장은 하루 ${guideline.targetMin}분이에요. 조금씩 늘려볼까요?`;

  return `이번 주 하루 평균 터미타임은 ${m}분이에요${deltaPart}. ${cmp}`;
}
