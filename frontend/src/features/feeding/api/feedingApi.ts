import {
  useQuery,
  useMutation,
  useQueryClient,
} from "@tanstack/react-query";
import { apiClient } from "@/lib/api-client";
import type { Feeding, CreateFeedingRequest } from "../types/feeding";

const feedingKeys = {
  all: ["feedings"] as const,
  list: (babyId: string, date: string) =>
    ["feedings", babyId, date] as const,
};

export function useFeedings(babyId: string, date: string) {
  return useQuery({
    queryKey: feedingKeys.list(babyId, date),
    queryFn: () =>
      apiClient.get<Feeding[]>(`/api/v1/babies/${babyId}/feedings?date=${date}`),
    enabled: !!babyId,
  });
}

export function useCreateFeeding() {
  const qc = useQueryClient();
  return useMutation({
    mutationFn: (data: CreateFeedingRequest) =>
      apiClient.post<Feeding>(`/api/v1/babies/${data.babyId}/feedings`, data),
    onMutate: async (newFeeding) => {
      const date = newFeeding.startedAt.slice(0, 10);
      const key = feedingKeys.list(newFeeding.babyId, date);
      await qc.cancelQueries({ queryKey: key });
      const prev = qc.getQueryData<Feeding[]>(key);
      if (prev) {
        qc.setQueryData<Feeding[]>(key, [
          { ...newFeeding, id: `temp-${Date.now()}`, createdAt: new Date().toISOString() },
          ...prev,
        ]);
      }
      return { prev, key };
    },
    onError: (_err, _vars, ctx) => {
      if (ctx?.prev !== undefined) {
        qc.setQueryData(ctx.key, ctx.prev);
      }
    },
    onSettled: (_data, _err, vars) => {
      const date = vars.startedAt.slice(0, 10);
      qc.invalidateQueries({ queryKey: feedingKeys.list(vars.babyId, date) });
      qc.invalidateQueries({ queryKey: ["daily-summary"] });
    },
  });
}

export function useDeleteFeeding() {
  const qc = useQueryClient();
  return useMutation({
    mutationFn: ({ babyId, feedingId }: { babyId: string; feedingId: string }) =>
      apiClient.delete<void>(`/api/v1/babies/${babyId}/feedings/${feedingId}`),
    onSettled: () => {
      qc.invalidateQueries({ queryKey: feedingKeys.all });
      qc.invalidateQueries({ queryKey: ["daily-summary"] });
    },
  });
}
