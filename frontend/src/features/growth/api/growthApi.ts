import { useQuery, useMutation, useQueryClient } from "@tanstack/react-query";
import { apiClient } from "@/lib/api-client";
import { optimisticDeleteOptions } from "@/shared/lib/optimisticDelete";
import type { GrowthRecord, CreateGrowthRequest } from "../types/growth";

const growthKeys = {
  all: ["growth"] as const,
  list: (babyId: string) => ["growth", babyId] as const,
};

export function useGrowthRecords(babyId: string) {
  return useQuery({
    queryKey: growthKeys.list(babyId),
    queryFn: () =>
      apiClient.get<GrowthRecord[]>(`/api/v1/babies/${babyId}/growth`),
    enabled: !!babyId,
  });
}

export function useCreateGrowthRecord() {
  const qc = useQueryClient();
  return useMutation({
    mutationFn: ({
      babyId,
      data,
    }: {
      babyId: string;
      data: CreateGrowthRequest;
    }) =>
      apiClient.post<GrowthRecord>(`/api/v1/babies/${babyId}/growth`, data),
    onSettled: (_data, _err, vars) => {
      qc.invalidateQueries({ queryKey: growthKeys.list(vars.babyId) });
    },
  });
}

export function useDeleteGrowthRecord() {
  const qc = useQueryClient();
  return useMutation({
    mutationFn: ({
      babyId,
      recordId,
    }: {
      babyId: string;
      recordId: string;
    }) =>
      apiClient.delete<void>(
        `/api/v1/babies/${babyId}/growth/${recordId}`
      ),
    ...optimisticDeleteOptions<{ babyId: string; recordId: string }>({
      qc,
      listKey: growthKeys.all,
      getId: (v) => v.recordId,
    }),
  });
}
