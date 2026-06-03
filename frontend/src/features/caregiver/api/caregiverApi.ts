import {
  useQuery,
  useMutation,
  useQueryClient,
} from "@tanstack/react-query";
import { apiClient } from "@/lib/api-client";

export interface InviteResponse {
  code: string;
  expiresAt: string;
}

export interface CaregiverMember {
  userId: string;
  role: string;
  createdAt: string;
}

const caregiverKeys = {
  list: (babyId: string) => ["caregivers", babyId] as const,
};

export function useCaregivers(babyId: string) {
  return useQuery({
    queryKey: caregiverKeys.list(babyId),
    queryFn: () =>
      apiClient.get<CaregiverMember[]>(`/api/v1/babies/${babyId}/caregivers`),
    enabled: !!babyId,
  });
}

export function useCreateInvite() {
  const qc = useQueryClient();
  return useMutation({
    mutationFn: (babyId: string) =>
      apiClient.post<InviteResponse>(
        `/api/v1/babies/${babyId}/caregivers/invite`
      ),
    onSettled: (_data, _err, babyId) => {
      qc.invalidateQueries({ queryKey: caregiverKeys.list(babyId) });
    },
  });
}

export function useJoinByCode() {
  const qc = useQueryClient();
  return useMutation({
    mutationFn: (code: string) =>
      apiClient.post<{ id: string; name: string }>(`/api/v1/caregivers/join`, {
        code,
      }),
    onSettled: () => {
      qc.invalidateQueries({ queryKey: ["babies"] });
    },
  });
}
