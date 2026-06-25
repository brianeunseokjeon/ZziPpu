"use client";

import { useEffect } from "react";
import { useQueryClient } from "@tanstack/react-query";
import { warmupServers } from "@/shared/lib/serverWarmup";

/**
 * 앱 생명주기에 맞춰 두 가지를 수행한다(콜드스타트·오프라인 기록유실 방어).
 *
 *  1. 서버 깨우기(Layer 1): 앱을 열거나(마운트), 포그라운드로 복귀하거나,
 *     온라인이 복구될 때 core·auth 서버를 미리 깨운다.
 *  2. 대기 기록 재전송(Layer 3): 온라인 복구·포그라운드 복귀 시
 *     paused 상태로 보관됐던 기록 mutation 을 즉시 재전송한다.
 *     (앱 재시작 후 localStorage 복원분은 QueryProvider 의 onSuccess 에서 1차 재개)
 *
 * 화면을 그리지 않는 부수효과 전용 컴포넌트.
 */
export function AppLifecycle() {
  const qc = useQueryClient();

  useEffect(() => {
    // 앱 진입 즉시 서버 깨우기 — 사용자가 기록 버튼을 누를 때쯤 warm 상태가 되도록.
    warmupServers(true);

    const onForeground = () => {
      if (document.visibilityState === "visible") {
        warmupServers();
        qc.resumePausedMutations();
      }
    };
    const onOnline = () => {
      warmupServers(true);
      qc.resumePausedMutations();
    };

    document.addEventListener("visibilitychange", onForeground);
    window.addEventListener("online", onOnline);
    return () => {
      document.removeEventListener("visibilitychange", onForeground);
      window.removeEventListener("online", onOnline);
    };
  }, [qc]);

  return null;
}
