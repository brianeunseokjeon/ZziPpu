export interface DailySummary {
  date: string;
  babyId: string;
  totalFeedingMl: number;
  feedingCount: number;
  lastFeedingAt?: string;
  totalSleepMinutes: number;
  sleepCount: number;
  diaperCount: number;
  poopCount: number;
  peeCount: number;
  totalPlayMinutes: number;
  tummyTimeMinutes: number;
}
