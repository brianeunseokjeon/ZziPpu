import { useQuery } from "@tanstack/react-query";
import { apiClient } from "@/lib/api-client";
import type { DailySummary } from "../types/dashboard";

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
