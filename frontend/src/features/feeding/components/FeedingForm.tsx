"use client";

import { useState } from "react";
import { Minus, Plus, ChevronDown, ChevronUp } from "lucide-react";
import { Button } from "@/shared/components/ui/button";
import { Input } from "@/shared/components/ui/input";
import { useTimer } from "@/shared/hooks/useTimer";
import { useCreateFeeding } from "../api/feedingApi";
import { FeedingType } from "../types/feeding";
import { useUIStore } from "@/shared/stores/uiStore";
import { useCreateDiaper } from "@/features/diaper/api/diaperApi";
import { DiaperType, StoolColor, StoolState } from "@/features/diaper/types/diaper";
import { STOOL_COLORS, STOOL_STATES } from "@/config/constants";
import { cn } from "@/lib/utils";

type Tab = "formula" | "breast";
type BreastSide = "left" | "right" | "both";

function formatTimerDisplay(seconds: number) {
  const h = Math.floor(seconds / 3600);
  const m = Math.floor((seconds % 3600) / 60);
  const s = seconds % 60;
  if (h > 0) {
    return `${String(h).padStart(2, "0")}:${String(m).padStart(2, "0")}:${String(s).padStart(2, "0")}`;
  }
  return `${String(m).padStart(2, "0")}:${String(s).padStart(2, "0")}`;
}

