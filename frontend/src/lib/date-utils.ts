import { format, differenceInDays, isToday as fnsIsToday } from "date-fns";
import { ko } from "date-fns/locale";

export function formatTime(date: Date | string): string {
  const d = typeof date === "string" ? new Date(date) : date;
  return format(d, "a h:mm", { locale: ko });
}

export function formatDate(date: Date | string): string {
  const d = typeof date === "string" ? new Date(date) : date;
  return format(d, "M월 d일 (E)", { locale: ko });
}

export function formatDuration(minutes: number): string {
  const h = Math.floor(minutes / 60);
  const m = minutes % 60;
  if (h === 0) return `${m}분`;
  if (m === 0) return `${h}시간`;
  return `${h}시간 ${m}분`;
}

export function getAgeDays(birthDate: Date | string): number {
  // 한국식: 생일 당일 = 생후 1일. TZ 무관하게 캘린더 날짜로만 비교.
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
  return format(d, "yyyy-MM-dd");
}
