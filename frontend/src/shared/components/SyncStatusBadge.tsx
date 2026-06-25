"use client";

import { useEffect, useState } from "react";
import { useIsMutating, onlineManager } from "@tanstack/react-query";
import { CloudOff, RefreshCw } from "lucide-react";

/**
 * 화면 우하단에 "저장 중 / 대기 중" 상태를 잠깐 보여준다.
 *
 * 신생아 기록에서 가장 중요한 건 부모의 신뢰 — "방금 누른 게 진짜 저장됐나?"
 * 평소엔 숨어 있다가, 전송이 진행 중이거나 오프라인 대기 중일 때만 나타난다.
 * 모두 끝나면(서버 반영 완료) 자동으로 사라진다 → 보이지 않으면 = 안전.
 */
export function SyncStatusBadge() {
  const mutating = useIsMutating();
  const [online, setOnline] = useState(true);

  useEffect(() => {
    setOnline(onlineManager.isOnline());
    return onlineManager.subscribe(setOnline);
  }, []);

  // 전송할 게 없으면 표시하지 않는다.
  if (mutating === 0) return null;

  const offline = !online;

  return (
    <div
      className="fixed bottom-20 left-1/2 -translate-x-1/2 z-50 flex items-center gap-1.5 rounded-full px-3 py-1.5 text-xs font-medium shadow-lg"
      style={{
        backgroundColor: offline ? "#fef3c7" : "#dbeafe",
        color: offline ? "#92400e" : "#1e40af",
        bottom: "calc(5rem + env(safe-area-inset-bottom))",
      }}
      role="status"
      aria-live="polite"
    >
      {offline ? (
        <>
          <CloudOff className="w-3.5 h-3.5" />
          <span>오프라인 — 연결되면 자동 저장돼요</span>
        </>
      ) : (
        <>
          <RefreshCw className="w-3.5 h-3.5 animate-spin" />
          <span>저장 중…</span>
        </>
      )}
    </div>
  );
}
