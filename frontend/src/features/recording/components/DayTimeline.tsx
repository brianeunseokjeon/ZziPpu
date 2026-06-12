"use client";

/**
 * DayTimeline — 한 날짜의 기록을 시간순 텍스트 리스트로 표시.
 *
 * 레이아웃:
 *   [시간]  [분유 100ml]  [✏️]
 *           [소변]        [✏️]
 *   [시간]  [수면 시작]   [✏️]
 *
 * - 같은 1분 내 기록은 같은 시간 블록에 묶임
 * - 묶음 내 순서: 분유/모유 → 소변/대변 → 수면 → 놀이
 * - ✏️ 탭 → RecordEditSheet (수정 + 삭제)
 */

import { useState } from "react";
import { Pencil } from "lucide-react";
import { useDayRecords } from "../hooks/useDayRecords";
import { RecordEditSheet } from "./RecordEditSheet";
import { formatTime, formatDuration, todayDateString } from "@/lib/date-utils";
import type { TimelineRecord } from "./RecordPopover";

interface Props {
  babyId: string;
  date: string; // YYYY-MM-DD
}

/* ─── 카테고리 우선순위 (분유/모유→배변→수면→놀이) ────────── */

const CATEGORY_ORDER: Record<string, number> = {
  formula: 0,
  breast_left: 0,
  breast_right: 0,
  breast_both: 0,
  pee: 1,
  poo: 1,
  both: 1,
  sleep: 2,
  play: 3,
};

function categoryKey(record: TimelineRecord): number {
  if (record.kind === "feeding") return CATEGORY_ORDER[record.type] ?? 0;
  if (record.kind === "diaper") return CATEGORY_ORDER[record.type] ?? 1;
  if (record.kind === "sleep") return 2;
  if (record.kind === "play") return 3;
  return 9;
}

/* ─── 텍스트 변환 ────────────────────────────────────────── */

function feedingLabel(f: { feedingType: string; amountMl?: number | null; durationMinutes?: number | null }): string {
  switch (f.feedingType) {
    case "formula":      return f.amountMl ? `분유 ${f.amountMl}ml` : "분유";
    case "breast_left":  return f.durationMinutes ? `모유 왼쪽 (${f.durationMinutes}분)` : "모유 왼쪽";
    case "breast_right": return f.durationMinutes ? `모유 오른쪽 (${f.durationMinutes}분)` : "모유 오른쪽";
    case "breast_both":  return f.durationMinutes ? `모유 양쪽 (${f.durationMinutes}분)` : "모유 양쪽";
    default:             return "수유";
  }
}

function diaperLabel(d: { diaperType: string }): string {
  switch (d.diaperType) {
    case "pee":  return "소변";
    case "poo":  return "대변";
    case "both": return "소변 + 대변";
    default:     return "배변";
  }
}

function sleepLabel(s: { durationMinutes?: number | null; endedAt?: string | null }): string {
  if (s.endedAt && s.durationMinutes != null) return `수면 (${formatDuration(s.durationMinutes)})`;
  return "수면 시작";
}

function playLabel(p: { playType: string; durationMinutes: number; endedAt?: string | null }): string {
  const names: Record<string, string> = { tummy_time: "터미타임", free_play: "자유놀이", sensory_play: "감각놀이" };
  const name = names[p.playType] ?? "터미타임";
  if (p.endedAt && p.durationMinutes > 0) return `${name} (${formatDuration(p.durationMinutes)})`;
  return `${name} 시작`;
}

/* ─── 색 도트 ────────────────────────────────────────────── */

const DOTS: Record<string, string> = {
  formula: "bg-blue-500", breast_left: "bg-pink-400", breast_right: "bg-pink-400", breast_both: "bg-pink-400",
  pee: "bg-cyan-400", poo: "bg-yellow-500", both: "bg-orange-400",
  sleep: "bg-purple-400", play: "bg-green-400",
};

function dotClass(record: TimelineRecord): string {
  if (record.kind === "feeding") return DOTS[record.type] ?? "bg-gray-300";
  if (record.kind === "diaper")  return DOTS[record.type] ?? "bg-gray-300";
  if (record.kind === "sleep")   return DOTS.sleep;
  if (record.kind === "play")    return DOTS.play;
  return "bg-gray-300";
}

/* ─── 통합 아이템 ────────────────────────────────────────── */

interface FlatItem {
  ts: number;
  record: TimelineRecord;
  label: string;
  dot: string;
  catOrder: number;
}

/* ─── 1분 단위 그루핑 ─────────────────────────────────── */

interface Group {
  minuteKey: number;
  ts: number;               // 그룹 내 가장 이른 시각
  items: FlatItem[];        // catOrder 기준 정렬된
}

