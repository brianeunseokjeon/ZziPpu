import { create } from "zustand";
import { persist } from "zustand/middleware";

export type TimerType = "feeding" | "sleep" | "play";

export interface Timer {
  id: string;
  type: TimerType;
  startedAt: number;
  isRunning: boolean;
}

interface TimerState {
  timers: Record<TimerType, Timer | null>;
  startTimer: (type: TimerType) => void;
  stopTimer: (type: TimerType) => void;
  getTimer: (type: TimerType) => Timer | null;
  getElapsedSeconds: (type: TimerType) => number;
  clearTimer: (type: TimerType) => void;
}

export const useTimerStore = create<TimerState>()(
  persist(
    (set, get) => ({
      timers: {
        feeding: null,
        sleep: null,
        play: null,
      },

      startTimer: (type) => {
        const timer: Timer = {
          id: `${type}-${Date.now()}`,
          type,
          startedAt: Date.now(),
          isRunning: true,
        };
        set((s) => ({ timers: { ...s.timers, [type]: timer } }));
      },

      stopTimer: (type) => {
        set((s) => {
          const t = s.timers[type];
          if (!t) return s;
          return { timers: { ...s.timers, [type]: { ...t, isRunning: false } } };
        });
      },

      getTimer: (type) => get().timers[type],

      getElapsedSeconds: (type) => {
        const t = get().timers[type];
        if (!t || !t.isRunning) return 0;
        return Math.floor((Date.now() - t.startedAt) / 1000);
      },

      clearTimer: (type) => {
        set((s) => ({ timers: { ...s.timers, [type]: null } }));
      },
    }),
    {
      name: "muknoljam-timers",
      partialize: (s) => ({ timers: s.timers }),
    }
  )
);
