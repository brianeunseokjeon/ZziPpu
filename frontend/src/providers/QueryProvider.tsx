"use client";

import { QueryClient, QueryClientProvider } from "@tanstack/react-query";
import { PersistQueryClientProvider } from "@tanstack/react-query-persist-client";
import { createSyncStoragePersister } from "@tanstack/query-sync-storage-persister";
import { useState } from "react";

/**
 * React Query Provider — 캐시 영속화(localStorage) 적용.
 *
 * 목적: 새로고침/탭 이동 후에도 직전 데이터를 **즉시** 보여주고(stale-while-revalidate),
 * 백그라운드에서 갱신한다. 인메모리 캐시 소실로 인한 "빈 화면 → 뿅" 깜빡임 제거.
 *
 * 클린아키텍처: 캐시(인프라) 정책일 뿐 — 서버 DB 가 단일 진실 소스이고,
 * persister 를 다른 저장소로 교체해도 도메인/엔티티에 영향 없다.
 */
export function QueryProvider({ children }: { children: React.ReactNode }) {
  const [queryClient] = useState(
    () =>
      new QueryClient({
        defaultOptions: {
          queries: {
            staleTime: 30 * 1000,    // 30s fresh → 이후 background refetch
            gcTime: 30 * 60 * 1000, // 30분 캐시 보존 (탭 이동 후 즉시 복원)
            retry: 1,
            // 공유 계정 실시간 동기화: 앱 포그라운드 복귀 시 즉시 재조회
            refetchOnWindowFocus: true,
          },
        },
      })
  );

  // localStorage persister (브라우저에서만). SSR 단계에선 일반 Provider 로 폴백.
  const [persister] = useState(() =>
    typeof window === "undefined"
      ? null
      : createSyncStoragePersister({
          storage: window.localStorage,
          key: "zzippu-query-cache",
        })
  );

  if (!persister) {
    return <QueryClientProvider client={queryClient}>{children}</QueryClientProvider>;
  }

  return (
    <PersistQueryClientProvider
      client={queryClient}
      persistOptions={{ persister, maxAge: 24 * 60 * 60 * 1000 }}
    >
      {children}
    </PersistQueryClientProvider>
  );
}
