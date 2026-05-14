import {
  useQuery,
  useMutation,
  useQueryClient,
} from "@tanstack/react-query";
import { apiClient } from "@/lib/api-client";
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
  });
}

export function useCreateDiaper() {
  const qc = useQueryClient();
  return useMutation({
    mutationFn: (data: CreateDiaperRequest) =>
      apiClient.post<DiaperRecord>(`/api/v1/babies/${data.babyId}/diapers`, data),
    onSettled: (_data, _err, vars) => {
      const date = vars.occurredAt.slice(0, 10);
      qc.invalidateQueries({ queryKey: diaperKeys.list(vars.babyId, date) });
      qc.invalidateQueries({ queryKey: ["daily-summary"] });
    },
  });
}

export function useDeleteDiaper() {
  const qc = useQueryClient();
  return useMutation({
    mutationFn: ({ babyId, diaperId }: { babyId: string; diaperId: string }) =>
      apiClient.delete<void>(`/api/v1/babies/${babyId}/diapers/${diaperId}`),
    onSettled: () => {
      qc.invalidateQueries({ queryKey: diaperKeys.all });
      qc.invalidateQueries({ queryKey: ["daily-summary"] });
    },
  });
}
