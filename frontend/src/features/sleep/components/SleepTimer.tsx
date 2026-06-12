"use client";

import { useEffect, useState } from "react";
import { Moon, Play, Pause, CheckCircle2, RotateCcw } from "lucide-react";
import { Button } from "@/shared/components/ui/button";
import { Input } from "@/shared/components/ui/input";
import { useActivityTimer, formatElapsed } from "@/shared/hooks/useActivityTimer";
import { useRecordingPreferencesStore, type RecordingMode } from "@/shared/stores/recordingPreferencesStore";
import { useCreateSleep } from "../api/sleepApi";
import { useUIStore } from "@/shared/stores/uiStore";
import { ModeToggle } from "@/features/recording/components/ModeToggle";
import { nowDatetimeLocal, datetimeLocalToISO } from "@/lib/date-utils";

/**
 * 수면 기록 폼. 3-mode 토글 + 일시정지/재개 가능한 타이머.
 *
 * 기존 서버 측 `useStartSleep/useEndSleep` 흐름은 제거하고, 클라이언트 타이머가
 * 정확한 시작·종료 시각을 측정한 뒤 `useCreateSleep`로 한번에 저장 (PlayForm 패턴).
 * 까먹어도 ActiveSessionBanner 가 모든 화면에서 알림.
 */
