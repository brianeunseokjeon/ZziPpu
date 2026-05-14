"use client";

import { useState } from "react";
import { Button } from "@/shared/components/ui/button";
import { Input } from "@/shared/components/ui/input";
import { useTimer } from "@/shared/hooks/useTimer";
import { useCreatePlay } from "../api/playApi";
import { type PlayType } from "../types/play";
import { useUIStore } from "@/shared/stores/uiStore";
import { PLAY_TYPES } from "@/config/constants";
import { cn } from "@/lib/utils";

function formatTimerDisplay(seconds: number): string {
  const m = Math.floor(seconds / 60);
  const s = seconds % 60;
  return `${String(m).padStart(2, "0")}:${String(s).padStart(2, "0")}`;
}

export function PlayForm() {
  const { activeBabyId } = useUIStore();
  const { mutate: createPlay, isPending } = useCreatePlay();
  const timer = useTimer("play");

  const [playType, setPlayType] = useState<PlayType>("tummy_time");
  const [memo, setMemo] = useState("");

  function handleSave() {
    const durationMinutes = timer.isRunning || timer.elapsedSeconds > 0
      ? Math.max(1, Math.round(timer.elapsedSeconds / 60))
      : 1;

    const startedAt = timer.startedAt
      ? new Date(timer.startedAt).toISOString()
      : new Date().toISOString();

    if (timer.isRunning) timer.stop();

    createPlay({
      babyId: activeBabyId,
      playType,
      durationMinutes,
      startedAt,
      endedAt: new Date().toISOString(),
      memo: memo || undefined,
    });

    timer.reset();
    setMemo("");
  }

  return (
    <div className="space-y-5">
      <div>
        <p className="text-sm font-medium text-gray-700 mb-2">놀이 종류</p>
        <div className="flex gap-3">
          {PLAY_TYPES.map(({ value, label, emoji }) => (
            <button
              key={value}
              onClick={() => setPlayType(value)}
              className={cn(
                "flex-1 flex flex-col items-center py-4 rounded-2xl border-2 transition-all",
                playType === value
                  ? "border-green-400 bg-green-50 text-green-700"
                  : "border-gray-100 bg-white text-gray-600 hover:border-gray-200"
              )}
            >
              <span className="text-2xl mb-1">{emoji}</span>
              <span className="text-xs font-medium">{label}</span>
            </button>
          ))}
        </div>
      </div>

      <div className="flex flex-col items-center gap-4 py-4">
        <div className="text-5xl font-bold tabular-nums text-gray-900 tracking-tight">
          {formatTimerDisplay(timer.elapsedSeconds)}
        </div>
        <div className="flex gap-3">
          {!timer.isRunning ? (
            <Button
              onClick={timer.start}
              className="px-8 bg-green-400 hover:bg-green-500"
            >
              시작
            </Button>
          ) : (
            <Button
              onClick={timer.stop}
              variant="outline"
              className="px-8 border-green-300 text-green-600"
            >
              일시정지
            </Button>
          )}
          {timer.elapsedSeconds > 0 && (
            <Button onClick={timer.reset} variant="ghost" size="sm">
              초기화
            </Button>
          )}
        </div>
      </div>

      <div>
        <p className="text-sm font-medium text-gray-700 mb-1.5">메모 (선택)</p>
        <Input
          placeholder="메모를 입력하세요"
          value={memo}
          onChange={(e) => setMemo(e.target.value)}
        />
      </div>

      <Button
        onClick={handleSave}
        disabled={isPending}
        className="w-full h-14 text-lg bg-green-400 hover:bg-green-500"
      >
        {isPending ? "저장 중..." : "저장"}
      </Button>
    </div>
  );
}
