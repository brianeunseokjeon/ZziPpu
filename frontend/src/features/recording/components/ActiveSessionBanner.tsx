"use client";

import { useEffect, useState } from "react";
import { useRouter } from "next/navigation";
import { CheckCircle2, Pause, Play, X, Clock, AlertTriangle } from "lucide-react";
import {
  type ActiveSession,
  type ActivityType,
  useActivityTimerStore,
} from "@/shared/stores/activityTimerStore";
import { formatElapsed } from "@/shared/hooks/useActivityTimer";
import { useCreateSleep } from "@/features/sleep/api/sleepApi";
import { useCreatePlay } from "@/features/play/api/playApi";
import { useCreateFeeding } from "@/features/feeding/api/feedingApi";
import { useUIStore } from "@/shared/stores/uiStore";
import { FeedingType } from "@/features/feeding/types/feeding";
import { isoToTimeInput } from "@/lib/date-utils";

/** 진행 중인 모든 세션을 헤더 아래에 표시. 모든 페이지에서 보임. */
export function ActiveSessionBanner() {
  // 1초마다 강제 리렌더 (elapsed 업데이트)
  const [, force] = useState(0);
  useEffect(() => {
    const id = setInterval(() => force((n) => n + 1), 1000);
    return () => clearInterval(id);
  }, []);

  const sessions = useActivityTimerStore((s) => s.sessions);
  const active = [sessions.sleep, sessions.play, sessions.feeding].filter(
    (s): s is ActiveSession => s !== null
  );

  if (active.length === 0) return null;

  return (
    <div className="sticky top-14 z-20 bg-white border-b border-gray-100">
      <div className="max-w-md mx-auto px-3 py-2 space-y-1.5">
        {active.map((s) => (
          <SessionRow key={s.id} session={s} />
        ))}
      </div>
    </div>
  );
}

const TYPE_INFO: Record<
  ActivityType,
  { label: string; emoji: string; href: string; activeBg: string }
> = {
  sleep: { label: "수면", emoji: "😴", href: "/record/sleep", activeBg: "bg-purple-50 border-purple-200" },
  play: { label: "놀이", emoji: "🤸", href: "/record/play", activeBg: "bg-green-50 border-green-200" },
  feeding: { label: "수유", emoji: "🍼", href: "/record/feeding", activeBg: "bg-blue-50 border-blue-200" },
};

function SessionRow({ session }: { session: ActiveSession }) {
  const router = useRouter();
  const store = useActivityTimerStore();
  const { activeBabyId } = useUIStore();
  const createSleep = useCreateSleep();
  const createPlay = useCreatePlay();
  const createFeeding = useCreateFeeding();

  const info = TYPE_INFO[session.type];
  const elapsedMs = store.getElapsedMs(session.type);
  const isStale = elapsedMs > 24 * 60 * 60 * 1000;
  const isPaused = session.pausedAt !== null;

  const startStr = isoToTimeInput(new Date(session.startedAt).toISOString());

  async function handleFinish() {
    const finished = store.finishSession(session.type);
    if (!finished) return;

    const startedAtISO = finished.startedAt.toISOString();
    const endedAtISO = finished.endedAt.toISOString();
    const durationMinutes = finished.durationMinutes;

    try {
      if (session.type === "sleep") {
        await createSleep.mutateAsync({
          babyId: activeBabyId,
          startedAt: startedAtISO,
          endedAt: endedAtISO,
          memo: session.meta.memo,
        });
      } else if (session.type === "play") {
        await createPlay.mutateAsync({
          babyId: activeBabyId,
          playType: (session.meta.playType as "tummy_time") || "tummy_time",
          durationMinutes,
          startedAt: startedAtISO,
          endedAt: endedAtISO,
          memo: session.meta.memo,
        });
      } else if (session.type === "feeding") {
        const ft = (session.meta.feedingType || "breast_both") as
          | "breast_left"
          | "breast_right"
          | "breast_both";
        const feedingTypeEnum =
          ft === "breast_left"
            ? FeedingType.BreastLeft
            : ft === "breast_right"
            ? FeedingType.BreastRight
            : FeedingType.BreastBoth;
        await createFeeding.mutateAsync({
          babyId: activeBabyId,
          feedingType: feedingTypeEnum,
          durationMinutes,
          startedAt: startedAtISO,
          memo: session.meta.memo,
        });
      }
    } catch (e) {
      // 실패 시 세션 복원
      store.startSession(session.type, session.meta);
      alert(`기록 저장 실패: ${e instanceof Error ? e.message : String(e)}`);
    }
  }

  function handlePauseResume() {
    if (isPaused) store.resumeSession(session.type);
    else store.pauseSession(session.type);
  }

  function handleCancel() {
    if (confirm("진행 중인 기록을 취소하시겠어요? 저장되지 않습니다.")) {
      store.cancelSession(session.type);
    }
  }

  const bgClass = isStale
    ? "bg-amber-50 border-amber-200"
    : isPaused
    ? "bg-gray-50 border-gray-200"
    : info.activeBg;
  const dotClass = isPaused
    ? "bg-gray-400"
    : isStale
    ? "bg-amber-500"
    : "bg-green-500 animate-pulse";

  return (
    <div className={`flex items-center gap-2 rounded-xl border px-3 py-2 ${bgClass}`}>
      <button
        onClick={() => router.push(info.href)}
        className="flex items-center gap-2 flex-1 min-w-0 text-left"
      >
        <span className={`w-2 h-2 rounded-full ${dotClass}`} />
        <span className="text-base">{info.emoji}</span>
        <div className="flex flex-col min-w-0">
          <span className="text-sm font-semibold text-gray-800 truncate">
            {isStale && <AlertTriangle className="w-3 h-3 inline -mt-1 text-amber-500 mr-1" />}
            {info.label}
            {session.meta.playType === "tummy_time" && " (터미타임)"}
            {isPaused && <span className="text-gray-500 font-normal"> 일시정지</span>}
          </span>
          <span className="text-xs text-gray-500 tabular-nums">
            <Clock className="w-3 h-3 inline -mt-0.5 mr-0.5" />
            {formatElapsed(elapsedMs)} · {startStr} 시작
          </span>
        </div>
      </button>

      <div className="flex items-center gap-1 flex-shrink-0">
        <button
          onClick={handlePauseResume}
          className="w-8 h-8 rounded-full bg-white border border-gray-200 flex items-center justify-center text-gray-600 hover:bg-gray-50"
          aria-label={isPaused ? "재개" : "일시정지"}
        >
          {isPaused ? <Play className="w-4 h-4" /> : <Pause className="w-4 h-4" />}
        </button>
        <button
          onClick={handleFinish}
          className="w-8 h-8 rounded-full bg-green-500 text-white flex items-center justify-center hover:bg-green-600"
          aria-label="완료"
        >
          <CheckCircle2 className="w-4 h-4" />
        </button>
        <button
          onClick={handleCancel}
          className="w-8 h-8 rounded-full bg-white border border-gray-200 flex items-center justify-center text-gray-400 hover:bg-red-50 hover:text-red-500"
          aria-label="취소"
        >
          <X className="w-4 h-4" />
        </button>
      </div>
    </div>
  );
}
