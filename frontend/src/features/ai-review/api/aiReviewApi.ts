import {
  useQuery,
  useMutation,
  useQueryClient,
} from "@tanstack/react-query";
import { apiClient } from "@/lib/api-client";
import { MOCK_BABY_ID } from "@/config/constants";
import type { DailyReview, SavedInfo } from "../types/aiReview";

const aiReviewKeys = {
  all: ["ai-reviews"] as const,
  reviews: (babyId: string) => ["ai-reviews", babyId] as const,
  savedInfos: (babyId: string) => ["ai-saved-infos", babyId] as const,
};

export function useGenerateReview(babyId: string = MOCK_BABY_ID, date: string) {
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

export function useAIReviews(babyId: string = MOCK_BABY_ID) {
  return useQuery({
    queryKey: aiReviewKeys.reviews(babyId),
    queryFn: () =>
      apiClient.get<DailyReview[]>(`/api/v1/babies/${babyId}/ai/reviews`),
    enabled: !!babyId,
    select: (data) => data.slice(0, 7),
  });
}

export function useSavedInfos(babyId: string = MOCK_BABY_ID) {
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
    onSuccess: (_data, vars) => {
      qc.invalidateQueries({ queryKey: aiReviewKeys.savedInfos(vars.babyId) });
    },
  });
}
