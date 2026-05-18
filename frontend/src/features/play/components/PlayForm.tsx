"use client";

import { useEffect, useState } from "react";
import { Pause, Play, CheckCircle2, RotateCcw } from "lucide-react";
import { Button } from "@/shared/components/ui/button";
import { Input } from "@/shared/components/ui/input";
import { useActivityTimer, formatElapsed } from "@/shared/hooks/useActivityTimer";
import { useRecordingPreferencesStore, type RecordingMode } from "@/shared/stores/recordingPreferencesStore";
import { useCreatePlay } from "../api/playApi";
import { type PlayType } from "../types/play";
import { useUIStore } from "@/shared/stores/uiStore";
import { PLAY_TYPES } from "@/config/constants";
import { ModeToggle } from "@/features/recording/components/ModeToggle";
import { cn } from "@/lib/utils";

export function PlayForm() {
  const { activeBabyId } = useUIStore();
  const { mutateAsync: createPlay, isPending } = useCreatePlay();
  const timer = useActivityTimer("play");
  const defaultMode = useRecordingPreferencesStore((s) => s.defaultModes.play);

  // 진행 중인 세션이 있으면 무조건 timer 모드로 표시
  const [mode, setMode] = useState<RecordingMode>(
    timer.isActive ? "timer" : defaultMode
  );

  // 진행 중 세션이 외부에서 생기면 자동으로 timer 모드로
  useEffect(() => {
    if (timer.isActive) setMode("timer");
  }, [timer.isActive]);

  const [playType, setPlayType] = useState<PlayType>(
    (timer.session?.meta.playType as PlayType) || "tummy_time"
  );
  const [memo, setMemo] = useState("");
  const [manualStartedAt, setManualStartedAt] = useState("");
  const [manualEndedAt, setManualEndedAt] = useState("");
  const [manualDuration, setManualDuration] = useState<number | "">("");

  // playType 변경 시 진행 중 세션에도 반영
  function handlePlayTypeChange(v: PlayType) {
    setPlayType(v);
    if (timer.isActive) timer.updateMeta({ playType: v });
  }

  async function saveRecord(args: {
    startedAt: string;
    endedAt?: string;
    durationMinutes: number;
  }) {
    await createPlay({
      babyId: activeBabyId,
      playType,
      durationMinutes: args.durationMinutes,
      startedAt: args.startedAt,
      endedAt: args.endedAt,
      memo: memo || undefined,
    });
    setMemo("");
    setManualStartedAt("");
    setManualEndedAt("");
    setManualDuration("");
  }

  // === 모드별 핸들러 ===

  async function handleNowRecord() {
    // 1탭 — "방금 끝남" 으로 1분으로 기록
    const now = new Date();
    await saveRecord({
      startedAt: now.toISOString(),
      endedAt: now.toISOString(),
      durationMinutes: 1,
    });
  }

  function handleTimerStart() {
    timer.start({ playType, babyId: activeBabyId, memo });
  }

  async function handleTimerFinish() {
    const finished = timer.finish();
    if (!finished) return;
    await saveRecord({
      startedAt: finished.startedAt.toISOString(),
      endedAt: finished.endedAt.toISOString(),
      durationMinutes: finished.durationMinutes,
    });
  }

  async function handleManualSave() {
    if (!manualStartedAt) {
      alert("시작 시간을 입력해주세요");
      return;
    }
    const startedAt = new Date(manualStartedAt);
    let durationMinutes: number;
    let endedAtISO: string | undefined;

    if (manualEndedAt) {
      const endedAt = new Date(manualEndedAt);
      durationMinutes = Math.max(1, Math.round((endedAt.getTime() - startedAt.getTime()) / 60000));
      endedAtISO = endedAt.toISOString();
    } else if (manualDuration !== "" && Number(manualDuration) > 0) {
      durationMinutes = Math.round(Number(manualDuration));
      const endedAt = new Date(startedAt.getTime() + durationMinutes * 60000);
      endedAtISO = endedAt.toISOString();
    } else {
      alert("종료 시간 또는 시간(분)을 입력해주세요");
      return;
    }

    await saveRecord({
      startedAt: startedAt.toISOString(),
      endedAt: endedAtISO,
      durationMinutes,
    });
  }

  return (
    <div className="space-y-5">
      <ModeToggle activity="play" mode={mode} onChange={setMode} />

      {/* 놀이 종류 — 모든 모드 공통 */}
      <div>
        <p className="text-sm font-medium text-gray-700 mb-2">놀이 종류</p>
        <div className="flex gap-3">
          {PLAY_TYPES.map(({ value, label, emoji }) => (
            <button
              key={value}
              onClick={() => handlePlayTypeChange(value)}
              className={cn(
                "flex-1 flex flex-col items-center py-3.5 rounded-2xl border-2 transition-all",
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

      {/* ⚡ 지금 기록 모드 */}
      {mode === "now" && (
        <div className="bg-green-50 rounded-2xl p-4 space-y-3 border border-green-100">
          <p className="text-sm text-green-700">
            "방금 끝났어요" — 1탭으로 1분 기록을 남깁니다.
          </p>
          <Button
            onClick={handleNowRecord}
            disabled={isPending}
            className="w-full h-14 text-lg bg-green-500 hover:bg-green-600"
          >
            {isPending ? "저장 중..." : "지금 기록"}
          </Button>
        </div>
      )}

      {/* ⏱ 타이머 모드 */}
      {mode === "timer" && (
        <div className="flex flex-col items-center gap-4 py-4 bg-green-50/40 rounded-2xl">
          <div className="text-5xl font-bold tabular-nums text-gray-900 tracking-tight">
            {formatElapsed(timer.elapsedMs)}
          </div>
          {timer.isPaused && (
            <div className="text-sm text-gray-500">⏸ 일시정지됨</div>
          )}

          <div className="flex gap-3">
            {!timer.isActive ? (
              <Button
                onClick={handleTimerStart}
                className="px-8 bg-green-500 hover:bg-green-600 flex items-center gap-2"
              >
                <Play className="w-4 h-4" />
                시작
              </Button>
            ) : (
              <>
                {timer.isPaused ? (
                  <Button
                    onClick={timer.resume}
                    className="px-6 bg-green-500 hover:bg-green-600 flex items-center gap-2"
                  >
                    <Play className="w-4 h-4" />
                    재개
                  </Button>
                ) : (
                  <Button
                    onClick={timer.pause}
                    variant="outline"
                    className="px-6 border-green-300 text-green-600 flex items-center gap-2"
                  >
                    <Pause className="w-4 h-4" />
                    일시정지
                  </Button>
                )}
                <Button
                  onClick={handleTimerFinish}
                  disabled={isPending}
                  className="px-6 bg-blue-500 hover:bg-blue-600 flex items-center gap-2"
                >
                  <CheckCircle2 className="w-4 h-4" />
                  완료
                </Button>
                <Button
                  onClick={timer.cancel}
                  variant="ghost"
                  size="sm"
                  className="text-gray-500"
                  title="취소"
                >
                  <RotateCcw className="w-4 h-4" />
                </Button>
              </>
            )}
          </div>

          <p className="text-xs text-gray-400 text-center max-w-xs">
            완료 못해도 괜찮아요. 진행 중 표시가 모든 화면에 보입니다.
          </p>
        </div>
      )}

      {/* ✏️ 수동 입력 모드 */}
      {mode === "manual" && (
        <div className="space-y-3 bg-gray-50 rounded-2xl p-4 border border-gray-100">
          <div>
            <p className="text-sm font-medium text-gray-700 mb-1.5">시작 시간</p>
            <Input
              type="datetime-local"
              value={manualStartedAt}
              max={new Date().toISOString().slice(0, 16)}
              onChange={(e) => setManualStartedAt(e.target.value)}
            />
          </div>
          <div>
            <p className="text-sm font-medium text-gray-700 mb-1.5">
              종료 시간 <span className="text-gray-400 text-xs">(또는 아래 분 입력)</span>
            </p>
            <Input
              type="datetime-local"
              value={manualEndedAt}
              max={new Date().toISOString().slice(0, 16)}
              onChange={(e) => setManualEndedAt(e.target.value)}
            />
          </div>
          <div>
            <p className="text-sm font-medium text-gray-700 mb-1.5">시간 (분)</p>
            <Input
              type="number"
              min={1}
              max={600}
              placeholder="예: 15"
              value={manualDuration}
              onChange={(e) =>
                setManualDuration(e.target.value === "" ? "" : Number(e.target.value))
              }
            />
          </div>
        </div>
      )}

      {/* 메모 — 모든 모드 공통 */}
      <div>
        <p className="text-sm font-medium text-gray-700 mb-1.5">메모 (선택)</p>
        <Input
          placeholder="메모를 입력하세요"
          value={memo}
          onChange={(e) => setMemo(e.target.value)}
        />
      </div>

      {/* 수동 입력 모드만 저장 버튼 (다른 모드는 자체 버튼 사용) */}
      {mode === "manual" && (
        <Button
          onClick={handleManualSave}
          disabled={isPending}
          className="w-full h-14 text-lg bg-green-500 hover:bg-green-600"
        >
          {isPending ? "저장 중..." : "저장"}
        </Button>
      )}
    </div>
  );
}
