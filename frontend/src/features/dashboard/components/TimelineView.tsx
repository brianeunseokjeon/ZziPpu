"use client";

import { useFeedings } from "@/features/feeding/api/feedingApi";
import { useDiapers } from "@/features/diaper/api/diaperApi";
import { useSleepRecords } from "@/features/sleep/api/sleepApi";
import { usePlayRecords } from "@/features/play/api/playApi";
import { useUIStore } from "@/shared/stores/uiStore";
import { formatTime } from "@/lib/date-utils";
import { FeedingType } from "@/features/feeding/types/feeding";
import { DiaperType } from "@/features/diaper/types/diaper";
import { Card, CardHeader, CardTitle, CardContent } from "@/shared/components/ui/card";

interface TimelineEvent {
  time: Date;
  emoji: string;
  label: string;
  sub?: string;
  color: string;
}

export function TimelineView() {
  const { activeBabyId, selectedDate } = useUIStore();
  const { data: feedings } = useFeedings(activeBabyId, selectedDate);
  const { data: diapers } = useDiapers(activeBabyId, selectedDate);
  const { data: sleeps } = useSleepRecords(activeBabyId, selectedDate);
  const { data: plays } = usePlayRecords(activeBabyId, selectedDate);

  const events: TimelineEvent[] = [];

  feedings?.forEach((f) => {
    const isFormula = f.type === FeedingType.Formula;
    events.push({
      time: new Date(f.startedAt),
      emoji: "🍼",
      label: isFormula ? `분유 ${f.amountMl}ml` : `모유`,
      color: "border-blue-300 bg-blue-50",
    });
  });

  diapers?.forEach((d) => {
    const isPoop = d.type === DiaperType.Poop || d.type === DiaperType.Both;
    events.push({
      time: new Date(d.occurredAt),
      emoji: isPoop ? "💩" : "💧",
      label: d.type === DiaperType.Pee ? "소변" : d.type === DiaperType.Poop ? "대변" : "소변+대변",
      color: "border-orange-300 bg-orange-50",
    });
  });

  sleeps?.forEach((s) => {
    events.push({
      time: new Date(s.startedAt),
      emoji: "😴",
      label: "수면 시작",
      sub: s.endedAt ? `종료 ${formatTime(s.endedAt)}` : "진행 중",
      color: "border-purple-300 bg-purple-50",
    });
  });

  plays?.forEach((p) => {
    events.push({
      time: new Date(p.startedAt),
      emoji: p.playType === "tummy_time" ? "🤸" : p.playType === "free_play" ? "🎈" : "🎵",
      label: p.playType === "tummy_time" ? "터미타임" : p.playType === "free_play" ? "자유놀이" : "감각놀이",
      sub: `${p.durationMinutes}분`,
      color: "border-green-300 bg-green-50",
    });
  });

  events.sort((a, b) => b.time.getTime() - a.time.getTime());

  return (
    <Card>
      <CardHeader>
        <CardTitle className="text-base">📋 오늘의 타임라인</CardTitle>
      </CardHeader>
      <CardContent>
        {events.length === 0 ? (
          <div className="text-center py-6 text-gray-400 text-sm">
            오늘 기록이 없어요
          </div>
        ) : (
          <div className="space-y-2">
            {events.map((e, i) => (
              <div
                key={i}
                className={`flex items-center gap-3 p-3 rounded-xl border ${e.color}`}
              >
                <span className="text-xl w-8 text-center">{e.emoji}</span>
                <div className="flex-1 min-w-0">
                  <span className="text-sm font-medium text-gray-800">{e.label}</span>
                  {e.sub && <span className="text-xs text-gray-500 ml-2">{e.sub}</span>}
                </div>
                <span className="text-xs text-gray-400 flex-shrink-0">
                  {formatTime(e.time)}
                </span>
              </div>
            ))}
          </div>
        )}
      </CardContent>
    </Card>
  );
}
