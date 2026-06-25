import type { QueryClient } from "@tanstack/react-query";
import { apiClient } from "@/lib/api-client";
import { getDateString } from "@/lib/date-utils";
import type { Feeding, CreateFeedingRequest } from "@/features/feeding/types/feeding";

/**
 * 기록 생성 mutation 의 "기본 정의"를 한 곳에 등록한다 (Layer 3 의 핵심).
 *
 * 왜 필요한가:
 *  오프라인/네트워크 단절 중 누른 기록은 React Query 가 paused 상태로 보관하고,
 *  앱이 닫혔다 다시 열려도 localStorage 에서 복원해 **자동으로 재전송**한다.
 *  그런데 복원된 mutation 은 컴포넌트의 useMutation 콜백을 잃은 상태라,
 *  여기에 등록된 mutationFn(실제 POST)이 있어야 재전송이 가능하다.
 *
 *  → 컴포넌트의 useCreateFeeding 은 동일한 mutationKey 만 지정하면
 *    이 기본 정의(전송·낙관적 갱신·무효화)를 그대로 상속한다.
 *
 * 클린아키텍처: "전송 보장" 정책을 표현계층에서 끌어올려 한 곳에 격리.
 */
export const mutationKeys = {
  createFeeding: ["feedings", "create"] as const,
};

const feedingListKey = (babyId: string, date: string) =>
  ["feedings", babyId, date] as const;

type CreateFeedingContext = {
  prev?: Feeding[];
  key: readonly unknown[];
};

export function registerMutationDefaults(qc: QueryClient): void {
  qc.setMutationDefaults<Feeding, Error, CreateFeedingRequest, CreateFeedingContext>(
    mutationKeys.createFeeding,
    {
      mutationFn: (data) =>
        apiClient.post<Feeding>(`/api/v1/babies/${data.babyId}/feedings`, data),
      onMutate: async (vars) => {
        const date = getDateString(vars.startedAt);
        const key = feedingListKey(vars.babyId, date);
        await qc.cancelQueries({ queryKey: key });
        const prev = qc.getQueryData<Feeding[]>(key);
        qc.setQueryData<Feeding[]>(key, [
          { ...vars, id: `temp-${Date.now()}`, createdAt: new Date().toISOString() },
          ...(prev ?? []),
        ]);
        return { prev, key };
      },
      onError: (_err, _vars, ctx) => {
        if (ctx?.prev !== undefined) {
          qc.setQueryData(ctx.key, ctx.prev);
        }
      },
      onSettled: (_data, _err, vars) => {
        const date = getDateString(vars.startedAt);
        qc.invalidateQueries({ queryKey: feedingListKey(vars.babyId, date) });
        qc.invalidateQueries({ queryKey: ["daily-summary"] });
      },
    }
  );
}
