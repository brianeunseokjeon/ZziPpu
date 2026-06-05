import {
  useQuery,
  useMutation,
  useQueryClient,
} from "@tanstack/react-query";
import { apiClient } from "@/lib/api-client";
import { optimisticDeleteOptions } from "@/shared/lib/optimisticDelete";
import type { DailyReview, SavedInfo } from "../types/aiReview";

const aiReviewKeys = {
  all: ["ai-reviews"] as const,
  reviews: (babyId: string) => ["ai-reviews", babyId] as const,
  savedInfos: (babyId: string) => ["ai-saved-infos", babyId] as const,
};

export function useGenerateReview(babyId: string, date: string) {
  const qc = useQueryClient();
  return useMutation({
    mutationFn: () =>
      apiClient.post<DailyReview>(
        `/api/v1/babies/${babyId}/ai/review`,
        { review_date: date }
      ),
    onSuccess: () => {
      qc.invalidateQueries({ queryKey: aiReviewKeys.reviews(babyId) });
    },
  });
}

export function useAIReviews(babyId: string) {
  return useQuery({
    queryKey: aiReviewKeys.reviews(babyId),
    queryFn: () =>
      apiClient.get<DailyReview[]>(`/api/v1/babies/${babyId}/ai/reviews`),
    enabled: !!babyId,
    select: (data) => data.slice(0, 7),
  });
}

export function useSavedInfos(babyId: string) {
  return useQuery({
    queryKey: aiReviewKeys.savedInfos(babyId),
    queryFn: () =>
      apiClient.get<SavedInfo[]>(`/api/v1/babies/${babyId}/ai/saved-info`),
    enabled: !!babyId,
  });
}

export function useDeleteSavedInfo() {
  const qc = useQueryClient();
  return useMutation({
    mutationFn: ({ babyId, id }: { babyId: string; id: string }) =>
      apiClient.delete<void>(`/api/v1/babies/${babyId}/ai/saved-info/${id}`),
    ...optimisticDeleteOptions<{ babyId: string; id: string }>({
      qc,
      listKey: ["ai-saved-infos"],
      getId: (v) => v.id,
    }),
  });
}
