/**
 * 활동 타이머 store — 수면 / 놀이 / 수유 (모유) 세션 관리.
 *
 * 기존 timerStore의 버그 (일시정지 = 0초 사라짐) 해결:
 *  - 일시정지하면 그때까지의 누적시간을 accumulatedMs에 저장
 *  - 재개 시 startedAt만 갱신하고 누적은 유지
 *  - getElapsedMs는 (현재 진행 중 ms) + accumulatedMs
 *
 * persist (localStorage) → 앱 종료해도 진행 중 세션 유지.
 */
import { create } from "zustand";
import { persist } from "zustand/middleware";

export type ActivityType = "sleep" | "play" | "feeding";

export interface ActivityMeta {
  playType?: string;       // "tummy_time" | "free_play" | "sensory_play"
  feedingType?: string;    // "breast_left" | "breast_right" | "breast_both"
  babyId?: string;
  memo?: string;
}

export interface ActiveSession {
  id: string;
  type: ActivityType;
  startedAt: number;          // 최초 시작 시각 (Date.now()) — 저장 시 startedAt으로 사용
  resumedAt: number;          // 현재 진행 중 구간 시작 시각 (= 시작/재개 시점)
  pausedAt: number | null;    // 현재 멈춘 상태면 멈춘 시각, 진행 중이면 null
  accumulatedMs: number;      // 일시정지 이전까지 누적된 ms (재개 시 합산)
  meta: ActivityMeta;
}

export interface FinishedSession {
  startedAt: Date;
  endedAt: Date;
  durationMinutes: number;
  meta: ActivityMeta;
}

interface TimerState {
  sessions: Record<ActivityType, ActiveSession | null>;

  startSession: (type: ActivityType, meta?: ActivityMeta) => void;
  pauseSession: (type: ActivityType) => void;
  resumeSession: (type: ActivityType) => void;
  finishSession: (type: ActivityType) => FinishedSession | null;
  cancelSession: (type: ActivityType) => void;
  updateMeta: (type: ActivityType, meta: Partial<ActivityMeta>) => void;

  getSession: (type: ActivityType) => ActiveSession | null;
  getElapsedMs: (type: ActivityType) => number;
  getAllActive: () => ActiveSession[];
}

function calcElapsed(s: ActiveSession): number {
  if (s.pausedAt !== null) {
    return s.accumulatedMs;
  }
  return s.accumulatedMs + (Date.now() - s.resumedAt);
}

export const useActivityTimerStore = create<TimerState>()(
  persist(
    (set, get) => ({
      sessions: { sleep: null, play: null, feeding: null },

      startSession: (type, meta = {}) => {
        const now = Date.now();
        const session: ActiveSession = {
          id: `${type}-${now}`,
          type,
          startedAt: now,
          resumedAt: now,
          pausedAt: null,
          accumulatedMs: 0,
          meta,
        };
        set((s) => ({ sessions: { ...s.sessions, [type]: session } }));
      },

      pauseSession: (type) => {
        set((s) => {
          const cur = s.sessions[type];
          if (!cur || cur.pausedAt !== null) return s;
          const now = Date.now();
          const elapsed = now - cur.resumedAt;
          return {
            sessions: {
              ...s.sessions,
              [type]: {
                ...cur,
                pausedAt: now,
                accumulatedMs: cur.accumulatedMs + elapsed,
              },
            },
          };
        });
      },

      resumeSession: (type) => {
        set((s) => {
          const cur = s.sessions[type];
          if (!cur || cur.pausedAt === null) return s;
          return {
            sessions: {
              ...s.sessions,
              [type]: { ...cur, resumedAt: Date.now(), pausedAt: null },
            },
          };
        });
      },

      finishSession: (type) => {
        const cur = get().sessions[type];
        if (!cur) return null;
        const totalMs = calcElapsed(cur);
        const result: FinishedSession = {
          startedAt: new Date(cur.startedAt),
          endedAt: new Date(),
          durationMinutes: Math.max(1, Math.round(totalMs / 60000)),
          meta: cur.meta,
        };
        set((s) => ({ sessions: { ...s.sessions, [type]: null } }));
        return result;
      },

      cancelSession: (type) => {
        set((s) => ({ sessions: { ...s.sessions, [type]: null } }));
      },

      updateMeta: (type, partial) => {
        set((s) => {
          const cur = s.sessions[type];
          if (!cur) return s;
          return {
            sessions: {
              ...s.sessions,
              [type]: { ...cur, meta: { ...cur.meta, ...partial } },
            },
          };
        });
      },

      getSession: (type) => get().sessions[type],

      getElapsedMs: (type) => {
        const s = get().sessions[type];
        return s ? calcElapsed(s) : 0;
      },

      getAllActive: () => {
        const all = get().sessions;
        return [all.sleep, all.play, all.feeding].filter(
          (s): s is ActiveSession => s !== null
        );
      },
    }),
    {
      name: "muknoljam-activity-timers",
      partialize: (s) => ({ sessions: s.sessions }),
    }
  )
);
