/**
 * 마일스톤 / 생후 일수 양방향 계산.
 *
 * 한국식 (생일 당일 = 생후 1일)을 따른다. backend Baby.age_days와 일치.
 */

/** birthDate(YYYY-MM-DD or Date) + 생후 N일 → 해당 날짜 Date 객체 (로컬 자정). */
export function getDateForAgeDays(birthDate: Date | string, ageDays: number): Date {
  const birth = typeof birthDate === "string" ? new Date(birthDate) : birthDate;
  // 로컬 자정 기준
  const local = new Date(birth.getFullYear(), birth.getMonth(), birth.getDate());
  // 생후 1일 = birthDate 당일이므로 +(ageDays - 1)일
  local.setDate(local.getDate() + (ageDays - 1));
  return local;
}

/** birthDate + 임의 날짜 → 해당 날짜는 생후 며칠? */
export function getAgeDaysForDate(birthDate: Date | string, target: Date | string): number {
  const birth = typeof birthDate === "string" ? new Date(birthDate) : birthDate;
  const t = typeof target === "string" ? new Date(target) : target;
  const birthLocal = new Date(birth.getFullYear(), birth.getMonth(), birth.getDate());
  const targetLocal = new Date(t.getFullYear(), t.getMonth(), t.getDate());
  const diffMs = targetLocal.getTime() - birthLocal.getTime();
  // 음수일 수도 있음 (출생 전 날짜)
  return Math.floor(diffMs / (24 * 60 * 60 * 1000)) + 1;
}

/** 마일스톤(생후 N일) 권장일까지 D-day. 음수면 지난 마일스톤. */
export function daysUntilMilestone(birthDate: Date | string, milestoneDays: number): number {
  const today = new Date();
  const target = getDateForAgeDays(birthDate, milestoneDays);
  const todayLocal = new Date(today.getFullYear(), today.getMonth(), today.getDate());
  return Math.floor((target.getTime() - todayLocal.getTime()) / (24 * 60 * 60 * 1000));
}

/** "2026-05-20" 형식 */
export function formatYMD(d: Date): string {
  const y = d.getFullYear();
  const m = String(d.getMonth() + 1).padStart(2, "0");
  const day = String(d.getDate()).padStart(2, "0");
  return `${y}-${m}-${day}`;
}

/** "2026년 5월 20일 (수)" 형식 */
export function formatKoreanDate(d: Date): string {
  const days = ["일", "월", "화", "수", "목", "금", "토"];
  return `${d.getFullYear()}년 ${d.getMonth() + 1}월 ${d.getDate()}일 (${days[d.getDay()]})`;
}