function groupByMinute(items: FlatItem[]): Group[] {
  const map = new Map<number, Group>();
  for (const item of items) {
    const key = Math.floor(item.ts / 60000);
    if (!map.has(key)) map.set(key, { minuteKey: key, ts: item.ts, items: [] });
    map.get(key)!.items.push(item);
  }
  // 각 그룹 내 카테고리 순 정렬
  for (const g of map.values()) {
    g.items.sort((a, b) => a.catOrder - b.catOrder || a.ts - b.ts);
  }
  // 그룹은 최신 시각 먼저 (내림차순) — 피드형 표시
  return Array.from(map.values()).sort((a, b) => b.ts - a.ts);
}

/* ─── 메인 ─────────────────────────────────────────────── */

export function DayTimeline({ babyId, date }: Props) {
  const { feedings, diapers, sleeps, plays, isLoading, isEmpty } = useDayRecords(babyId, date);
  const [editRecord, setEditRecord] = useState<TimelineRecord | null>(null);

  const flatItems: FlatItem[] = [
    ...feedings.map((f) => {
      const r: TimelineRecord = { kind: "feeding", ...f, type: f.feedingType };
      return { ts: new Date(f.startedAt).getTime(), record: r, label: feedingLabel(f), dot: dotClass(r), catOrder: categoryKey(r) };
    }),
    ...diapers.map((d) => {
      const r: TimelineRecord = { kind: "diaper", ...d, type: d.diaperType };
      return { ts: new Date(d.recordedAt).getTime(), record: r, label: diaperLabel(d), dot: dotClass(r), catOrder: categoryKey(r) };
    }),
    ...sleeps.map((s) => {
      const r: TimelineRecord = { kind: "sleep", ...s };
      return { ts: new Date(s.startedAt).getTime(), record: r, label: sleepLabel(s), dot: dotClass(r), catOrder: 2 };
    }),
    ...plays.map((p) => {
      const r: TimelineRecord = { kind: "play", ...p };
      return { ts: new Date(p.startedAt).getTime(), record: r, label: playLabel(p), dot: dotClass(r), catOrder: 3 };
    }),
  ];

  const groups = groupByMinute(flatItems);

  // 초기 로딩(이전 데이터 없음)에만 스켈레톤. keepPreviousData 로 날짜 전환 시엔
  // 이전 데이터가 유지되므로 isLoading=false → 깜빡임 없이 부드럽게 교체된다.
  if (isLoading) {
    return (
      <div className="py-3 px-1 space-y-2.5 animate-pulse">
        {[0, 1, 2].map((i) => (
          <div key={i} className="flex items-center gap-2.5">
            <div className="w-10 h-3 rounded bg-gray-100" />
            <div className="w-2 h-2 rounded-full bg-gray-200" />
            <div className="h-3 rounded bg-gray-100" style={{ width: `${50 + i * 12}%` }} />
          </div>
        ))}
      </div>
    );
  }

  if (isEmpty) {
    return <div className="py-6 text-center text-xs text-gray-300">이 날의 기록이 없어요</div>;
  }

  // 오늘 날짜인 경우 첫 번째 그룹(가장 최신 기록)을 강조 표시
  const isToday = date === todayDateString();

  return (
    <>
      <div className="divide-y divide-gray-50">
        {groups.map((group, groupIndex) => {
          const isNewest = isToday && groupIndex === 0;
          const timeStr = formatTime(new Date(group.ts));
          return (
            <div
              key={group.minuteKey}
              className={`flex gap-3 px-4 py-2.5 ${isNewest ? "bg-blue-50/70 border-l-[3px] border-blue-400" : ""}`}
            >
              {/* 시간 — 그룹 상단 정렬 */}
              <div className={`w-16 flex-shrink-0 font-mono leading-[1.8rem] select-none ${isNewest ? "text-[11px] text-blue-500 font-bold" : "text-[11px] text-gray-400"}`}>
                {timeStr}
                {isNewest && (
                  <div className="text-[9px] text-blue-400 font-medium leading-tight -mt-0.5">최신</div>
                )}
              </div>

              {/* 활동 목록 (카테고리 순 세로 배열) */}
              <div className="flex-1 space-y-0.5">
                {group.items.map((item) => (
                  <div
                    key={item.record.id}
                    className="flex items-center justify-between min-h-[1.8rem]"
                  >
                    <div className="flex items-center gap-2 flex-1">
                      <span className={`rounded-full flex-shrink-0 ${item.dot} ${isNewest ? "w-2 h-2" : "w-1.5 h-1.5"}`} />
                      <span className={`text-sm ${isNewest ? "text-gray-900 font-semibold" : "text-gray-800"}`}>
                        {item.label}
                      </span>
                    </div>
                    <button
                      onClick={() => setEditRecord(item.record)}
                      className="ml-2 p-1.5 text-gray-300 hover:text-blue-400 active:text-blue-500 rounded-lg transition-colors"
                      aria-label="수정"
                    >
                      <Pencil className="w-3.5 h-3.5" />
                    </button>
                  </div>
                ))}
              </div>
            </div>
          );
        })}
      </div>

      <RecordEditSheet key={editRecord?.id ?? ""} record={editRecord} onClose={() => setEditRecord(null)} />
    </>
  );
}
