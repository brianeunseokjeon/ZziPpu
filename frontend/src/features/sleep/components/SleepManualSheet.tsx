"use client";

import { useState, useMemo } from "react";
import { Loader2 } from "lucide-react";
import { Dialog } from "@/shared/components/ui/dialog";
import { TimeField } from "@/shared/components/ui/time-field";
import { useCreateSleep } from "@/features/sleep/api/sleepApi";
import { useUIStore } from "@/shared/stores/uiStore";
import { nowTimeInput, dateTimeToISO, getDateString } from "@/lib/date-utils";

interface SleepManualSheetProps {
  open: boolean;
  onClose: () => void;
  onSaved?: (msg: string) => void;
}

function toDateLabel(dateStr: string): string {
  const [y, mo, da] = dateStr.split("-").map(Number);
  const date = new Date(y, mo - 1, da);
  return new Intl.DateTimeFormat("ko-KR", {
    month: "long",
    day: "numeric",
    weekday: "short",
  }).format(date);
}

export function SleepManualSheet({ open, onClose, onSaved }: SleepManualSheetProps) {
  const { activeBabyId } = useUIStore();
  const { mutateAsync: createSleep, isPending } = useCreateSleep();

  const [dateMode, setDateMode] = useState<"yesterday" | "today">("today");
  const [startTime, setStartTime] = useState(() => nowTimeInput());
  const [endTime, setEndTime] = useState("");

  const { todayStr, yesterdayStr, startDateStr, crossMidnight, endDateStr } = useMemo(() => {
    const todayStr = getDateString(new Date());
    const yesterdayStr = getDateString(new Date(Date.now() - 86400000));
    const startDateStr = dateMode === "today" ? todayStr : yesterdayStr;
    const crossMidnight =
      endTime !== "" &&
      dateMode === "yesterday" &&
      endTime < startTime;
    const endDateStr = crossMidnight ? todayStr : startDateStr;
    return { todayStr, yesterdayStr, startDateStr, crossMidnight, endDateStr };
  }, [dateMode, startTime, endTime]);

  async function handleSave() {
    if (!activeBabyId) return;
    const startedAt = dateTimeToISO(startDateStr, startTime);
    const endedAt = endTime ? dateTimeToISO(endDateStr, endTime) : undefined;
    try {
      await createSleep({ babyId: activeBabyId, startedAt, endedAt });
      onSaved?.("수면 기록됐어요");
      onClose();
    } catch {
      // optimisticCreateOptions.onError 가 에러 토스트 처리
    }
  }

  return (
    <Dialog open={open} onClose={onClose} title="수면 직접 입력">
      <div className="space-y-4">
        {/* Date selector */}
        <div className="grid grid-cols-2 gap-2">
          {(["yesterday", "today"] as const).map((mode) => {
            const dateStr = mode === "today" ? todayStr : yesterdayStr;
            const selected = dateMode === mode;
            return (
              <button
                key={mode}
                type="button"
                onClick={() => setDateMode(mode)}
                className={`flex flex-col items-center gap-0.5 py-3 rounded-xl border transition-colors ${
                  selected
                    ? "bg-purple-50 border-purple-400 text-purple-700"
                    : "bg-white border-gray-200 text-gray-600"
                }`}
              >
                <span className="text-sm font-semibold">
                  {mode === "today" ? "오늘" : "어제"}
                </span>
                <span className="text-[11px]">{toDateLabel(dateStr)}</span>
              </button>
            );
          })}
        </div>

        <TimeField label="잠든 시각" value={startTime} onChange={setStartTime} />

        <div className="space-y-1">
          <TimeField label="깨어난 시각 (선택)" value={endTime} onChange={setEndTime} />
          <p className="text-[11px] text-gray-400 px-1">
            비워두면 진행 중 수면으로 기록돼요
          </p>
        </div>

        {crossMidnight && (
          <div className="flex items-center gap-1.5 rounded-xl bg-indigo-50 border border-indigo-100 px-3 py-2 text-xs text-indigo-700">
            🌅 자정을 넘겨 <b>오늘</b> 깨어난 걸로 기록해요
          </div>
        )}

        <button
          type="button"
          onClick={handleSave}
          disabled={isPending}
          className="w-full py-3.5 rounded-xl bg-purple-500 text-white font-semibold text-sm flex items-center justify-center gap-2 disabled:opacity-60 transition-colors"
        >
          {isPending && <Loader2 className="w-4 h-4 animate-spin" />}
          저장
        </button>
      </div>
    </Dialog>
  );
}
