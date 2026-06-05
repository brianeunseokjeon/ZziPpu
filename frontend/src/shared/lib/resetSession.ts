import type { QueryClient } from "@tanstack/react-query";
import { useAuthStore } from "@/features/auth/store/authStore";
import { useBabyStore } from "@/features/baby/store/babyStore";

/**
 * 신원 전환(로그아웃·다른 사용자 로그인) 시 **모든 사용자별 상태를 초기화**한다.
 *
 * ⚠️ 이걸 빠뜨리면 다음 사용자에게 이전 사용자의 아기 정보·기록이 잠깐 노출된다
 * (다중 사용자 정확성/프라이버시 이슈).
 *
 * 초기화 대상:
 *  - authStore (토큰/유저)
 *  - babyStore (아기 정보)
 *  - React Query 캐시 + 영속화된 localStorage 캐시
 *
 * 클린아키텍처: auth·baby 도메인의 생명주기 조율을 이 한 곳으로 끌어올려,
 * 표현계층(LogoutButton 등)이 각 store 내부를 몰라도 되게 한다.
 */
export function resetSession(queryClient: QueryClient) {
  useAuthStore.getState().clear();
  useBabyStore.getState().reset();
  queryClient.clear();
  if (typeof window !== "undefined") {
    window.localStorage.removeItem("zzippu-query-cache");
  }
}
