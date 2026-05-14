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
  const d = typeof birthDate === "string" ? new Date(birthDate) : birthDate;
  return differenceInDays(new Date(), d) + 1;
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
