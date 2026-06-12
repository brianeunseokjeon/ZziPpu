/**
 * 연령별 권장 수면 시간 및 터미타임 가이드라인
 *
 * 출처(Sources):
 * - NSF (National Sleep Foundation)
 *   Hirshkowitz M et al. "National Sleep Foundation's sleep time duration
 *   recommendations: methodology and results summary." Sleep Health 2015.
 * - AAP (American Academy of Pediatrics) / AASM 2016 consensus
 *   Paruthi S et al. "Recommended Amount of Sleep for Pediatric Populations."
 *   J Clin Sleep Med. 2016;12(6):785-786.
 * - AAP "Back to Sleep, Tummy to Play"
 *   https://www.healthychildren.org/English/ages-stages/baby/sleep/Pages/Back-to-Sleep-Tummy-to-Play.aspx
 * - WHO Guidelines on Physical Activity, Sedentary Behaviour and Sleep (2019)
 *   Table 1: Infants aged less than 1 year
 *
 * ⚠️ 참고용 가이드. 개인차 정상. 의학적 진단 아님.
 */

// ─── Sleep Guidelines ────────────────────────────────────────────────────────

/**
 * 수면 권장 범위 (시간/일, 낮잠 포함 총합)
 *  - 0~3개월(newborn): 14~17h (NSF 2015)
 *  - 4~11개월(infant): 12~16h (AASM 2016, 낮잠 포함)
 *  - 12~23개월(toddler): 11~14h (AASM 2016)
 */
export interface SleepGuideline {
  /** 권장 하한 (시간/일) */
  minH: number;
  /** 권장 상한 (시간/일) */
  maxH: number;
  /** 연령대 레이블 */
  label: string;
}

export function getSleepGuideline(ageMonths: number): SleepGuideline {
  if (ageMonths < 4) {
    return { minH: 14, maxH: 17, label: "신생아" };
  }
  if (ageMonths < 12) {
    return { minH: 12, maxH: 16, label: "영아" };
  }
  return { minH: 11, maxH: 14, label: "유아" };
}

// ─── Tummy Time Guidelines ───────────────────────────────────────────────────

/**
 * 터미타임 권장 범위 (분/일, 깨어있을 때 여러 번 나눠서 누적)
 *  - 0~2개월: 5~15분 시작 (짧게 자주, 점진적으로 늘림)
 *  - 2~4개월: 20~30분 목표
 *  - 4~6개월: 30~60분 목표
 *  - 6개월+:  60분 이상 (깨어있는 시간 바닥놀이 중심)
 */
export interface TummyGuideline {
  /** 권장 하한 (분/일) */
  minMin: number;
  /** 목표 (분/일) */
  targetMin: number;
  /** 연령대 레이블 */
  label: string;
}

export function getTummyGuideline(ageMonths: number): TummyGuideline {
  if (ageMonths < 2) {
    return { minMin: 5, targetMin: 15, label: "0~2개월" };
  }
  if (ageMonths < 4) {
    return { minMin: 20, targetMin: 30, label: "2~4개월" };
  }
  if (ageMonths < 6) {
    return { minMin: 30, targetMin: 60, label: "4~6개월" };
  }
  return { minMin: 60, targetMin: 90, label: "6개월 이상" };
}
