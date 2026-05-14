"use client";

import { useEffect, useState } from "react";
import { useTimerStore, type TimerType } from "@/shared/stores/timerStore";

export function useTimer(type: TimerType) {
  const { startTimer, stopTimer, clearTimer, getTimer, getElapsedSeconds } =
    useTimerStore();
  const [elapsedSeconds, setElapsedSeconds] = useState(0);

  const timer = getTimer(type);
  const isRunning = timer?.isRunning ?? false;

  useEffect(() => {
    if (!isRunning) {
      setElapsedSeconds(0);
      return;
    }

    setElapsedSeconds(getElapsedSeconds(type));

    const interval = setInterval(() => {
      setElapsedSeconds(getElapsedSeconds(type));
    }, 1000);

    return () => clearInterval(interval);
  }, [isRunning, type, getElapsedSeconds]);

  function start() {
    startTimer(type);
  }

  function stop() {
    stopTimer(type);
    return timer?.startedAt ? Math.floor((Date.now() - timer.startedAt) / 1000) : 0;
  }

  function reset() {
    clearTimer(type);
    setElapsedSeconds(0);
  }

  return {
    isRunning,
    elapsedSeconds,
    startedAt: timer?.startedAt,
    start,
    stop,
    reset,
  };
}
