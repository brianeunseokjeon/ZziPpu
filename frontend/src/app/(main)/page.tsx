"use client";

import { useRouter } from "next/navigation";
import { Milk, Moon, Baby, Gamepad2, ChevronRight } from "lucide-react";
import { Card, CardContent } from "@/shared/components/ui/card";
import { Button } from "@/shared/components/ui/button";
import { DailySummaryCard } from "@/features/dashboard/components/DailySummaryCard";
import { useUIStore } from "@/shared/stores/uiStore";
import { useTimerStore } from "@/shared/stores/timerStore";
import { useTimer } from "@/shared/hooks/useTimer";
import { formatTime } from "@/lib/date-utils";
import { useFeedings } from "@/features/feeding/api/feedingApi";
import { getDateString } from "@/lib/date-utils";

function SleepStatusCard() {
  const timer = useTimer("sleep");

  function formatElapsed(secs: number) {
    const h = Math.floor(secs / 3600);
    const m = Math.floor((secs % 3600) / 60);
    const s = secs % 60;
    return `${String(h).padStart(2, "0")}:${String(m).padStart(2, "0")}:${String(s).padStart(2, "0")}`;
  }

  if (!timer.isRunning) return null;

  return (
    <Card className="border-purple-200 bg-purple-50">
      <CardContent className="pt-4">
        <div className="flex items-center justify-between">
          <div className="flex items-center gap-3">
            <div className="w-10 h-10 rounded-full bg-purple-100 flex items-center justify-center">
              <Moon className="w-5 h-5 text-purple-500" fill="currentColor" />
            </div>
            <div>
              <p className="text-sm font-semibold text-purple-700">수면 중</p>
              <p className="text-2xl font-bold tabular-nums text-purple-900">
                {formatElapsed(timer.elapsedSeconds)}
              </p>
            </div>
          </div>
        </div>
      </CardContent>
    </Card>
  );
}

function LastFeedingCard() {
  const { activeBabyId } = useUIStore();
  const today = getDateString(new Date());
  const { data: feedings } = useFeedings(activeBabyId, today);

  if (!feedings || feedings.length === 0) return null;

  const last = [...feedings].sort(
    (a, b) => new Date(b.startedAt).getTime() - new Date(a.startedAt).getTime()
  )[0];

  const minutesAgo = Math.round(
    (Date.now() - new Date(last.startedAt).getTime()) / 60000
  );

  return (
    <Card className="border-blue-200 bg-blue-50">
      <CardContent className="pt-4">
        <div className="flex items-center justify-between">
          <div className="flex items-center gap-3">
            <div className="w-10 h-10 rounded-full bg-blue-100 flex items-center justify-center text-xl">
              🍼
            </div>
            <div>
              <p className="text-xs text-blue-500 font-medium">마지막 수유</p>
              <p className="text-sm font-semibold text-blue-900">
                {formatTime(last.startedAt)}
                {last.amountMl && ` · ${last.amountMl}ml`}
              </p>
              <p className="text-xs text-blue-400">
                {minutesAgo < 60
                  ? `${minutesAgo}분 전`
                  : `${Math.floor(minutesAgo / 60)}시간 ${minutesAgo % 60}분 전`}
              </p>
            </div>
          </div>
        </div>
      </CardContent>
    </Card>
  );
}

const QUICK_ACTIONS = [
  { icon: Milk, label: "수유", path: "/record/feeding", color: "text-blue-500 bg-blue-50" },
  { icon: Baby, label: "배변", path: "/record/diaper", color: "text-orange-500 bg-orange-50" },
  { icon: Moon, label: "수면", path: "/record/sleep", color: "text-purple-500 bg-purple-50" },
  { icon: Gamepad2, label: "놀이", path: "/record/play", color: "text-green-500 bg-green-50" },
];

export default function HomePage() {
  const router = useRouter();

  return (
    <div className="space-y-4">
      <SleepStatusCard />
      <LastFeedingCard />

      <div>
        <h2 className="text-sm font-semibold text-gray-500 mb-2">오늘 요약</h2>
        <DailySummaryCard />
      </div>

      <div>
        <h2 className="text-sm font-semibold text-gray-500 mb-2">빠른 기록</h2>
        <div className="grid grid-cols-4 gap-3">
          {QUICK_ACTIONS.map(({ icon: Icon, label, path, color }) => (
            <button
              key={path}
              onClick={() => router.push(path)}
              className={`flex flex-col items-center gap-2 py-4 rounded-2xl ${color} transition-all active:scale-95`}
            >
              <Icon className="w-6 h-6" />
              <span className="text-xs font-medium">{label}</span>
            </button>
          ))}
        </div>
      </div>

      <div>
        <button
          onClick={() => router.push("/record")}
          className="w-full flex items-center justify-between p-4 bg-white rounded-2xl border border-gray-100 hover:bg-gray-50 transition-colors"
        >
          <span className="text-sm font-medium text-gray-700">전체 기록 보기</span>
          <ChevronRight className="w-4 h-4 text-gray-400" />
        </button>
      </div>
    </div>
  );
}
