import {
  useQuery,
  useMutation,
  useQueryClient,
} from "@tanstack/react-query";
import { apiClient } from "@/lib/api-client";
import { getDateString } from "@/lib/date-utils";
import type { PlayRecord, CreatePlayRequest } from "../types/play";

const playKeys = {
  all: ["play"] as const,
  list: (babyId: string, date: string) => ["play", babyId, date] as const,
};

export function usePlayRecords(babyId: string, date: string) {
  return useQuery({
    queryKey: playKeys.list(babyId, date),
    queryFn: () =>
      apiClient.get<PlayRecord[]>(`/api/v1/babies/${babyId}/plays?date=${date}`),
    enabled: !!babyId,
    refetchInterval: date === getDateString(new Date()) ? 15000 : false,
  });
}

export function useCreatePlay() {
  const qc = useQueryClient();
  return useMutation({
    mutationFn: (data: CreatePlayRequest) =>
      apiClient.post<PlayRecord>(`/api/v1/babies/${data.babyId}/plays`, data),
    onSettled: (_data, _err, vars) => {
      const date = getDateString(vars.startedAt);
      qc.invalidateQueries({ queryKey: playKeys.list(vars.babyId, date) });
      qc.invalidateQueries({ queryKey: ["daily-summary"] });
    },
  });
}

export function useDeletePlay() {
  const qc = useQueryClient();
  return useMutation({
    mutationFn: ({ babyId, playId }: { babyId: string; playId: string }) =>
      apiClient.delete<void>(`/api/v1/babies/${babyId}/plays/${playId}`),
    onSettled: () => {
      qc.invalidateQueries({ queryKey: playKeys.all });
      qc.invalidateQueries({ queryKey: ["daily-summary"] });
    },
  });
}
