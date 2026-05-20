"use client";

/**
 * DayTimeline — 한 날짜의 24시간 세로 그리드.
 *
 * 좌측 시간 라벨(0, 6, 12, 18시) + 우측 4개 레인:
 *   레인 1: 수면 (보라 막대)
 *   레인 2: 놀이 (초록 막대)
 *   레인 3: 수유 (분유=파란 점 / 모유=핑크 점 + 막대)
 *   레인 4: 배변 (소변=하늘 점 / 대변=노란 점)
 *
 * 각 막대/점 탭 시 RecordPopover.
 */

import { useState } from "react";
import { useDayRecords } from "../hooks/useDayRecords";
import { RecordPopover, type TimelineRecord } from "./RecordPopover";

const HOUR_HEIGHT = 36; // px per hour → 24h = 864px
const TOTAL_HEIGHT = HOUR_HEIGHT * 24;
const LABEL_HOURS = [0, 3, 6, 9, 12, 15, 18, 21];
const MIN_BAR_HEIGHT = 4;

interface Props {
  babyId: string;
  date: string; // YYYY-MM-DD
}

/** 한 날짜의 자정 기준 시각(local timezone)에서 분 단위로 측정 */
function minutesSinceDayStart(iso: string, dateStr: string): number {
  const recDate = new Date(iso);
  const [y, m, d] = dateStr.split("-").map(Number);
  const dayStart = new Date(y, m - 1, d, 0, 0, 0);
  const diffMs = recDate.getTime() - dayStart.getTime();
  return Math.max(0, Math.min(24 * 60, diffMs / 60000));
}

/** 그 시각이 해당 날짜 범위에 있는가? */
function isWithinDay(iso: string, dateStr: string): boolean {
  const recDate = new Date(iso);
  const [y, m, d] = dateStr.split("-").map(Number);
  const dayStart = new Date(y, m - 1, d, 0, 0, 0).getTime();
  const dayEnd = dayStart + 24 * 60 * 60 * 1000;
  return recDate.getTime() >= dayStart && recDate.getTime() < dayEnd;
}

function minutesToTop(min: number): number {
  return (min / 60) * HOUR_HEIGHT;
}

