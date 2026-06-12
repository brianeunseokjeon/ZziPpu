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
    onMutate: async (vars) => {
      const key = growthKeys.list(vars.babyId);
      await qc.cancelQueries({ queryKey: key });
      const prev = qc.getQueryData<GrowthRecord[]>(key);
      const tempRecord: GrowthRecord = {
        id: "temp-" + vars.babyId.slice(0, 4) + "-" + vars.data.recordedAt,
        babyId: vars.babyId,
        recordedAt: vars.data.recordedAt,
        weightG: vars.data.weightG ?? null,
        heightCm: vars.data.heightCm ?? null,
        headCircumferenceCm: vars.data.headCircumferenceCm ?? null,
        memo: vars.data.memo ?? null,
        createdAt: vars.data.recordedAt,
      };
      qc.setQueryData<GrowthRecord[]>(key, [tempRecord, ...(prev ?? [])]);
      return { prev };
    },
    onError: (_err, vars, ctx) => {
      if (ctx?.prev !== undefined) {
        qc.setQueryData(growthKeys.list(vars.babyId), ctx.prev);
      }
    },
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
