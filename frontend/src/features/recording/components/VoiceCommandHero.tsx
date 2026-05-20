"use client";

/**
 * VoiceCommandHero — 홈 화면 중간 큰 마이크 버튼.
 *
 * 탭 → 한국어 1회 인식 → 타이머 시작/종료 또는 즉시 저장.
 * 지원 명령어:
 *   "분유 100" → 분유 100ml 즉시 저장
 *   "소변" / "쉬했어" → 소변 저장
 *   "대변" / "응가했어" → 대변 저장
 *   "터미타임 시작" / "수면 시작" / "놀이 시작" → 타이머 시작
 *   "수면 종료" / "놀이 끝" → 타이머 종료
 *
 * 미지원 브라우저(Firefox 등)에서는 컴포넌트 자체 숨김.
 */

import { useState } from "react";
import { Mic, MicOff } from "lucide-react";
import { useVoiceCommand } from "@/shared/hooks/useVoiceCommand";
import { useActivityTimerStore } from "@/shared/stores/activityTimerStore";
import { useUIStore } from "@/shared/stores/uiStore";
import { useQuickSave } from "../hooks/useQuickSave";
import { useRecordingDefaultsStore } from "@/shared/stores/recordingDefaultsStore";

const EXAMPLE_COMMANDS = ["분유 100", "소변", "터미타임 시작", "수면 종료"];

interface ResultCard {
  kind: "ok" | "err" | "unrecognized";
  msg: string;
}

export function VoiceCommandHero() {
  const { activeBabyId } = useUIStore();
  const timerStore = useActivityTimerStore();
  const defaults = useRecordingDefaultsStore();
  const { saveFormula, savePee, savePoo } = useQuickSave();
  const [result, setResult] = useState<ResultCard | null>(null);

  function showResult(card: ResultCard) {
    setResult(card);
    setTimeout(() => setResult(null), 2500);
  }

  const { start, stop, isListening, isSupported } = useVoiceCommand({
    onCommand: async (cmd) => {
      if (!activeBabyId) return;
      try {
        if (cmd.action === "quick_save") {
          const { saveType, amountMl } = cmd.meta ?? {};
          if (saveType === "formula" && amountMl) {
            await saveFormula(activeBabyId, amountMl);
            showResult({ kind: "ok", msg: `분유 ${amountMl}ml 기록됐어요` });
          } else if (saveType === "pee") {
            await savePee(activeBabyId);
            showResult({ kind: "ok", msg: "소변 기록됐어요" });
          } else if (saveType === "poo") {
            await savePoo(activeBabyId);
            showResult({ kind: "ok", msg: "대변 기록됐어요" });
          }
          return;
        }

        if (cmd.action === "start") {
          const type = cmd.activity ?? "play";
          timerStore.startSession(type, {
            babyId: activeBabyId,
            playType: type === "play" ? (cmd.meta?.playType ?? defaults.playType) : undefined,
          });
          const labels: Record<string, string> = { sleep: "수면", play: "놀이", feeding: "모유 수유" };
          showResult({ kind: "ok", msg: `${labels[type] ?? type} 타이머 시작됐어요` });
          return;
        }

        if (cmd.action === "finish") {
          const type = cmd.activity ?? "play";
          timerStore.finishSession(type);
          const labels: Record<string, string> = { sleep: "수면", play: "놀이", feeding: "모유 수유" };
          showResult({ kind: "ok", msg: `${labels[type] ?? type} 종료됐어요` });
          return;
        }

        if (cmd.action === "pause") {
          const active = (["sleep", "play", "feeding"] as const).find(
            (t) => timerStore.getSession(t)
          );
          if (active) {
            timerStore.pauseSession(active);
            showResult({ kind: "ok", msg: "일시정지됐어요" });
          }
          return;
        }

        if (cmd.action === "resume") {
          const paused = (["sleep", "play", "feeding"] as const).find(
            (t) => timerStore.getSession(t)?.pausedAt !== null
          );
          if (paused) {
            timerStore.resumeSession(paused);
            showResult({ kind: "ok", msg: "재개됐어요" });
          }
          return;
        }
      } catch {
        showResult({ kind: "err", msg: "저장 실패. 다시 시도해주세요." });
      }
    },
    onUnrecognized: (text) => {
      showResult({
        kind: "unrecognized",
        msg: text ? `"${text}" — 인식은 됐지만 알 수 없는 명령이에요` : "인식 못했어요. 다시 시도해주세요.",
      });
    },
    onError: () => {
      showResult({ kind: "err", msg: "음성 인식 오류. 마이크 권한을 확인해주세요." });
    },
  });

  if (!isSupported) return null;

  function handleMicClick() {
    if (isListening) {
      stop();
    } else {
      start();
    }
  }

  const resultBg: Record<ResultCard["kind"], string> = {
    ok: "bg-gray-800 text-white",
    err: "bg-red-50 text-red-700 border border-red-200",
    unrecognized: "bg-yellow-50 text-yellow-800 border border-yellow-200",
  };

  return (
    <div className="bg-gradient-to-br from-indigo-50 to-purple-50 rounded-2xl p-4 border border-indigo-100">
      <div className="flex items-center gap-4">
        {/* 큰 마이크 버튼 */}
        <button
          onClick={handleMicClick}
          className={`relative w-16 h-16 rounded-full flex items-center justify-center shadow-md transition-all active:scale-95 flex-shrink-0 ${
            isListening
              ? "bg-red-500 text-white animate-pulse"
              : "bg-indigo-500 text-white hover:bg-indigo-600"
          }`}
        >
          {isListening ? (
            <MicOff className="w-7 h-7" />
          ) : (
            <Mic className="w-7 h-7" />
          )}
        </button>

        {/* 예시 명령어 */}
        <div className="flex-1 min-w-0">
          <p className="text-xs font-semibold text-indigo-700 mb-1.5">
            {isListening ? "🎤 듣고 있어요..." : "🎤 음성으로 기록"}
          </p>
          <div className="flex flex-wrap gap-1.5">
            {EXAMPLE_COMMANDS.map((cmd) => (
              <span
                key={cmd}
                className="text-[10px] bg-white border border-indigo-100 text-indigo-500 rounded-full px-2 py-0.5"
              >
                {cmd}
              </span>
            ))}
          </div>
        </div>
      </div>

      {/* 인식 결과 카드 */}
      {result && (
        <div className={`mt-3 rounded-xl px-3 py-2 text-sm font-medium ${resultBg[result.kind]}`}>
          {result.kind === "ok" && "✅ "}
          {result.kind === "err" && "❌ "}
          {result.kind === "unrecognized" && "⚠️ "}
          {result.msg}
        </div>
      )}
    </div>
  );
}