export function DayTimeline({ babyId, date }: Props) {
  const { feedings, diapers, sleeps, plays, isLoading, isEmpty } = useDayRecords(babyId, date);
  const [selected, setSelected] = useState<TimelineRecord | null>(null);

  return (
    <div className="relative bg-white rounded-2xl border border-gray-100 overflow-hidden">
      {/* 24h 본문 */}
      <div className="relative flex" style={{ height: TOTAL_HEIGHT }}>
        {/* 좌측 시간 라벨 */}
        <div className="relative w-10 flex-shrink-0 border-r border-gray-100 bg-gray-50/50">
          {LABEL_HOURS.map((h) => (
            <div
              key={h}
              className="absolute left-0 right-0 text-[10px] text-gray-400 text-right pr-1.5"
              style={{ top: minutesToTop(h * 60) - 6 }}
            >
              {String(h).padStart(2, "0")}시
            </div>
          ))}
        </div>

        {/* 우측 활동 영역 */}
        <div className="relative flex-1">
          {/* 시간 grid line (3h 단위) */}
          {LABEL_HOURS.map((h) => (
            <div
              key={h}
              className="absolute left-0 right-0 border-t border-dashed border-gray-100"
              style={{ top: minutesToTop(h * 60) }}
            />
          ))}

          {/* 4 레인 — 가로 split (각 레인은 25% 폭) */}
          <div className="absolute inset-0 grid grid-cols-4 gap-px">
            {/* 레인 1: 수면 */}
            <div className="relative">
              {sleeps
                .filter((s) => isWithinDay(s.startedAt, date) || (s.endedAt && isWithinDay(s.endedAt, date)))
                .map((s) => {
                  const top = minutesToTop(minutesSinceDayStart(s.startedAt, date));
                  const endTime = s.endedAt ? minutesSinceDayStart(s.endedAt, date) : 24 * 60;
                  const startTime = minutesSinceDayStart(s.startedAt, date);
                  const height = Math.max(MIN_BAR_HEIGHT, minutesToTop(endTime - startTime));
                  return (
                    <button
                      key={s.id}
                      onClick={() => setSelected({ kind: "sleep", ...s })}
                      className="absolute left-0.5 right-0.5 bg-purple-300/80 hover:bg-purple-400 rounded-md transition-colors"
                      style={{ top, height }}
                      title={`수면 ${s.durationMinutes ?? "?"}분`}
                    />
                  );
                })}
            </div>

            {/* 레인 2: 놀이 */}
            <div className="relative">
              {plays.map((p) => {
                if (!isWithinDay(p.startedAt, date)) return null;
                const startTime = minutesSinceDayStart(p.startedAt, date);
                const top = minutesToTop(startTime);
                const height = Math.max(MIN_BAR_HEIGHT, minutesToTop(p.durationMinutes));
                return (
                  <button
                    key={p.id}
                    onClick={() => setSelected({ kind: "play", ...p })}
                    className="absolute left-0.5 right-0.5 bg-green-300/80 hover:bg-green-400 rounded-md transition-colors"
                    style={{ top, height }}
                    title={`놀이 ${p.durationMinutes}분`}
                  />
                );
              })}
            </div>

            {/* 레인 3: 수유 */}
            <div className="relative">
              {feedings.map((f) => {
                if (!isWithinDay(f.startedAt, date)) return null;
                const top = minutesToTop(minutesSinceDayStart(f.startedAt, date));
                const isFormula = f.feedingType === "formula";
                const color = isFormula ? "bg-blue-500" : "bg-pink-500";
                // 모유: duration 있으면 막대, 없으면 점. 분유: 항상 점.
                if (!isFormula && f.durationMinutes && f.durationMinutes > 0) {
                  const height = Math.max(MIN_BAR_HEIGHT, minutesToTop(f.durationMinutes));
                  return (
                    <button
                      key={f.id}
                      onClick={() => setSelected({ kind: "feeding", ...f, type: f.feedingType })}
                      className={`absolute left-0.5 right-0.5 ${color} opacity-70 hover:opacity-100 rounded-md`}
                      style={{ top, height }}
                      title="모유 수유"
                    />
                  );
                }
                return (
                  <button
                    key={f.id}
                    onClick={() => setSelected({ kind: "feeding", ...f, type: f.feedingType })}
                    className={`absolute left-1/2 w-3 h-3 -translate-x-1/2 ${color} rounded-full hover:scale-125 transition-transform shadow-sm`}
                    style={{ top: top - 6 }}
                    title={isFormula ? `분유 ${f.amountMl ?? ""}ml` : "모유"}
                  />
                );
              })}
            </div>

            {/* 레인 4: 배변 */}
            <div className="relative">
              {diapers.map((d) => {
                if (!isWithinDay(d.recordedAt, date)) return null;
                const top = minutesToTop(minutesSinceDayStart(d.recordedAt, date));
                const isPee = d.diaperType === "pee";
                const color = isPee ? "bg-cyan-400" : "bg-yellow-500";
                return (
                  <button
                    key={d.id}
                    onClick={() => setSelected({ kind: "diaper", ...d, type: d.diaperType })}
                    className={`absolute left-1/2 w-3 h-3 -translate-x-1/2 ${color} rounded-full hover:scale-125 transition-transform shadow-sm`}
                    style={{ top: top - 6 }}
                    title={isPee ? "소변" : "대변"}
                  />
                );
              })}
            </div>
          </div>
        </div>
      </div>

      {/* 빈 날 안내 */}
      {!isLoading && isEmpty && (
        <div className="absolute inset-0 flex items-center justify-center pointer-events-none">
          <p className="text-xs text-gray-300">이 날의 기록이 없어요</p>
        </div>
      )}

      {/* 범례 (날짜 카드 하단) */}
      <div className="border-t border-gray-100 px-3 py-2 flex flex-wrap gap-x-3 gap-y-1 text-[10px] text-gray-500">
        <span className="flex items-center gap-1"><span className="w-2 h-2 bg-purple-300 rounded-sm" />수면</span>
        <span className="flex items-center gap-1"><span className="w-2 h-2 bg-green-300 rounded-sm" />놀이</span>
        <span className="flex items-center gap-1"><span className="w-2 h-2 bg-blue-500 rounded-full" />분유</span>
        <span className="flex items-center gap-1"><span className="w-2 h-2 bg-pink-500 rounded-full" />모유</span>
        <span className="flex items-center gap-1"><span className="w-2 h-2 bg-cyan-400 rounded-full" />소변</span>
        <span className="flex items-center gap-1"><span className="w-2 h-2 bg-yellow-500 rounded-full" />대변</span>
      </div>

      <RecordPopover record={selected} onClose={() => setSelected(null)} />
    </div>
  );
}
