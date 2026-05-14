export enum FeedingType {
  Formula = "formula",
  BreastLeft = "breast_left",
  BreastRight = "breast_right",
  BreastBoth = "breast_both",
}

export interface Feeding {
  id: string;
  babyId: string;
  type: FeedingType;
  amountMl?: number;
  durationMinutes?: number;
  startedAt: string;
  endedAt?: string;
  memo?: string;
  createdAt: string;
}

export interface CreateFeedingRequest {
  babyId: string;
  type: FeedingType;
  amountMl?: number;
  durationMinutes?: number;
  startedAt: string;
  endedAt?: string;
  memo?: string;
}
