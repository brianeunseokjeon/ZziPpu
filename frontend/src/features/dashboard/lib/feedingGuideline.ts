/**
 * 체중 기반 1일 분유 권장량 가이드 (소아과 일반 기준).
 *
 * 출처(Source):
 * - AAP(미국소아과학회) / HealthyChildren.org
 *   "Amount and Schedule of Baby Formula Feedings"
 *   https://www.healthychildren.org/English/ages-stages/baby/formula-feeding/Pages/Amount-and-Schedule-of-Formula-Feedings.aspx
 *
 * 근거(AAP 일반 가이드):
 * - 체중 1파운드당 약 2.5oz/일 (≈ 체중 1kg당 약 165ml/일, 임상 범위 150~180ml/일)
 * - 1일 총량 상한(cap) 약 32oz (~960ml) — 체중 6kg 초과 영아도 적용
 * - 모유·혼합수유 여부, 개별 식욕에 따라 ±20% 차이는 정상
 *
 * ⚠️ 의학적 진단이 아니라 참고용 가이드. 분유(formula) 측정량 기준이며
 * 모유수유는 양 측정이 어려워 별도 안내가 필요하다.
 */

export const AAP_DAILY_CAP_ML = 960;
export const ML_PER_KG_MIN = 150;
export const ML_PER_KG_MAX = 180;
/** 정상으로 간주하는 허용 오차 (±20%) */
export const NORMAL_TOLERANCE = 0.2;

export type FeedingStatus = "no_weight" | "low" | "ok" | "high";

export interface FeedingGuideline {
  hasWeight: boolean;
  weightKg: number | null;
  /** 권장 하한 (체중×150, cap 적용) */
  recommendedMin: number;
  /** 권장 상한 (체중×180, cap 적용) */
  recommendedMax: number;
  /** AAP 960ml cap 이 적용되었는지 */
  capped: boolean;
  actualMl: number;
  status: FeedingStatus;
  /** 게이지 표시용 (0~1+, 권장 상한 대비 실제 비율) */
  ratio: number;
}

export function calcFeedingGuideline(
  weightG: number | null | undefined,
  actualMl: number
): FeedingGuideline {
  if (!weightG || weightG <= 0) {
    return {
      hasWeight: false,
      weightKg: null,
      recommendedMin: 0,
      recommendedMax: 0,
      capped: false,
      actualMl,
      status: "no_weight",
      ratio: 0,
    };
  }

  const weightKg = weightG / 1000;
  const rawMin = weightKg * ML_PER_KG_MIN;
  const rawMax = weightKg * ML_PER_KG_MAX;
  const recommendedMin = Math.round(Math.min(rawMin, AAP_DAILY_CAP_ML));
  const recommendedMax = Math.round(Math.min(rawMax, AAP_DAILY_CAP_ML));
  const capped = rawMax > AAP_DAILY_CAP_ML;

  let status: FeedingStatus;
  if (actualMl < recommendedMin * (1 - NORMAL_TOLERANCE)) status = "low";
  else if (actualMl > recommendedMax * (1 + NORMAL_TOLERANCE)) status = "high";
  else status = "ok";

  const ratio = recommendedMax > 0 ? actualMl / recommendedMax : 0;

  return {
    hasWeight: true,
    weightKg,
    recommendedMin,
    recommendedMax,
    capped,
    actualMl,
    status,
    ratio,
  };
}

export const STATUS_META: Record<
  FeedingStatus,
  { label: string; tone: string; bar: string; text: string }
> = {
  no_weight: { label: "체중 필요", tone: "bg-gray-100 text-gray-500", bar: "bg-gray-300", text: "text-gray-500" },
  low: { label: "권장보다 적음", tone: "bg-amber-100 text-amber-700", bar: "bg-amber-400", text: "text-amber-600" },
  ok: { label: "적정", tone: "bg-emerald-100 text-emerald-700", bar: "bg-emerald-400", text: "text-emerald-600" },
  high: { label: "권장보다 많음", tone: "bg-rose-100 text-rose-700", bar: "bg-rose-400", text: "text-rose-600" },
};
