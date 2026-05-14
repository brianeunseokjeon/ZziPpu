export interface SleepRecord {
  id: string;
  babyId: string;
  startedAt: string;
  endedAt?: string;
  durationMinutes?: number;
  memo?: string;
  createdAt: string;
}

export interface CreateSleepRequest {
  babyId: string;
  startedAt: string;
  endedAt?: string;
  memo?: string;
}

export interface StartSleepRequest {
  babyId: string;
  startedAt: string;
}
