export interface GrowthRecord {
  id: string;
  baby_id: string;
  recorded_at: string;
  weight_g: number | null;
  height_cm: number | null;
  head_circumference_cm: number | null;
  memo: string | null;
  created_at: string;
}

export interface CreateGrowthRequest {
  recorded_at: string;
  weight_g?: number | null;
  height_cm?: number | null;
  head_circumference_cm?: number | null;
  memo?: string | null;
}
