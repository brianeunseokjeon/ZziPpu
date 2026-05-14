export interface DailyReview {
  baby_id: string;
  review_date: string;
  feeding_analysis: string;
  sleep_analysis: string;
  diaper_analysis: string;
  play_analysis: string;
  overall_assessment: string;
  alerts: string[];
  recommendations: string[];
}

export interface SavedInfo {
  id: string;
  baby_id: string;
  title: string;
  content: string;
  category: "feeding" | "sleep" | "development" | "health" | "general";
  chat_message_id?: string;
  created_at: string;
}
