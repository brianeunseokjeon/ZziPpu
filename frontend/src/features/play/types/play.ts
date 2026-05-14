export type PlayType = "tummy_time" | "free_play" | "sensory_play";

export interface PlayRecord {
  id: string;
  babyId: string;
  playType: PlayType;
  durationMinutes: number;
  startedAt: string;
  endedAt?: string;
  memo?: string;
  createdAt: string;
}

export interface CreatePlayRequest {
  babyId: string;
  playType: PlayType;
  durationMinutes: number;
  startedAt: string;
  endedAt?: string;
  memo?: string;
}
