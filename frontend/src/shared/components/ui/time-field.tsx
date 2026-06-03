"use client";

import { useEffect, useRef, useState } from "react";
import { Clock, Check } from "lucide-react";
import { cn } from "@/lib/utils";

/* ── "HH:MM"(24h) ↔ 표시용 변환 ── */
function parse(hhmm: string): { period: "AM" | "PM"; hour12: number; minute: number } {
  const [h, m] = (hhmm || "00:00").split(":").map(Number);
  const period = h < 12 ? "AM" : "PM";
  const hour12 = h % 12 === 0 ? 12 : h % 12;
  return { period, hour12, minute: m || 0 };
}

function build(period: "AM" | "PM", hour12: number, minute: number): string {
  let h = hour12 % 12; // 12 → 0
  if (period === "PM") h += 12;
  return `${String(h).padStart(2, "0")}:${String(minute).padStart(2, "0")}`;
}

function displayTime(hhmm: string): string {
  if (!hhmm) return "시간 선택";
  const { period, hour12, minute } = parse(hhmm);
  return `${period === "AM" ? "오전" : "오후"} ${hour12}:${String(minute).padStart(2, "0")}`;
}

const HOURS = Array.from({ length: 12 }, (_, i) => i + 1);
const MINUTES = Array.from({ length: 60 }, (_, i) => i);

interface TimeFieldProps {
  label?: string;
  value: string;
  onChange: (v: string) => void;
  className?: string;
}

/**
 * 완전 자체 구현 시간 선택기 (네이티브 input/showPicker 미사용).
 * 필드를 누르면 인라인 패널이 펼쳐지고, 오전/오후 + 시 + 분을 탭으로 고른다.
 * absolute 미사용 → 모달의 overflow에 잘리지 않음. ref-as-prop·scrollIntoView 미사용 → 환경 의존 0.
 */
export function TimeField({ label, value, onChange, className }: TimeFieldProps) {
  const [open, setOpen] = useState(false);
  const { period, hour12, minute } = parse(value);
  const rootRef = useRef<HTMLDivElement>(null);
  const hourColRef = useRef<HTMLDivElement>(null);
  const minColRef = useRef<HTMLDivElement>(null);

  // 패널이 열리면 선택된 시/분이 가운데 보이도록 각 열만 스크롤(모달은 안 움직임)
  useEffect(() => {
    if (!open) return;
    // offsetParent에 의존하지 않도록 getBoundingClientRect로 델타 계산
    const center = (col: HTMLDivElement | null) => {
      const el = col?.querySelector<HTMLElement>('[data-active="true"]');
      if (!col || !el) return;
      const colRect = col.getBoundingClientRect();
      const elRect = el.getBoundingClientRect();
      const delta = elRect.top - colRect.top - (col.clientHeight / 2 - el.clientHeight / 2);
      col.scrollTop += delta;
    };
    // 패널 레이아웃이 커밋된 다음 프레임에 스크롤
    const raf = requestAnimationFrame(() => {
      center(hourColRef.current);
      center(minColRef.current);
    });
    return () => cancelAnimationFrame(raf);
  }, [open]);

  // 바깥 클릭 시 닫기
  useEffect(() => {
    if (!open) return;
    function onDocClick(e: MouseEvent) {
      if (rootRef.current && !rootRef.current.contains(e.target as Node)) setOpen(false);
    }
    document.addEventListener("mousedown", onDocClick);
    return () => document.removeEventListener("mousedown", onDocClick);
  }, [open]);

  function set(p: "AM" | "PM", h: number, m: number) {
    onChange(build(p, h, m));
  }

  return (
    <div ref={rootRef} className={cn("space-y-1", className)}>
      {label && <p className="text-xs text-gray-500 font-medium">{label}</p>}

      <button
        type="button"
        onClick={() => setOpen((o) => !o)}
        className={cn(
          "w-full px-4 py-3.5 border rounded-xl bg-white flex items-center justify-between text-left transition-all active:scale-[0.99]",
          open ? "border-blue-400 ring-2 ring-blue-100" : "border-gray-200"
        )}
      >
        <span className="text-base font-semibold text-gray-800">{displayTime(value)}</span>
        <Clock className={cn("w-4 h-4", open ? "text-blue-500" : "text-gray-400")} />
      </button>

      {open && (
        <div className="mt-2 border border-gray-200 rounded-2xl bg-white p-3 shadow-sm">
          {/* 오전/오후 */}
          <div className="flex gap-2 mb-2">
            {(["AM", "PM"] as const).map((p) => (
              <button
                key={p}
                type="button"
                onClick={() => set(p, hour12, minute)}
                className={cn(
                  "flex-1 py-2 rounded-xl text-sm font-medium border transition-colors",
                  period === p
                    ? "bg-blue-500 text-white border-blue-500"
                    : "bg-white text-gray-600 border-gray-200"
                )}
              >
                {p === "AM" ? "오전" : "오후"}
              </button>
            ))}
          </div>

          {/* 시 / 분 */}
          <div className="flex gap-2">
            <div className="flex-1 min-w-0">
              <p className="text-[11px] text-gray-400 text-center mb-1">시</p>
              <div
                ref={hourColRef}
                className="h-40 overflow-y-auto rounded-xl bg-gray-50 border border-gray-100 py-1"
              >
                {HOURS.map((h) => (
                  <button
                    key={h}
                    type="button"
                    data-active={h === hour12}
                    onClick={() => set(period, h, minute)}
                    className={cn(
                      "w-full py-2 text-center text-sm tabular-nums transition-colors",
                      h === hour12
                        ? "bg-blue-500 text-white font-bold rounded-lg"
                        : "text-gray-700 hover:bg-gray-100"
                    )}
                  >
                    {h}
                  </button>
                ))}
              </div>
            </div>

            <div className="flex-1 min-w-0">
              <p className="text-[11px] text-gray-400 text-center mb-1">분</p>
              <div
                ref={minColRef}
                className="h-40 overflow-y-auto rounded-xl bg-gray-50 border border-gray-100 py-1"
              >
                {MINUTES.map((m) => (
                  <button
                    key={m}
                    type="button"
                    data-active={m === minute}
                    onClick={() => set(period, hour12, m)}
                    className={cn(
                      "w-full py-2 text-center text-sm tabular-nums transition-colors",
                      m === minute
                        ? "bg-blue-500 text-white font-bold rounded-lg"
                        : "text-gray-700 hover:bg-gray-100"
                    )}
                  >
                    {String(m).padStart(2, "0")}
                  </button>
                ))}
              </div>
            </div>
          </div>

          <button
            type="button"
            onClick={() => setOpen(false)}
            className="mt-3 w-full py-2.5 rounded-xl bg-blue-500 text-white text-sm font-semibold flex items-center justify-center gap-1.5 hover:bg-blue-600 transition-colors"
          >
            <Check className="w-4 h-4" /> 확인
          </button>
        </div>
      )}
    </div>
  );
}
