export interface GrowthRecord {
  id: string;
  babyId: string;
  recordedAt: string;
  weightG: number | null;
  heightCm: number | null;
  headCircumferenceCm: number | null;
  memo: string | null;
  createdAt: string;
}

export interface CreateGrowthRequest {
  recordedAt: string;
  weightG?: number | null;
  heightCm?: number | null;
  headCircumferenceCm?: number | null;
  memo?: string | null;
}
