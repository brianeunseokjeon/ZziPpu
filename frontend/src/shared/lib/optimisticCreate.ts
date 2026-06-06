import type { QueryClient, QueryKey } from "@tanstack/react-query";

/**
 * 낙관적 생성(optimistic create)용 React Query mutation 옵션 팩토리.
 *
 * 동작:
 *  1) onMutate — 해당 list 캐시 상단에 임시 항목을 즉시 삽입.
 *     서버 응답 전에 화면에 바로 나타난다. 이전 스냅샷을 저장.
 *  2) onError — 서버 실패 시 스냅샷을 복원. 에러 처리는 호출부에서 담당.
 *  3) onSettled — 성공/실패 무관 서버와 최종 동기화(invalidate).
 *
 * @param qc              QueryClient
 * @param listKeyForDate  vars 로부터 해당 날짜의 list queryKey 를 반환하는 함수
 * @param buildOptimistic vars 로부터 낙관적으로 화면에 보여줄 임시 레코드를 생성하는 함수
 * @param alsoInvalidate  추가로 무효화할 쿼리 키들 (예: [["daily-summary"]])
 */
export function optimisticCreateOptions<TVars, TRecord extends { id: string }>(opts: {
  qc: QueryClient;
  listKeyForDate: (vars: TVars) => QueryKey;
  buildOptimistic: (vars: TVars, tempId: string) => TRecord;
  alsoInvalidate?: QueryKey[];
}) {
  const { qc, listKeyForDate, buildOptimistic, alsoInvalidate = [] } = opts;

  return {
    onMutate: async (vars: TVars) => {
      const listKey = listKeyForDate(vars);
      await qc.cancelQueries({ queryKey: listKey });
      const snapshot = qc.getQueryData<TRecord[]>(listKey);
      const tempId = crypto.randomUUID();
      const optimisticItem = buildOptimistic(vars, tempId);
      qc.setQueryData<TRecord[]>(listKey, (old) =>
        Array.isArray(old) ? [optimisticItem, ...old] : [optimisticItem]
      );
      return { snapshot, listKey };
    },
    onError: (_err: unknown, _vars: TVars, ctx: unknown) => {
      const context = ctx as { snapshot?: TRecord[]; listKey?: QueryKey } | undefined;
      if (context?.listKey !== undefined) {
        qc.setQueryData(context.listKey, context.snapshot);
      }
    },
    onSettled: (_data: unknown, _err: unknown, vars: TVars) => {
      const listKey = listKeyForDate(vars);
      qc.invalidateQueries({ queryKey: listKey });
      alsoInvalidate.forEach((key) => qc.invalidateQueries({ queryKey: key }));
    },
  };
}
