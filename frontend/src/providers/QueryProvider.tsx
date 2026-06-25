"use client";

import { QueryClient, QueryClientProvider } from "@tanstack/react-query";
import { PersistQueryClientProvider } from "@tanstack/react-query-persist-client";
import { createSyncStoragePersister } from "@tanstack/query-sync-storage-persister";
import { useState } from "react";
import { registerMutationDefaults } from "@/shared/lib/mutationRegistry";
import { AppLifecycle } from "@/shared/components/AppLifecycle";
import { SyncStatusBadge } from "@/shared/components/SyncStatusBadge";

/**
 * React Query Provider — 캐시 영속화(localStorage) + 콜드스타트/오프라인 기록유실 방어.
 *
 * 목적: 새로고침/탭 이동 후에도 직전 데이터를 **즉시** 보여주고(stale-while-revalidate),
 * 백그라운드에서 갱신한다. 인메모리 캐시 소실로 인한 "빈 화면 → 뿅" 깜빡임 제거.
 *
 * 기록유실 방어(무료 호스팅 콜드스타트 대응):
 *  - mutations.retry + 지수 백오프: 서버가 깨어나는 동안(콜드스타트) 끝까지 재시도.
 *  - networkMode 'online': 오프라인엔 paused 로 보관 → 온라인 복구 시 자동 재전송.
 *  - mutation 영속화: paused 기록을 localStorage 에 저장 → 앱을 닫았다 열어도 복원·재전송.
 *  - registerMutationDefaults: 복원된 mutation 이 다시 전송할 수 있도록 mutationFn 등록.
 *
 * 클린아키텍처: 캐시·전송(인프라) 정책일 뿐 — 서버 DB 가 단일 진실 소스이고,
 * persister 를 다른 저장소로 교체해도 도메인/엔티티에 영향 없다.
 */
export function QueryProvider({ children }: { children: React.ReactNode }) {
  const [queryClient] = useState(() => {
    const qc = new QueryClient({
      defaultOptions: {
        queries: {
          staleTime: 30 * 1000,    // 30s fresh → 이후 background refetch
          gcTime: 30 * 60 * 1000, // 30분 캐시 보존 (탭 이동 후 즉시 복원)
          retry: 1,
          // 공유 계정 실시간 동기화: 앱 포그라운드 복귀 시 즉시 재조회
          refetchOnWindowFocus: true,
        },
        mutations: {
          // 콜드스타트(서버 깨어나는 30~60초) 동안 끝까지 재시도 → 기록유실 방지.
          retry: 6,
          retryDelay: (attempt) => Math.min(1000 * 2 ** attempt, 15000),
          // 오프라인이면 실패시키지 말고 paused 로 보관 → 온라인 복구 시 자동 재전송.
          networkMode: "online",
        },
      },
    });
    // 복원된(persist) mutation 이 재전송할 수 있도록 전송 정의를 등록.
    registerMutationDefaults(qc);
    return qc;
  });

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
    return (
      <QueryClientProvider client={queryClient}>
        <AppLifecycle />
        {children}
        <SyncStatusBadge />
      </QueryClientProvider>
    );
  }

  return (
    <PersistQueryClientProvider
      client={queryClient}
      persistOptions={{
        persister,
        maxAge: 24 * 60 * 60 * 1000,
        // 미완료(paused) 기록 mutation 도 함께 저장 → 앱 재시작 후 복원 가능.
        dehydrateOptions: {
          shouldDehydrateMutation: (mutation) => mutation.state.isPaused,
        },
      }}
      // localStorage 복원 완료 후, 대기 중이던 기록을 즉시 재전송.
      onSuccess={() => {
        queryClient.resumePausedMutations();
      }}
    >
      <AppLifecycle />
      {children}
      <SyncStatusBadge />
    </PersistQueryClientProvider>
  );
}