export function FeedingForm() {
  const { activeBabyId } = useUIStore();
  const { mutate: createFeeding, isPending: feedingPending } = useCreateFeeding();
  const { mutate: createDiaper, isPending: diaperPending } = useCreateDiaper();
  const timer = useTimer("feeding");

  const [tab, setTab] = useState<Tab>("formula");
  const [amountMl, setAmountMl] = useState(100);
  const [amountInput, setAmountInput] = useState("100");
  const [breastSide, setBreastSide] = useState<BreastSide>("both");
  const [memo, setMemo] = useState("");
  const [startedAt, setStartedAt] = useState(() =>
    new Date().toISOString().slice(0, 16)
  );

  // 배변 함께 기록
  const [withDiaper, setWithDiaper] = useState(false);
  const [diaperType, setDiaperType] = useState<DiaperType>(DiaperType.Pee);
  const [stoolColor, setStoolColor] = useState<StoolColor | undefined>();
  const [stoolState, setStoolState] = useState<StoolState | undefined>();

  const hasPoop = diaperType === DiaperType.Poop || diaperType === DiaperType.Both;
  const isPending = feedingPending || diaperPending;

  function adjustAmount(delta: number) {
    const next = Math.max(0, Math.min(500, amountMl + delta));
    setAmountMl(next);
    setAmountInput(String(next));
  }

  function handleAmountInput(v: string) {
    setAmountInput(v);
    const n = parseInt(v, 10);
    if (!isNaN(n)) setAmountMl(Math.max(0, Math.min(500, n)));
  }

  function getFeedingType(): FeedingType {
    if (tab === "formula") return FeedingType.Formula;
    if (breastSide === "left") return FeedingType.BreastLeft;
    if (breastSide === "right") return FeedingType.BreastRight;
    return FeedingType.BreastBoth;
  }

  function handleSave() {
    const durationSeconds =
      tab === "breast" && timer.startedAt
        ? Math.floor((Date.now() - timer.startedAt) / 1000)
        : 0;

    if (timer.isRunning) timer.stop();

    const occurredAt = new Date(startedAt).toISOString();

    createFeeding({
      babyId: activeBabyId,
      feedingType: getFeedingType(),
      amountMl: tab === "formula" ? amountMl : undefined,
      durationMinutes: tab === "breast" ? Math.round(durationSeconds / 60) : undefined,
      startedAt: occurredAt,
      memo: memo || undefined,
    });

    if (withDiaper) {
      createDiaper({
        babyId: activeBabyId,
        diaperType: diaperType,
        stoolColor: hasPoop ? stoolColor : undefined,
        stoolState: hasPoop ? stoolState : undefined,
        recordedAt: occurredAt,
        memo: undefined,
      });
    }

    setMemo("");
    setAmountMl(100);
    setAmountInput("100");
    setStoolColor(undefined);
    setStoolState(undefined);
    timer.reset();
  }

  return (
    <div className="space-y-4">
      {/* 수유 탭 */}
      <div className="flex rounded-xl bg-gray-100 p-1">
        {(["formula", "breast"] as Tab[]).map((t) => (
          <button
            key={t}
            onClick={() => setTab(t)}
            className={cn(
              "flex-1 py-2 rounded-lg text-sm font-medium transition-all",
              tab === t ? "bg-white text-gray-900 shadow-sm" : "text-gray-500"
            )}
          >
            {t === "formula" ? "분유" : "모유"}
          </button>
        ))}
      </div>

      {/* 분유 */}
      {tab === "formula" && (
        <div className="space-y-3">
          <p className="text-sm font-medium text-gray-700">수유량 (ml)</p>
          <div className="flex items-center gap-3">
            <button
              onClick={() => adjustAmount(-10)}
              className="w-11 h-11 rounded-full bg-blue-50 flex items-center justify-center text-blue-500 hover:bg-blue-100 active:bg-blue-200"
            >
              <Minus className="w-5 h-5" />
            </button>
            <div className="flex-1 text-center">
              <Input
                type="number"
                value={amountInput}
                onChange={(e) => handleAmountInput(e.target.value)}
                className="text-center text-2xl font-bold tabular-nums h-14"
                min={0}
                max={500}
              />
            </div>
            <button
              onClick={() => adjustAmount(10)}
              className="w-11 h-11 rounded-full bg-blue-50 flex items-center justify-center text-blue-500 hover:bg-blue-100 active:bg-blue-200"
            >
              <Plus className="w-5 h-5" />
            </button>
          </div>
          <div className="flex gap-2 flex-wrap">
            {[60, 80, 100, 120, 150, 180].map((v) => (
              <button
                key={v}
                onClick={() => {
                  setAmountMl(v);
                  setAmountInput(String(v));
                }}
                className={cn(
                  "px-3 py-1.5 rounded-full text-sm font-medium border transition-colors",
                  amountMl === v
                    ? "bg-blue-400 text-white border-blue-400"
                    : "bg-white text-gray-600 border-gray-200 hover:border-blue-300"
                )}
              >
                {v}ml
              </button>
            ))}
          </div>
        </div>
      )}

      {/* 모유 */}
      {tab === "breast" && (
        <div className="space-y-4">
          <div>
            <p className="text-sm font-medium text-gray-700 mb-2">수유 방향</p>
            <div className="flex gap-2">
              {(["left", "right", "both"] as BreastSide[]).map((side) => (
                <button
                  key={side}
                  onClick={() => setBreastSide(side)}
                  className={cn(
                    "flex-1 py-2.5 rounded-xl text-sm font-medium border transition-all",
                    breastSide === side
                      ? "bg-blue-400 text-white border-blue-400"
                      : "bg-white text-gray-600 border-gray-200 hover:border-blue-300"
                  )}
                >
                  {side === "left" ? "좌" : side === "right" ? "우" : "양쪽"}
                </button>
              ))}
            </div>
          </div>
          <div className="flex flex-col items-center gap-3 py-4">
            <div className="text-4xl font-bold tabular-nums text-gray-900">
              {formatTimerDisplay(timer.elapsedSeconds)}
            </div>
            <div className="flex gap-3">
              {!timer.isRunning ? (
                <Button onClick={timer.start} className="px-8 bg-blue-400 hover:bg-blue-500">
                  시작
                </Button>
              ) : (
                <Button onClick={timer.stop} variant="outline" className="px-8">
                  일시정지
                </Button>
              )}
              {timer.elapsedSeconds > 0 && (
                <Button onClick={timer.reset} variant="ghost" size="sm">
                  초기화
                </Button>
              )}
            </div>
          </div>
        </div>
      )}

      {/* 기록 시간 */}
      <div>
        <p className="text-sm font-medium text-gray-700 mb-1.5">기록 시간 (과거 날짜 입력 가능)</p>
        <Input
          type="datetime-local"
          value={startedAt}
          max={new Date().toISOString().slice(0, 16)}
          onChange={(e) => setStartedAt(e.target.value)}
        />
      </div>

      {/* 메모 */}
      <div>
        <p className="text-sm font-medium text-gray-700 mb-1.5">메모 (선택)</p>
        <Input
          placeholder="메모를 입력하세요"
          value={memo}
          onChange={(e) => setMemo(e.target.value)}
        />
      </div>

      {/* 배변 함께 기록 토글 */}
      <div className="border border-orange-200 rounded-2xl overflow-hidden">
        <button
          onClick={() => setWithDiaper((v) => !v)}
          className={cn(
            "w-full flex items-center justify-between px-4 py-3 text-sm font-medium transition-colors",
            withDiaper
              ? "bg-orange-50 text-orange-700"
              : "bg-gray-50 text-gray-500 hover:bg-orange-50 hover:text-orange-600"
          )}
        >
          <span>🧷 배변도 함께 기록</span>
          {withDiaper ? (
            <ChevronUp className="w-4 h-4" />
          ) : (
            <ChevronDown className="w-4 h-4" />
          )}
        </button>

        {withDiaper && (
          <div className="px-4 pb-4 pt-3 space-y-4 bg-orange-50/30">
            {/* 종류 */}
            <div>
              <p className="text-xs font-medium text-gray-600 mb-2">종류</p>
              <div className="flex gap-2">
                {[
                  { value: DiaperType.Pee, label: "소변", emoji: "💧" },
                  { value: DiaperType.Poop, label: "대변", emoji: "💩" },
                  { value: DiaperType.Both, label: "둘 다", emoji: "💧💩" },
                ].map(({ value, label, emoji }) => (
                  <button
                    key={value}
                    onClick={() => setDiaperType(value)}
                    className={cn(
                      "flex-1 flex flex-col items-center py-3 rounded-xl border-2 transition-all",
                      diaperType === value
                        ? "border-orange-400 bg-orange-50 text-orange-700"
                        : "border-gray-100 bg-white text-gray-600 hover:border-gray-200"
                    )}
                  >
                    <span className="text-xl mb-0.5">{emoji}</span>
                    <span className="text-xs font-medium">{label}</span>
                  </button>
                ))}
              </div>
            </div>

            {/* 대변 색상/상태 */}
            {hasPoop && (
              <>
                <div>
                  <p className="text-xs font-medium text-gray-600 mb-2">색상</p>
                  <div className="flex gap-2 flex-wrap">
                    {STOOL_COLORS.map(({ value, label, hex }) => (
                      <button
                        key={value}
                        onClick={() => setStoolColor(value as StoolColor)}
                        className={cn(
                          "flex items-center gap-1.5 px-2.5 py-1.5 rounded-xl border-2 transition-all",
                          stoolColor === value
                            ? "border-gray-700 bg-gray-50"
                            : "border-gray-100 bg-white hover:border-gray-300"
                        )}
                      >
                        <span
                          className="w-4 h-4 rounded-full border border-gray-200 flex-shrink-0"
                          style={{ backgroundColor: hex }}
                        />
                        <span className="text-xs text-gray-700">{label}</span>
                      </button>
                    ))}
                  </div>
                </div>
                <div>
                  <p className="text-xs font-medium text-gray-600 mb-2">상태</p>
                  <div className="flex gap-2">
                    {STOOL_STATES.map(({ value, label }) => (
                      <button
                        key={value}
                        onClick={() => setStoolState(value as StoolState)}
                        className={cn(
                          "flex-1 py-2 rounded-xl text-xs font-medium border-2 transition-all",
                          stoolState === value
                            ? "border-orange-400 bg-orange-50 text-orange-700"
                            : "border-gray-100 bg-white text-gray-600 hover:border-gray-200"
                        )}
                      >
                        {label}
                      </button>
                    ))}
                  </div>
                </div>
              </>
            )}
          </div>
        )}
      </div>

      <Button
        onClick={handleSave}
        disabled={isPending}
        className="w-full h-14 text-lg bg-blue-400 hover:bg-blue-500"
      >
        {isPending ? "저장 중..." : withDiaper ? "수유 + 배변 저장" : "저장"}
      </Button>
    </div>
  );
}
