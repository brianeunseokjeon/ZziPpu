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
import type {
  SleepRecord,
  CreateSleepRequest,
  StartSleepRequest,
} from "../types/sleep";

const sleepKeys = {
  all: ["sleep"] as const,
  list: (babyId: string, date: string) => ["sleep", babyId, date] as const,
  active: (babyId: string) => ["sleep", "active", babyId] as const,
};

export function useSleepRecords(babyId: string, date: string) {
  return useQuery({
    queryKey: sleepKeys.list(babyId, date),
    queryFn: () =>
      apiClient.get<SleepRecord[]>(
        `/api/v1/babies/${babyId}/sleeps?date=${date}`
      ),
    enabled: !!babyId,
    refetchInterval: date === getDateString(new Date()) ? 30000 : false,
    placeholderData: keepPreviousData,
  });
}

export function useActiveSleep(babyId: string) {
  return useQuery({
    queryKey: sleepKeys.active(babyId),
    queryFn: () =>
      apiClient.get<SleepRecord | null>(
        `/api/v1/babies/${babyId}/sleeps/active`
      ),
    enabled: !!babyId,
    refetchInterval: 10000,
  });
}

export function useStartSleep() {
  const qc = useQueryClient();
  return useMutation({
    mutationFn: (data: StartSleepRequest) =>
      apiClient.post<SleepRecord>(`/api/v1/babies/${data.babyId}/sleeps`, data),
    onSettled: (_data, _err, vars) => {
      qc.invalidateQueries({ queryKey: sleepKeys.active(vars.babyId) });
      qc.invalidateQueries({ queryKey: sleepKeys.all });
    },
  });
}

export function useEndSleep() {
  const qc = useQueryClient();
  return useMutation({
    mutationFn: ({ babyId, sleepId, endedAt }: { babyId: string; sleepId: string; endedAt: string }) =>
      apiClient.put<SleepRecord>(
        `/api/v1/babies/${babyId}/sleeps/${sleepId}/end`,
        { endedAt }
      ),
    onSettled: (_data, _err, vars) => {
      qc.invalidateQueries({ queryKey: sleepKeys.active(vars.babyId) });
      qc.invalidateQueries({ queryKey: sleepKeys.all });
      qc.invalidateQueries({ queryKey: ["daily-summary"] });
    },
  });
}

export function useCreateSleep() {
  const qc = useQueryClient();
  return useMutation({
    mutationFn: (data: CreateSleepRequest) =>
      apiClient.post<SleepRecord>(`/api/v1/babies/${data.babyId}/sleeps`, data),
    ...optimisticCreateOptions<CreateSleepRequest, SleepRecord>({
      qc,
      listKeyForDate: (v) => sleepKeys.list(v.babyId, getDateString(v.startedAt)),
      buildOptimistic: (v, tempId) => ({
        id: tempId,
        babyId: v.babyId,
        startedAt: v.startedAt,
        endedAt: v.endedAt,
        memo: v.memo,
        createdAt: new Date().toISOString(),
      }),
      alsoInvalidate: [["daily-summary"]],
    }),
  });
}

export function useDeleteSleep() {
  const qc = useQueryClient();
  return useMutation({
    mutationFn: ({ babyId, sleepId }: { babyId: string; sleepId: string }) =>
      apiClient.delete<void>(`/api/v1/babies/${babyId}/sleeps/${sleepId}`),
    ...optimisticDeleteOptions<{ babyId: string; sleepId: string }>({
      qc,
      listKey: sleepKeys.all,
      getId: (v) => v.sleepId,
      alsoInvalidate: [["daily-summary"]],
    }),
  });
}
