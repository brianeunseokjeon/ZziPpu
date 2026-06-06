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
import type { DiaperRecord, CreateDiaperRequest } from "../types/diaper";

const diaperKeys = {
  all: ["diapers"] as const,
  list: (babyId: string, date: string) => ["diapers", babyId, date] as const,
};

export function useDiapers(babyId: string, date: string) {
  return useQuery({
    queryKey: diaperKeys.list(babyId, date),
    queryFn: () =>
      apiClient.get<DiaperRecord[]>(
        `/api/v1/babies/${babyId}/diapers?date=${date}`
      ),
    enabled: !!babyId,
    refetchInterval: date === getDateString(new Date()) ? 30000 : false,
    placeholderData: keepPreviousData,
  });
}

export function useCreateDiaper() {
  const qc = useQueryClient();
  return useMutation({
    mutationFn: (data: CreateDiaperRequest) =>
      apiClient.post<DiaperRecord>(`/api/v1/babies/${data.babyId}/diapers`, data),
    ...optimisticCreateOptions<CreateDiaperRequest, DiaperRecord>({
      qc,
      listKeyForDate: (v) => diaperKeys.list(v.babyId, getDateString(v.recordedAt)),
      buildOptimistic: (v, tempId) => ({
        id: tempId,
        babyId: v.babyId,
        diaperType: v.diaperType,
        stoolColor: v.stoolColor,
        stoolState: v.stoolState,
        recordedAt: v.recordedAt,
        memo: v.memo,
        createdAt: new Date().toISOString(),
      }),
      alsoInvalidate: [["daily-summary"]],
    }),
  });
}

export function useDeleteDiaper() {
  const qc = useQueryClient();
  return useMutation({
    mutationFn: ({ babyId, diaperId }: { babyId: string; diaperId: string }) =>
      apiClient.delete<void>(`/api/v1/babies/${babyId}/diapers/${diaperId}`),
    ...optimisticDeleteOptions<{ babyId: string; diaperId: string }>({
      qc,
      listKey: diaperKeys.all,
      getId: (v) => v.diaperId,
      alsoInvalidate: [["daily-summary"]],
    }),
  });
}
