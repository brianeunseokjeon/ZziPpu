import {
  useQuery,
  useMutation,
  useQueryClient,
  keepPreviousData,
} from "@tanstack/react-query";
import { apiClient } from "@/lib/api-client";
import { getDateString } from "@/lib/date-utils";
import { optimisticDeleteOptions } from "@/shared/lib/optimisticDelete";
import { optimisticUpdateOptions } from "@/shared/lib/optimisticUpdate";
import { mutationKeys } from "@/shared/lib/mutationRegistry";
import type { Feeding, CreateFeedingRequest, FeedingType } from "../types/feeding";

const feedingKeys = {
  all: ["feedings"] as const,
  list: (babyId: string, date: string) =>
    ["feedings", babyId, date] as const,
};

export function useFeedings(babyId: string, date: string) {
  return useQuery({
    queryKey: feedingKeys.list(babyId, date),
    queryFn: () =>
      apiClient.get<Feeding[]>(`/api/v1/babies/${babyId}/feedings?date=${date}`),
    enabled: !!babyId,
    refetchInterval: date === getDateString(new Date()) ? 30000 : false,
    placeholderData: keepPreviousData,
  });
}

/**
 * 수유 기록 생성.
 *
 * 전송·낙관적 갱신·재시도·오프라인 복원 정책은 모두 mutationRegistry 의
 * setMutationDefaults 에 등록돼 있다(콜드스타트/오프라인 기록유실 방어).
 * 여기선 동일 mutationKey 만 지정해 그 기본 정의를 상속한다 —
 * 그래야 앱 재시작 후 복원된 mutation 도 같은 방식으로 재전송된다.
 */
export function useCreateFeeding() {
  return useMutation<Feeding, Error, CreateFeedingRequest>({
    mutationKey: mutationKeys.createFeeding,
  });
}

export interface UpdateFeedingRequest {
  babyId: string;
  feedingId: string;
  feedingType: FeedingType;
  startedAt: string;
  endedAt?: string;
  amountMl?: number;
  durationMinutes?: number;
  memo?: string;
}

export function useUpdateFeeding() {
  const qc = useQueryClient();
  return useMutation({
    mutationFn: ({ babyId, feedingId, ...rest }: UpdateFeedingRequest) =>
      apiClient.patch<Feeding>(
        `/api/v1/babies/${babyId}/feedings/${feedingId}`,
        rest
      ),
    // 낙관적 수정: 저장 즉시 타임라인의 해당 항목 교체, 실패 시 롤백+토스트
    ...optimisticUpdateOptions<UpdateFeedingRequest>({
      qc,
      listKey: feedingKeys.all,
      getId: (v) => v.feedingId,
      applyPatch: (item, v) => ({
        ...item,
        feedingType: v.feedingType,
        startedAt: v.startedAt,
        endedAt: v.endedAt,
        amountMl: v.amountMl,
        durationMinutes: v.durationMinutes,
        memo: v.memo,
      }),
      alsoInvalidate: [["daily-summary"]],
    }),
  });
}

export function useDeleteFeeding() {
  const qc = useQueryClient();
  return useMutation({
    mutationFn: ({ babyId, feedingId }: { babyId: string; feedingId: string }) =>
      apiClient.delete<void>(`/api/v1/babies/${babyId}/feedings/${feedingId}`),
    ...optimisticDeleteOptions<{ babyId: string; feedingId: string }>({
      qc,
      listKey: feedingKeys.all,
      getId: (v) => v.feedingId,
      alsoInvalidate: [["daily-summary"]],
    }),
  });
}
