import {
  useQuery,
  useMutation,
  useQueryClient,
  keepPreviousData,
} from "@tanstack/react-query";
import { apiClient } from "@/lib/api-client";
import { getDateString } from "@/lib/date-utils";
import { optimisticDeleteOptions } from "@/shared/lib/optimisticDelete";
import { optimisticCreateOptions } from "@/shared/lib/optimisticCreate";
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
    refetchInterval: date === getDateString(new Date()) ? 30000 : false,
    placeholderData: keepPreviousData,
  });
}

export function useCreatePlay() {
  const qc = useQueryClient();
  return useMutation({
    mutationFn: (data: CreatePlayRequest) =>
      apiClient.post<PlayRecord>(`/api/v1/babies/${data.babyId}/plays`, data),
    ...optimisticCreateOptions<CreatePlayRequest, PlayRecord>({
      qc,
      listKeyForDate: (v) => playKeys.list(v.babyId, getDateString(v.startedAt)),
      buildOptimistic: (v, tempId) => ({
        id: tempId,
        babyId: v.babyId,
        playType: v.playType,
        durationMinutes: v.durationMinutes,
        startedAt: v.startedAt,
        endedAt: v.endedAt,
        memo: v.memo,
        createdAt: "",
      }),
      alsoInvalidate: [["daily-summary"]],
    }),
  });
}

export function useDeletePlay() {
  const qc = useQueryClient();
  return useMutation({
    mutationFn: ({ babyId, playId }: { babyId: string; playId: string }) =>
      apiClient.delete<void>(`/api/v1/babies/${babyId}/plays/${playId}`),
    ...optimisticDeleteOptions<{ babyId: string; playId: string }>({
      qc,
      listKey: playKeys.all,
      getId: (v) => v.playId,
      alsoInvalidate: [["daily-summary"]],
    }),
  });
}
