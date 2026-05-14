"use client";

import { Moon, StopCircle } from "lucide-react";
import { Button } from "@/shared/components/ui/button";
import { useTimer } from "@/shared/hooks/useTimer";
import { useStartSleep, useEndSleep, useActiveSleep } from "../api/sleepApi";
import { useUIStore } from "@/shared/stores/uiStore";
import { useTimerStore } from "@/shared/stores/timerStore";

function formatTimerDisplay(seconds: number): string {
  const h = Math.floor(seconds / 3600);
  const m = Math.floor((seconds % 3600) / 60);
  const s = seconds % 60;
  return `${String(h).padStart(2, "0")}:${String(m).padStart(2, "0")}:${String(s).padStart(2, "0")}`;
}

export function SleepTimer() {
  const { activeBabyId } = useUIStore();
  const timer = useTimer("sleep");
  const { clearTimer } = useTimerStore();
  const { data: activeSleep } = useActiveSleep(activeBabyId);
  const { mutate: startSleep, isPending: isStarting } = useStartSleep();
  const { mutate: endSleep, isPending: isEnding } = useEndSleep();

  function handleStart() {
    const startedAt = new Date().toISOString();
    startSleep({ babyId: activeBabyId, startedAt });
    timer.start();
  }

  function handleEnd() {
    if (activeSleep) {
      endSleep({
        babyId: activeBabyId,
        sleepId: activeSleep.id,
        endedAt: new Date().toISOString(),
      });
    }
    timer.reset();
    clearTimer("sleep");
  }

  const isSleeping = timer.isRunning || !!activeSleep;

  return (
    <div className="flex flex-col items-center py-8 gap-6">
      <div
        className={`w-48 h-48 rounded-full flex flex-col items-center justify-center shadow-lg transition-all ${
          isSleeping
            ? "bg-gradient-to-br from-purple-400 to-purple-600"
            : "bg-gradient-to-br from-gray-100 to-gray-200"
        }`}
      >
        <Moon
          className={`w-10 h-10 mb-2 ${isSleeping ? "text-white" : "text-gray-400"}`}
          fill={isSleeping ? "currentColor" : "none"}
        />
        <span
          className={`text-3xl font-bold tabular-nums tracking-tight ${
            isSleeping ? "text-white" : "text-gray-500"
          }`}
        >
          {formatTimerDisplay(timer.elapsedSeconds)}
        </span>
        {isSleeping && (
          <span className="text-purple-100 text-xs mt-1">수면 중</span>
        )}
      </div>

      {!isSleeping ? (
        <Button
          onClick={handleStart}
          disabled={isStarting}
          className="px-10 h-14 text-lg bg-purple-400 hover:bg-purple-500"
        >
          <Moon className="w-5 h-5 mr-2" />
          수면 시작
        </Button>
      ) : (
        <Button
          onClick={handleEnd}
          disabled={isEnding}
          variant="outline"
          className="px-10 h-14 text-lg border-purple-300 text-purple-600 hover:bg-purple-50"
        >
          <StopCircle className="w-5 h-5 mr-2" />
          수면 종료
        </Button>
      )}

      {isSleeping && timer.startedAt && (
        <p className="text-sm text-gray-400">
          수면 시작:{" "}
          {new Date(timer.startedAt).toLocaleTimeString("ko-KR", {
            hour: "2-digit",
            minute: "2-digit",
          })}
        </p>
      )}
    </div>
  );
}
