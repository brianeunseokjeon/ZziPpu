export interface Vaccination {
  id: string;
  babyId: string;
  vaccineName: string;
  doseNumber: number;
  scheduledDate: string;
  administeredDate: string | null;
  hospitalName: string | null;
  memo: string | null;
  isOverdue: boolean;
  daysUntil: number | null;
  createdAt: string;
}

export interface MarkAdministeredRequest {
  administeredDate: string;
  hospitalName?: string;
}
