import { differenceInDays, isToday as fnsIsToday } from "date-fns";

/* ─── KST 기반 time input 헬퍼 ─────────────────────────────── */
// 한국(KST)은 DST 없음 → UTC+9 고정. Intl.DateTimeFormat locale 버그 없이
// UTC 밀리초에 +9h를 더해서 getUTC* 로 날짜/시각을 직접 읽는 방식 사용.

const KST = "Asia/Seoul";
const KST_OFFSET_MS = 9 * 60 * 60 * 1000;

function toKSTDate(date: Date): Date {
  return new Date(date.getTime() + KST_OFFSET_MS);
}

/** ISO → "HH:MM" (KST 기준) — <input type="time"> 값 */
export function isoToTimeInput(iso: string): string {
  const kst = toKSTDate(new Date(iso));
  const h = String(kst.getUTCHours()).padStart(2, "0");
  const m = String(kst.getUTCMinutes()).padStart(2, "0");
  return `${h}:${m}`;
}

/** 현재 KST 시각 "HH:MM" */
export function nowTimeInput(): string {
  return isoToTimeInput(new Date().toISOString());
}

/**
 * "HH:MM" (KST) + 기준 ISO의 KST 날짜 → 새 ISO (UTC)
 * (수정 시: 원래 기록 날짜는 유지하고 시간만 교체)
 */
export function applyTimeInput(originalISO: string, timeStr: string): string {
  const [h, m] = timeStr.split(":").map(Number);
  const kst = toKSTDate(new Date(originalISO));
  const year  = kst.getUTCFullYear();
  const month = kst.getUTCMonth();  // 0-indexed
  const day   = kst.getUTCDate();
  // KST HH:MM → UTC: subtract 9 hours
  return new Date(Date.UTC(year, month, day, h - 9, m)).toISOString();
}

/** "HH:MM" + 오늘 KST 날짜 → ISO (새 기록 저장용) */
export function todayTimeToISO(timeStr: string): string {
  return applyTimeInput(new Date().toISOString(), timeStr);
}

/** 현재 KST 시각 "YYYY-MM-DDTHH:MM" — <input type="datetime-local"> value/max 용 */
export function nowDatetimeLocal(): string {
  const kst = toKSTDate(new Date());
  const p = (n: number) => String(n).padStart(2, "0");
  return `${kst.getUTCFullYear()}-${p(kst.getUTCMonth() + 1)}-${p(kst.getUTCDate())}T${p(kst.getUTCHours())}:${p(kst.getUTCMinutes())}`;
}

/** datetime-local 값(KST 벽시계) → UTC ISO */
export function datetimeLocalToISO(value: string): string {
  const [d, t] = value.split("T");
  const [y, mo, da] = d.split("-").map(Number);
  const [h, mi] = t.split(":").map(Number);
  return new Date(Date.UTC(y, mo - 1, da, h - 9, mi)).toISOString();
}

/* ─── 표시용 포맷 ──────────────────────────────────────────── */

/** "오전 4:33" / "오후 2:05" 형식 (KST 강제) */
export function formatTime(date: Date | string): string {
  const d = typeof date === "string" ? new Date(date) : date;
  return new Intl.DateTimeFormat("ko-KR", {
    timeZone: KST,
    hour: "numeric",
    minute: "2-digit",
    hour12: true,
  }).format(d);
}

export function formatDate(date: Date | string): string {
  const d = typeof date === "string" ? new Date(date) : date;
  return new Intl.DateTimeFormat("ko-KR", {
    timeZone: KST,
    month: "long",
    day: "numeric",
    weekday: "short",
  }).format(d);
}

export function formatDuration(minutes: number): string {
  const h = Math.floor(minutes / 60);
  const m = minutes % 60;
  if (h === 0) return `${m}분`;
  if (m === 0) return `${h}시간`;
  return `${h}시간 ${m}분`;
}

export function getAgeDays(birthDate: Date | string): number {
  const birth = typeof birthDate === "string" ? new Date(birthDate) : birthDate;
  const birthLocal = new Date(birth.getFullYear(), birth.getMonth(), birth.getDate());
  const today = new Date();
  const todayLocal = new Date(today.getFullYear(), today.getMonth(), today.getDate());
  return differenceInDays(todayLocal, birthLocal) + 1;
}

export function getAgeText(birthDate: Date | string): string {
  return `생후 ${getAgeDays(birthDate)}일`;
}

export function isToday(date: Date | string): boolean {
  const d = typeof date === "string" ? new Date(date) : date;
  return fnsIsToday(d);
}

export function getDateString(date: Date | string): string {
  const d = typeof date === "string" ? new Date(date) : date;
  const kst = toKSTDate(d);
  const y  = kst.getUTCFullYear();
  const mo = String(kst.getUTCMonth() + 1).padStart(2, "0");
  const da = String(kst.getUTCDate()).padStart(2, "0");
  return `${y}-${mo}-${da}`;
}
