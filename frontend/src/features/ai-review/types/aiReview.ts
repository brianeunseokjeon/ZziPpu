// api-client가 응답을 자동 camelize 하므로 모든 필드는 camelCase.
export interface DailyReview {
  babyId: string;
  reviewDate: string;
  feedingAnalysis: string;
  sleepAnalysis: string;
  diaperAnalysis: string;
  playAnalysis: string;
  overallAssessment: string;
  alerts: string[];
  recommendations: string[];
  positives: string[];
  considerations: string[];
  concerns: string[];
  criticalWarnings: string[];
}

export interface SavedInfo {
  id: string;
  babyId: string;
  title: string;
  content: string;
  category: "feeding" | "sleep" | "development" | "health" | "general";
  chatMessageId?: string;
  createdAt: string;
}
