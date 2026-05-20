import { useQuery } from "@tanstack/react-query";
import { apiClient } from "@/lib/api-client";
import type {
  CurrentStageBundle,
  DevelopmentStage,
  Milestone,
} from "../types/development";

const keys = {
  stages: ["development", "stages"] as const,
  current: (ageDays: number) => ["development", "current", ageDays] as const,
  milestones: ["development", "milestones"] as const,
};

export function useStages() {
  return useQuery({
    queryKey: keys.stages,
    queryFn: () => apiClient.get<DevelopmentStage[]>("/api/v1/development/stages"),
    staleTime: 1000 * 60 * 60, // 1시간 (정적 데이터)
  });
}

export function useCurrentStage(ageDays: number) {
  return useQuery({
    queryKey: keys.current(ageDays),
    queryFn: () =>
      apiClient.get<CurrentStageBundle>(
        `/api/v1/development/stages/current?age_days=${ageDays}`
      ),
    enabled: ageDays >= 0,
    staleTime: 1000 * 60 * 60,
  });
}

export function useMilestones() {
  return useQuery({
    queryKey: keys.milestones,
    queryFn: () => apiClient.get<Milestone[]>("/api/v1/development/milestones"),
    staleTime: 1000 * 60 * 60 * 24, // 24시간
  });
}
