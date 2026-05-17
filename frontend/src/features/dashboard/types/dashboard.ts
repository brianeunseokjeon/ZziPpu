export interface DailySummary {
  totalFeedingMl: number;
  feedingCount: number;
  totalSleepMinutes: number;
  sleepCount: number;
  diaperCount: number;
  poopCount: number;
  peeCount: number;
  totalPlayMinutes: number;
  tummyTimeMinutes: number;
  lastFeedingAt?: string;
  lastDiaperAt?: string;
  lastSleepAt?: string;
}
