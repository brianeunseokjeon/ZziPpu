export interface Vaccination {
  id: string;
  baby_id: string;
  vaccine_name: string;
  dose_number: number;
  scheduled_date: string;
  administered_date: string | null;
  hospital_name: string | null;
  memo: string | null;
  is_overdue: boolean;
  days_until: number | null;
}

export interface MarkAdministeredRequest {
  administered_date: string;
  hospital_name?: string;
}
