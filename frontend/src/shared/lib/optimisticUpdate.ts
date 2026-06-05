import type { QueryClient, QueryKey } from "@tanstack/react-query";
import { toast } from "@/shared/stores/toastStore";

/**
 * 낙관적 수정(optimistic update)용 React Query mutation 옵션 팩토리.
 * optimisticDelete 와 짝을 이룬다 — 차이는 "제거" 대신 "해당 항목을 새 값으로 교체".
 *
 * onMutate: list 캐시에서 id 항목을 applyPatch 결과로 즉시 교체(+스냅샷)
 * onError:  스냅샷 복원 + 에러 토스트
 * onSettled: 서버 진실로 최종 동기화(invalidate)
 */
export function optimisticUpdateOptions<TVars>(opts: {
  qc: QueryClient;
  listKey: QueryKey;
  getId: (vars: TVars) => string;
  applyPatch: (item: Record<string, unknown>, vars: TVars) => Record<string, unknown>;
  alsoInvalidate?: QueryKey[];
  errorMessage?: string;
}) {
  const {
    qc,
    listKey,
    getId,
    applyPatch,
    alsoInvalidate = [],
    errorMessage = "수정하지 못했어요. 잠시 후 다시 시도해 주세요.",
  } = opts;

  return {
    onMutate: async (vars: TVars) => {
      const id = getId(vars);
      await qc.cancelQueries({ queryKey: listKey });
      const snapshots = qc.getQueriesData<Record<string, unknown>[]>({ queryKey: listKey });
      qc.setQueriesData<Record<string, unknown>[]>({ queryKey: listKey }, (old) =>
        Array.isArray(old) ? old.map((item) => (item.id === id ? applyPatch(item, vars) : item)) : old
      );
      return { snapshots };
    },
    onError: (_err: unknown, _vars: TVars, ctx: unknown) => {
      const snapshots = (ctx as { snapshots?: [QueryKey, unknown][] } | undefined)?.snapshots;
      snapshots?.forEach(([key, data]) => qc.setQueryData(key, data));
      toast(errorMessage, "error");
    },
    onSettled: () => {
      qc.invalidateQueries({ queryKey: listKey });
      alsoInvalidate.forEach((key) => qc.invalidateQueries({ queryKey: key }));
    },
  };
}
