"use client";

import { Star, Zap, Timer, PenLine } from "lucide-react";
import {
  type RecordingActivity,
  type RecordingMode,
  useRecordingPreferencesStore,
} from "@/shared/stores/recordingPreferencesStore";
import { cn } from "@/lib/utils";

interface ModeToggleProps {
  activity: RecordingActivity;
  mode: RecordingMode;
  onChange: (mode: RecordingMode) => void;
  availableModes?: RecordingMode[];
}

const MODE_INFO: Record<
  RecordingMode,
  { label: string; icon: typeof Zap; desc: string }
> = {
  now: { label: "지금 기록", icon: Zap, desc: "1탭 즉시 저장" },
  timer: { label: "타이머", icon: Timer, desc: "시작·정지 측정" },
  manual: { label: "수동 입력", icon: PenLine, desc: "시간 직접 입력" },
};

const ALL_MODES: RecordingMode[] = ["now", "timer", "manual"];

export function ModeToggle({
  activity,
  mode,
  onChange,
  availableModes = ALL_MODES,
}: ModeToggleProps) {
  const { defaultModes, setDefaultMode } = useRecordingPreferencesStore();
  const isCurrentDefault = defaultModes[activity] === mode;

  return (
    <div className="space-y-2">
      <div className="flex gap-1.5 bg-gray-100 p-1 rounded-xl">
        {availableModes.map((m) => {
          const info = MODE_INFO[m];
          const Icon = info.icon;
          const isActive = mode === m;
          return (
            <button
              key={m}
              onClick={() => onChange(m)}
              className={cn(
                "flex-1 flex flex-col items-center gap-0.5 py-2 px-1 rounded-lg transition-all text-xs",
                isActive
                  ? "bg-white shadow-sm text-blue-600 font-semibold"
                  : "text-gray-500 hover:text-gray-700"
              )}
            >
              <Icon className="w-4 h-4" />
              <span>{info.label}</span>
            </button>
          );
        })}
      </div>

      {!isCurrentDefault && (
        <button
          onClick={() => setDefaultMode(activity, mode)}
          className="w-full flex items-center justify-center gap-1.5 text-xs text-gray-500 hover:text-blue-600 py-1"
        >
          <Star className="w-3 h-3" />
          <span>이 모드를 기본으로 설정</span>
        </button>
      )}
      {isCurrentDefault && (
        <div className="w-full flex items-center justify-center gap-1.5 text-xs text-blue-500 py-1">
          <Star className="w-3 h-3 fill-blue-500" />
          <span>기본 모드</span>
        </div>
      )}
    </div>
  );
}
