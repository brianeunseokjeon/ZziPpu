import { useQuery } from "@tanstack/react-query";
import { apiClient } from "@/lib/api-client";
import type { DailySummary, Prediction } from "../types/dashboard";

export function useDailySummary(babyId: string, date: string) {
  return useQuery({
    queryKey: ["daily-summary", babyId, date],
    queryFn: () =>
      apiClient.get<DailySummary>(
        `/api/v1/babies/${babyId}/dashboard/daily?date=${date}`
      ),
    enabled: !!babyId,
  });
}

export function usePredictions(babyId: string) {
  return useQuery({
    queryKey: ["predictions", babyId],
    queryFn: () =>
      apiClient.get<Prediction>(
        `/api/v1/babies/${babyId}/dashboard/predictions`
      ),
    enabled: !!babyId,
    refetchInterval: 60_000,
  });
}
