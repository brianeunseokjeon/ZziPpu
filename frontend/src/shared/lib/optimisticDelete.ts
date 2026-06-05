import type { QueryClient, QueryKey } from "@tanstack/react-query";
import { toast } from "@/shared/stores/toastStore";

/**
 * 낙관적 삭제(optimistic delete)용 React Query mutation 옵션 팩토리.
 *
 * 동작:
 *  1) onMutate — 해당 도메인의 모든 list 캐시(prefix 매칭)에서 항목을 즉시 제거.
 *     누르는 순간 화면에서 사라진다(서버 응답 대기 X). 이전 스냅샷을 저장.
 *  2) onError — 서버 실패 시 스냅샷을 복원하고 토스트로 알림. 데이터가 되살아난다.
 *  3) onSettled — 성공/실패 무관 서버와 최종 동기화(invalidate).
 *
 * 모든 기록 삭제(수유·기저귀·수면·놀이·성장·AI리뷰)가 이 헬퍼를 공유한다.
 *
 * @param qc         QueryClient
 * @param listKey    해당 도메인 list 쿼리들의 공통 prefix (예: ["feedings"])
 * @param getId      삭제 변수에서 대상 id 를 추출하는 함수
 * @param alsoInvalidate 추가로 무효화할 쿼리 키들 (예: [["daily-summary"]])
 * @param errorMessage 실패 토스트 문구
 */
export function optimisticDeleteOptions<TVars>(opts: {
  qc: QueryClient;
  listKey: QueryKey;
  getId: (vars: TVars) => string;
  alsoInvalidate?: QueryKey[];
  errorMessage?: string;
}) {
  const {
    qc,
    listKey,
    getId,
    alsoInvalidate = [],
    errorMessage = "삭제하지 못했어요. 잠시 후 다시 시도해 주세요.",
  } = opts;

  return {
    onMutate: async (vars: TVars) => {
      const id = getId(vars);
      await qc.cancelQueries({ queryKey: listKey });
      // prefix 매칭되는 모든 list 캐시 스냅샷 저장
      const snapshots = qc.getQueriesData<{ id: string }[]>({ queryKey: listKey });
      // 각 캐시에서 해당 항목 제거 (날짜 키를 몰라도 전체에서 제거)
      qc.setQueriesData<{ id: string }[]>({ queryKey: listKey }, (old) =>
        Array.isArray(old) ? old.filter((item) => item.id !== id) : old
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
