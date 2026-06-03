export interface Prediction {
  lastFeedingAt?: string;
  nextFeedingAt?: string;
  feedingIntervalMinutes?: number;
  feedingBasedOn: number;
  lastSleepEndedAt?: string;
  nextSleepAt?: string;
  awakeWindowMinutes?: number;
  sleepBasedOn: number;
}

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