export function SleepTimer() {
  const { activeBabyId } = useUIStore();
  const { mutateAsync: createSleep, isPending } = useCreateSleep();
  const timer = useActivityTimer("sleep");
  const defaultMode = useRecordingPreferencesStore((s) => s.defaultModes.sleep);

  const [mode, setMode] = useState<RecordingMode>(
    timer.isActive ? "timer" : defaultMode
  );

  useEffect(() => {
    if (timer.isActive) setMode("timer");
  }, [timer.isActive]);

  const [memo, setMemo] = useState("");
  const [manualStartedAt, setManualStartedAt] = useState("");
  const [manualEndedAt, setManualEndedAt] = useState("");

  async function handleNowRecord() {
    // 수면을 1탭으로 기록하는 건 부자연스러우니 "지금 시작"으로 처리
    timer.start({ babyId: activeBabyId, memo });
    setMode("timer");
  }

  async function handleTimerFinish() {
    const finished = timer.finish();
    if (!finished) return;
    try {
      await createSleep({
        babyId: activeBabyId,
        startedAt: finished.startedAt.toISOString(),
        endedAt: finished.endedAt.toISOString(),
        memo: memo || undefined,
      });
      setMemo("");
    } catch {
      // onError 토스트 처리
    }
  }

  async function handleManualSave() {
    if (!manualStartedAt || !manualEndedAt) {
      alert("시작·종료 시간을 모두 입력해주세요");
      return;
    }
    const startedAtISO = datetimeLocalToISO(manualStartedAt);
    const endedAtISO = datetimeLocalToISO(manualEndedAt);
    if (new Date(endedAtISO) <= new Date(startedAtISO)) {
      alert("종료 시간이 시작 시간보다 뒤여야 합니다");
      return;
    }
    try {
      await createSleep({
        babyId: activeBabyId,
        startedAt: startedAtISO,
        endedAt: endedAtISO,
        memo: memo || undefined,
      });
      setMemo("");
      setManualStartedAt("");
      setManualEndedAt("");
    } catch {
      // onError 토스트 처리
    }
  }

  const isSleeping = timer.isActive && !timer.isPaused;

  return (
    <div className="space-y-5">
      <ModeToggle activity="sleep" mode={mode} onChange={setMode} />

      {/* ⚡ 지금 기록 모드 → 사실상 "지금 시작" */}
      {mode === "now" && !timer.isActive && (
        <div className="bg-purple-50 rounded-2xl p-4 space-y-3 border border-purple-100">
          <p className="text-sm text-purple-700">
            아기가 막 잠들었나요? 지금부터 시간을 잽니다.
          </p>
          <Button
            onClick={handleNowRecord}
            className="w-full h-14 text-lg bg-purple-500 hover:bg-purple-600"
          >
            <Moon className="w-5 h-5 mr-2" />
            지금 자기 시작
          </Button>
        </div>
      )}

      {/* ⏱ 타이머 모드 (또는 진행 중 세션) */}
      {(mode === "timer" || (mode === "now" && timer.isActive)) && (
        <div className="flex flex-col items-center py-6 gap-5">
          <div
            className={`w-48 h-48 rounded-full flex flex-col items-center justify-center shadow-lg transition-all ${
              isSleeping
                ? "bg-gradient-to-br from-purple-400 to-purple-600"
                : timer.isPaused
                ? "bg-gradient-to-br from-gray-300 to-gray-400"
                : "bg-gradient-to-br from-gray-100 to-gray-200"
            }`}
          >
            <Moon
              className={`w-10 h-10 mb-2 ${
                timer.isActive ? "text-white" : "text-gray-400"
              }`}
              fill={timer.isActive ? "currentColor" : "none"}
            />
            <span
              className={`text-3xl font-bold tabular-nums tracking-tight ${
                timer.isActive ? "text-white" : "text-gray-500"
              }`}
            >
              {formatElapsed(timer.elapsedMs)}
            </span>
            {isSleeping && (
              <span className="text-purple-100 text-xs mt-1">수면 중</span>
            )}
            {timer.isPaused && (
              <span className="text-gray-100 text-xs mt-1">일시정지</span>
            )}
          </div>

          <div className="flex gap-3 flex-wrap justify-center">
            {!timer.isActive ? (
              <Button
                onClick={handleNowRecord}
                className="px-8 h-12 bg-purple-500 hover:bg-purple-600 flex items-center gap-2"
              >
                <Play className="w-4 h-4" />
                수면 시작
              </Button>
            ) : (
              <>
                {timer.isPaused ? (
                  <Button
                    onClick={timer.resume}
                    className="px-5 bg-purple-500 hover:bg-purple-600 flex items-center gap-2"
                  >
                    <Play className="w-4 h-4" />
                    재개
                  </Button>
                ) : (
                  <Button
                    onClick={timer.pause}
                    variant="outline"
                    className="px-5 border-purple-300 text-purple-600 flex items-center gap-2"
                  >
                    <Pause className="w-4 h-4" />
                    일시정지
                  </Button>
                )}
                <Button
                  onClick={handleTimerFinish}
                  disabled={isPending}
                  className="px-5 bg-blue-500 hover:bg-blue-600 flex items-center gap-2"
                >
                  <CheckCircle2 className="w-4 h-4" />
                  완료
                </Button>
                <Button
                  onClick={timer.cancel}
                  variant="ghost"
                  size="sm"
                  title="취소"
                >
                  <RotateCcw className="w-4 h-4 text-gray-400" />
                </Button>
              </>
            )}
          </div>

          {timer.session && (
            <p className="text-sm text-gray-400">
              시작: {new Date(timer.session.startedAt).toLocaleTimeString("ko-KR", {
                hour: "2-digit",
                minute: "2-digit",
              })}
            </p>
          )}
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
              max={nowDatetimeLocal()}
              onChange={(e) => setManualStartedAt(e.target.value)}
            />
          </div>
          <div>
            <p className="text-sm font-medium text-gray-700 mb-1.5">종료 시간</p>
            <Input
              type="datetime-local"
              value={manualEndedAt}
              max={nowDatetimeLocal()}
              onChange={(e) => setManualEndedAt(e.target.value)}
            />
          </div>
          <Button
            onClick={handleManualSave}
            disabled={isPending}
            className="w-full h-12 bg-purple-500 hover:bg-purple-600"
          >
            {isPending ? "저장 중..." : "저장"}
          </Button>
        </div>
      )}

      {/* 메모 — 공통 */}
      <div>
        <p className="text-sm font-medium text-gray-700 mb-1.5">메모 (선택)</p>
        <Input
          placeholder="메모를 입력하세요"
          value={memo}
          onChange={(e) => setMemo(e.target.value)}
        />
      </div>
    </div>
  );
}
