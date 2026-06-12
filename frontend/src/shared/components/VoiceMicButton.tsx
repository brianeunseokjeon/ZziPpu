"use client";

import { useState } from "react";
import { Mic, MicOff } from "lucide-react";
import { useRouter } from "next/navigation";
import { useVoiceCommand, type VoiceCommand } from "@/shared/hooks/useVoiceCommand";
import {
  useActivityTimerStore,
  type ActivityType,
} from "@/shared/stores/activityTimerStore";
import { useCreateSleep } from "@/features/sleep/api/sleepApi";
import { useCreatePlay } from "@/features/play/api/playApi";
import { useCreateFeeding } from "@/features/feeding/api/feedingApi";
import { useUIStore } from "@/shared/stores/uiStore";
import { FeedingType } from "@/features/feeding/types/feeding";

/**
 * QuickActionFAB 옆에 위치하는 마이크 버튼.
 * 탭 → 한국어 1회 듣기 → 명령 매칭 → 타이머 시작/종료/일시정지/재개.
 *
 * 지원: Chrome/Edge/Safari iOS 14.5+
 * 미지원: Firefox 등 → 버튼 표시 안 됨
 *
 * Hot-word(시리처럼) 모드는 Phase 7.B (Capacitor 이후).
 */
export function VoiceMicButton() {
  const router = useRouter();
  const store = useActivityTimerStore();
  const { activeBabyId } = useUIStore();
  const { mutateAsync: createSleep } = useCreateSleep();
  const { mutateAsync: createPlay } = useCreatePlay();
  const { mutateAsync: createFeeding } = useCreateFeeding();
  const [toast, setToast] = useState<{ kind: "ok" | "err"; msg: string } | null>(null);

  function showToast(kind: "ok" | "err", msg: string) {
    setToast({ kind, msg });
    setTimeout(() => setToast(null), 3000);
  }

  async function handleFinish(activity: ActivityType) {
    const finished = store.finishSession(activity);
    if (!finished) return false;
    try {
      const startedAtISO = finished.startedAt.toISOString();
      const endedAtISO = finished.endedAt.toISOString();
      if (activity === "sleep") {
        await createSleep({
          babyId: activeBabyId,
          startedAt: startedAtISO,
          endedAt: endedAtISO,
          memo: finished.meta.memo,
        });
      } else if (activity === "play") {
        await createPlay({
          babyId: activeBabyId,
          playType: (finished.meta.playType as "tummy_time") || "tummy_time",
          durationMinutes: finished.durationMinutes,
          startedAt: startedAtISO,
          endedAt: endedAtISO,
          memo: finished.meta.memo,
        });
      } else if (activity === "feeding") {
        const ft = (finished.meta.feedingType || "breast_both") as
          | "breast_left" | "breast_right" | "breast_both";
        await createFeeding({
          babyId: activeBabyId,
          feedingType:
            ft === "breast_left" ? FeedingType.BreastLeft :
            ft === "breast_right" ? FeedingType.BreastRight :
            FeedingType.BreastBoth,
          durationMinutes: finished.durationMinutes,
          startedAt: startedAtISO,
          memo: finished.meta.memo,
        });
      }
      return true;
    } catch (e) {
      // 실패 시 세션 복원
      store.startSession(activity, finished.meta);
      showToast("err", `저장 실패: ${e instanceof Error ? e.message : String(e)}`);
      return false;
    }
  }

  function findActiveType(): ActivityType | null {
    const s = store.sessions;
    return s.sleep ? "sleep" : s.play ? "play" : s.feeding ? "feeding" : null;
  }

  const labelMap: Record<ActivityType, string> = {
    sleep: "수면",
    play: "터미타임",
    feeding: "수유",
  };

  async function handleCommand(cmd: VoiceCommand) {
    if (cmd.action === "start" && cmd.activity) {
      if (store.getSession(cmd.activity)) {
        showToast("err", `이미 ${labelMap[cmd.activity]} 진행 중입니다`);
        return;
      }
      store.startSession(cmd.activity, { ...cmd.meta, babyId: activeBabyId });
      const isTummy = cmd.meta?.playType === "tummy_time";
      showToast("ok", `${isTummy ? "터미타임" : labelMap[cmd.activity]} 시작했어요`);
      // 해당 폼으로 이동 안 하고 그냥 배너에서 보임 (사용자가 멀티태스킹 중일 수 있음)
      return;
    }
    if (cmd.action === "finish") {
      const target = cmd.activity ?? findActiveType();
      if (!target) {
        showToast("err", "진행 중인 활동이 없습니다");
        return;
      }
      const ok = await handleFinish(target);
      if (ok) showToast("ok", `${labelMap[target]} 기록 저장 완료`);
      return;
    }
    if (cmd.action === "pause") {
      const target = cmd.activity ?? findActiveType();
      if (!target) {
        showToast("err", "일시정지할 활동이 없습니다");
        return;
      }
      store.pauseSession(target);
      showToast("ok", `${labelMap[target]} 일시정지`);
      return;
    }
    if (cmd.action === "resume") {
      const target = cmd.activity ?? findActiveType();
      if (!target) {
        showToast("err", "재개할 활동이 없습니다");
        return;
      }
      store.resumeSession(target);
      showToast("ok", `${labelMap[target]} 재개`);
      return;
    }
    if (cmd.action === "cancel") {
      const target = cmd.activity ?? findActiveType();
      if (!target) {
        showToast("err", "취소할 활동이 없습니다");
        return;
      }
      store.cancelSession(target);
      showToast("ok", `${labelMap[target]} 취소됨`);
    }
  }

  const voice = useVoiceCommand({
    onCommand: handleCommand,
    onError: (m) => showToast("err", m),
    onUnrecognized: (text) =>
      showToast(
        "err",
        text
          ? `"${text}" — 인식 못함. 예: "터미타임 시작" / "수면 종료"`
          : "음성을 인식하지 못했습니다"
      ),
  });

  // Suppress unused router warning - reserved for future use
  void router;

  if (!voice.isSupported) return null;

  return (
    <>
      <button
        onClick={voice.isListening ? voice.stop : voice.start}
        className={`w-12 h-12 rounded-full shadow-lg flex items-center justify-center transition-all ${
          voice.isListening
            ? "bg-red-500 text-white animate-pulse"
            : "bg-white border border-gray-200 text-gray-600 hover:bg-gray-50"
        }`}
        aria-label={voice.isListening ? "음성 인식 중지" : "음성 명령"}
        title='예: "터미타임 시작", "수면 종료", "일시정지"'
      >
        {voice.isListening ? <Mic className="w-5 h-5" /> : <MicOff className="w-5 h-5" />}
      </button>

      {/* 토스트 */}
      {toast && (
        <div
          className={`fixed bottom-36 left-1/2 -translate-x-1/2 z-[60] px-4 py-2.5 rounded-xl shadow-lg text-sm font-medium ${
            toast.kind === "ok" ? "bg-green-500 text-white" : "bg-red-500 text-white"
          }`}
        >
          {toast.kind === "ok" ? "✅" : "⚠️"} {toast.msg}
        </div>
      )}
    </>
  );
}
