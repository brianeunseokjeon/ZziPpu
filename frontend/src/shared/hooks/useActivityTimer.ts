"use client";

import { useEffect, useState } from "react";
import {
  type ActiveSession,
  type ActivityMeta,
  type ActivityType,
  type FinishedSession,
  useActivityTimerStore,
} from "@/shared/stores/activityTimerStore";

/**
 * 활동 타이머 훅.
 * - 진행 중이면 1초마다 elapsed 갱신
 * - 일시정지/재개/완료 콜백 제공
 * - getSession() 으로 raw session 접근 가능 (배너 등에서 사용)
 */
export function useActivityTimer(type: ActivityType) {
  const store = useActivityTimerStore();
  const session: ActiveSession | null = useActivityTimerStore(
    (s) => s.sessions[type]
  );

  const isRunning = !!session && session.pausedAt === null;
  const isPaused = !!session && session.pausedAt !== null;
  const isActive = !!session;

  const [elapsedMs, setElapsedMs] = useState(() =>
    session ? store.getElapsedMs(type) : 0
  );

  // 1초마다 갱신 (진행 중일 때만)
  useEffect(() => {
    if (!isRunning) {
      setElapsedMs(session ? store.getElapsedMs(type) : 0);
      return;
    }
    setElapsedMs(store.getElapsedMs(type));
    const id = setInterval(() => setElapsedMs(store.getElapsedMs(type)), 1000);
    return () => clearInterval(id);
  }, [isRunning, isPaused, type, store, session]);

  return {
    session,
    isActive,
    isRunning,
    isPaused,
    elapsedMs,
    elapsedSeconds: Math.floor(elapsedMs / 1000),

    start: (meta?: ActivityMeta) => store.startSession(type, meta),
    pause: () => store.pauseSession(type),
    resume: () => store.resumeSession(type),
    finish: (): FinishedSession | null => store.finishSession(type),
    cancel: () => store.cancelSession(type),
    updateMeta: (m: Partial<ActivityMeta>) => store.updateMeta(type, m),
  };
}

/** "MM:SS" or "HH:MM:SS" (1시간 이상이면) */
export function formatElapsed(ms: number): string {
  const totalSec = Math.floor(ms / 1000);
  const h = Math.floor(totalSec / 3600);
  const m = Math.floor((totalSec % 3600) / 60);
  const s = totalSec % 60;
  const pad = (n: number) => String(n).padStart(2, "0");
  if (h > 0) return `${h}:${pad(m)}:${pad(s)}`;
  return `${pad(m)}:${pad(s)}`;
}
