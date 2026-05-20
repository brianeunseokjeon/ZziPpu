// api-client camelize 후의 형태 (백엔드 snake_case → camelCase 자동 변환)

export type Priority = "high" | "medium" | "low";

export interface ParentAction {
  icon: string;
  title: string;
  detail: string;
  source: string;
  priority: Priority;
}

export interface DevelopmentStage {
  ageRangeDays: [number, number];
  label: string;
  summary: string;
  grossMotor: string[];
  fineMotor: string[];
  cognition: string[];
  language: string[];
  social: string[];
  selfCare: string[];
  parentActions: ParentAction[];
  warningSigns: string[];
  feedingSummary: string;
  sleepSummary: string;
  playSummary: string;
  sources: string[];
}

export interface CurrentStageBundle {
  current: DevelopmentStage;
  previous: DevelopmentStage | null;
  next: DevelopmentStage | null;
  ageDays: number;
}

export type MilestoneCategory = "celebration" | "checkup" | "developmental";

export interface Milestone {
  days: number;
  label: string;
  emoji: string;
  category: MilestoneCategory;
  description: string;
}
