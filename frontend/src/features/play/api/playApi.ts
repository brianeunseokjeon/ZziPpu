import {
  useQuery,
  useMutation,
  useQueryClient,
} from "@tanstack/react-query";
import { apiClient } from "@/lib/api-client";
import type { PlayRecord, CreatePlayRequest } from "../types/play";

const playKeys = {
  all: ["play"] as const,
  list: (babyId: string, date: string) => ["play", babyId, date] as const,
};

export function usePlayRecords(babyId: string, date: string) {
  return useQuery({
    queryKey: playKeys.list(babyId, date),
    queryFn: () =>
      apiClient.get<PlayRecord[]>(`/api/v1/babies/${babyId}/play?date=${date}`),
    enabled: !!babyId,
  });
}

export function useCreatePlay() {
  const qc = useQueryClient();
  return useMutation({
    mutationFn: (data: CreatePlayRequest) =>
      apiClient.post<PlayRecord>(`/api/v1/babies/${data.babyId}/play`, data),
    onSettled: (_data, _err, vars) => {
      const date = vars.startedAt.slice(0, 10);
      qc.invalidateQueries({ queryKey: playKeys.list(vars.babyId, date) });
      qc.invalidateQueries({ queryKey: ["daily-summary"] });
    },
  });
}

export function useDeletePlay() {
  const qc = useQueryClient();
  return useMutation({
    mutationFn: ({ babyId, playId }: { babyId: string; playId: string }) =>
      apiClient.delete<void>(`/api/v1/babies/${babyId}/play/${playId}`),
    onSettled: () => {
      qc.invalidateQueries({ queryKey: playKeys.all });
      qc.invalidateQueries({ queryKey: ["daily-summary"] });
    },
  });
}
