import { useQuery, useMutation, useQueryClient } from "@tanstack/react-query";
import { apiClient } from "@/lib/api-client";
import type { Vaccination, MarkAdministeredRequest } from "../types/vaccination";

const vaccinationKeys = {
  all: ["vaccinations"] as const,
  list: (babyId: string) => ["vaccinations", babyId] as const,
  upcoming: (babyId: string) => ["vaccinations", babyId, "upcoming"] as const,
};

export function useVaccinations(babyId: string) {
  return useQuery({
    queryKey: vaccinationKeys.list(babyId),
    queryFn: () =>
      apiClient.get<Vaccination[]>(`/api/v1/babies/${babyId}/vaccinations`),
    enabled: !!babyId,
  });
}

export function useUpcomingVaccinations(babyId: string) {
  return useQuery({
    queryKey: vaccinationKeys.upcoming(babyId),
    queryFn: () =>
      apiClient.get<Vaccination[]>(
        `/api/v1/babies/${babyId}/vaccinations/upcoming`
      ),
    enabled: !!babyId,
  });
}

export function useMarkAdministered() {
  const qc = useQueryClient();
  return useMutation({
    mutationFn: ({
      babyId,
      vaccinationId,
      data,
    }: {
      babyId: string;
      vaccinationId: string;
      data: MarkAdministeredRequest;
    }) =>
      apiClient.post<Vaccination>(
        `/api/v1/babies/${babyId}/vaccinations/${vaccinationId}/administer`,
        data
      ),
    onSettled: () => {
      qc.invalidateQueries({ queryKey: vaccinationKeys.all });
    },
  });
}
