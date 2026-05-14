"use client";

import { useState } from "react";
import { Minus, Plus } from "lucide-react";
import { Button } from "@/shared/components/ui/button";
import { Input } from "@/shared/components/ui/input";
import { useTimer } from "@/shared/hooks/useTimer";
import { useCreateFeeding } from "../api/feedingApi";
import { FeedingType } from "../types/feeding";
import { useUIStore } from "@/shared/stores/uiStore";
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
  const { mutate: createFeeding, isPending } = useCreateFeeding();
  const timer = useTimer("feeding");

  const [tab, setTab] = useState<Tab>("formula");
  const [amountMl, setAmountMl] = useState(100);
  const [amountInput, setAmountInput] = useState("100");
  const [breastSide, setBreastSide] = useState<BreastSide>("both");
  const [memo, setMemo] = useState("");
  const [startedAt, setStartedAt] = useState(() => {
    const now = new Date();
    return now.toISOString().slice(0, 16);
  });

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
    const durationSeconds = tab === "breast" && timer.startedAt
      ? Math.floor((Date.now() - timer.startedAt) / 1000)
      : 0;

    if (timer.isRunning) timer.stop();

    createFeeding({
      babyId: activeBabyId,
      type: getFeedingType(),
      amountMl: tab === "formula" ? amountMl : undefined,
      durationMinutes: tab === "breast" ? Math.round(durationSeconds / 60) : undefined,
      startedAt: new Date(startedAt).toISOString(),
      memo: memo || undefined,
    });

    setMemo("");
    setAmountMl(100);
    setAmountInput("100");
    timer.reset();
  }

  return (
    <div className="space-y-4">
      <div className="flex rounded-xl bg-gray-100 p-1">
        {(["formula", "breast"] as Tab[]).map((t) => (
          <button
            key={t}
            onClick={() => setTab(t)}
            className={cn(
              "flex-1 py-2 rounded-lg text-sm font-medium transition-all",
              tab === t
                ? "bg-white text-gray-900 shadow-sm"
                : "text-gray-500"
            )}
          >
            {t === "formula" ? "분유" : "모유"}
          </button>
        ))}
      </div>

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
                onClick={() => { setAmountMl(v); setAmountInput(String(v)); }}
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

      <div>
        <p className="text-sm font-medium text-gray-700 mb-1.5">시간</p>
        <Input
          type="datetime-local"
          value={startedAt}
          onChange={(e) => setStartedAt(e.target.value)}
        />
      </div>

      <div>
        <p className="text-sm font-medium text-gray-700 mb-1.5">메모 (선택)</p>
        <Input
          placeholder="메모를 입력하세요"
          value={memo}
          onChange={(e) => setMemo(e.target.value)}
        />
      </div>

      <Button
        onClick={handleSave}
        disabled={isPending}
        className="w-full h-14 text-lg bg-blue-400 hover:bg-blue-500"
      >
        {isPending ? "저장 중..." : "저장"}
      </Button>
    </div>
  );
}
