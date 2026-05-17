"use client";

import { useState } from "react";
import { Minus, Plus, Milk, Baby as BabyIcon, Clock } from "lucide-react";
import { Button } from "@/shared/components/ui/button";
import { Input } from "@/shared/components/ui/input";
import { useCreateFeeding } from "@/features/feeding/api/feedingApi";
import { useCreateDiaper } from "@/features/diaper/api/diaperApi";
import { FeedingType } from "@/features/feeding/types/feeding";
import { DiaperType, StoolColor, StoolState } from "@/features/diaper/types/diaper";
import { useUIStore } from "@/shared/stores/uiStore";
import { STOOL_COLORS, STOOL_STATES } from "@/config/constants";
import { cn } from "@/lib/utils";

type BreastSide = "left" | "right" | "both";
type DiaperMode = "off" | "pee" | "poo" | "both";

function getNowHHMM(): string {
  const d = new Date();
  return `${String(d.getHours()).padStart(2, "0")}:${String(d.getMinutes()).padStart(2, "0")}`;
}

function todayWithTime(hhmm: string): string {
  const [hh, mm] = hhmm.split(":").map(Number);
  const d = new Date();
  d.setHours(hh, mm, 0, 0);
  return d.toISOString();
}

export function CombinedRecordForm() {
  const { activeBabyId } = useUIStore();
  const { mutateAsync: createFeeding, isPending: feedingPending } = useCreateFeeding();
  const { mutateAsync: createDiaper, isPending: diaperPending } = useCreateDiaper();

  // 수유 — 분유와 모유 각각 독립 토글
  const [formulaOn, setFormulaOn] = useState(false);
  const [amountMl, setAmountMl] = useState(100);
  const [amountInput, setAmountInput] = useState("100");

  const [breastOn, setBreastOn] = useState(false);
  const [breastSide, setBreastSide] = useState<BreastSide>("both");
  const [breastMinutes, setBreastMinutes] = useState(15);

  // 배변
  const [diaperMode, setDiaperMode] = useState<DiaperMode>("off");
  const [stoolColor, setStoolColor] = useState<StoolColor | undefined>();
  const [stoolState, setStoolState] = useState<StoolState | undefined>();

  // 공통: 시간 (HH:MM, 기본=지금). 시간 편집 토글로 노출
  const [timeStr, setTimeStr] = useState(getNowHHMM);
  const [timeEditing, setTimeEditing] = useState(false);
  const [memo, setMemo] = useState("");

  const hasPoop = diaperMode === "poo" || diaperMode === "both";
  const isPending = feedingPending || diaperPending;
  const canSave = formulaOn || breastOn || diaperMode !== "off";

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

  function getBreastType(): FeedingType {
    if (breastSide === "left") return FeedingType.BreastLeft;
    if (breastSide === "right") return FeedingType.BreastRight;
    return FeedingType.BreastBoth;
  }

  function getDiaperType(): DiaperType {
    if (diaperMode === "pee") return DiaperType.Pee;
    if (diaperMode === "poo") return DiaperType.Poop;
    return DiaperType.Both;
  }

  async function handleSave() {
    if (!canSave) return;
    const occurredAt = todayWithTime(timeStr);
    const tasks: Promise<unknown>[] = [];

    // 분유 (켜져 있으면)
    if (formulaOn) {
      tasks.push(
        createFeeding({
          babyId: activeBabyId,
          feedingType: FeedingType.Formula,
          amountMl,
          startedAt: occurredAt,
          memo: memo || undefined,
        })
      );
    }

    // 모유 (켜져 있으면) — 분유와 동시에도 가능
    if (breastOn) {
      tasks.push(
        createFeeding({
          babyId: activeBabyId,
          feedingType: getBreastType(),
          durationMinutes: breastMinutes,
          startedAt: occurredAt,
          memo: !formulaOn ? memo || undefined : undefined,
        })
      );
    }

    if (diaperMode !== "off") {
      tasks.push(
        createDiaper({
          babyId: activeBabyId,
          diaperType: getDiaperType(),
          stoolColor: hasPoop ? stoolColor : undefined,
          stoolState: hasPoop ? stoolState : undefined,
          recordedAt: occurredAt,
          memo: !formulaOn && !breastOn ? (memo || undefined) : undefined,
        })
      );
    }

    await Promise.all(tasks);

    // reset
    setFormulaOn(false);
    setBreastOn(false);
    setDiaperMode("off");
    setAmountMl(100);
    setAmountInput("100");
    setStoolColor(undefined);
    setStoolState(undefined);
    setMemo("");
    setTimeStr(getNowHHMM());
    setTimeEditing(false);
  }

  const saveLabel = (() => {
    if (!canSave) return "수유 또는 배변을 선택하세요";
    const parts: string[] = [];
    if (formulaOn || breastOn) parts.push("수유");
    if (diaperMode !== "off") parts.push("배변");
    return `${parts.join(" + ")} 저장`;
  })();

  return (
    <div className="space-y-5">
      {/* 수유 섹션 */}
      <section className="rounded-2xl border border-blue-100 overflow-hidden">
        <div className="bg-blue-50 px-4 py-2.5 flex items-center gap-2">
          <Milk className="w-4 h-4 text-blue-500" />
          <span className="text-sm font-semibold text-blue-700">수유</span>
          <span className="text-xs text-blue-400">분유·모유 동시 선택 가능</span>
        </div>

        <div className="p-3 space-y-3">
          {/* 분유 / 모유 동시 토글 */}
          <div className="grid grid-cols-2 gap-2">
            <button
              onClick={() => setFormulaOn((v) => !v)}
              className={cn(
                "py-2.5 rounded-xl text-sm font-medium border transition-colors",
                formulaOn
                  ? "bg-blue-400 text-white border-blue-400"
                  : "bg-white text-gray-500 border-gray-200"
              )}
            >
              🍼 분유 {formulaOn ? "ON" : ""}
            </button>
            <button
              onClick={() => setBreastOn((v) => !v)}
              className={cn(
                "py-2.5 rounded-xl text-sm font-medium border transition-colors",
                breastOn
                  ? "bg-blue-400 text-white border-blue-400"
                  : "bg-white text-gray-500 border-gray-200"
              )}
            >
              👩 모유 {breastOn ? "ON" : ""}
            </button>
          </div>

          {/* 분유 입력 */}
          {formulaOn && (
            <div className="space-y-2.5 bg-blue-50/40 rounded-xl p-2.5">
              <p className="text-xs font-medium text-blue-700">분유량</p>
              <div className="flex items-center gap-2">
                <button
                  onClick={() => adjustAmount(-10)}
                  className="w-10 h-10 rounded-full bg-white border border-blue-200 flex items-center justify-center text-blue-500"
                >
                  <Minus className="w-4 h-4" />
                </button>
                <Input
                  type="number"
                  value={amountInput}
                  onChange={(e) => handleAmountInput(e.target.value)}
                  className="text-center text-xl font-bold tabular-nums h-11"
                  min={0}
                  max={500}
                />
                <span className="text-sm text-gray-500">ml</span>
                <button
                  onClick={() => adjustAmount(10)}
                  className="w-10 h-10 rounded-full bg-white border border-blue-200 flex items-center justify-center text-blue-500"
                >
                  <Plus className="w-4 h-4" />
                </button>
              </div>
              <div className="flex gap-1.5 flex-wrap">
                {[60, 80, 100, 120, 150, 180].map((v) => (
                  <button
                    key={v}
                    onClick={() => { setAmountMl(v); setAmountInput(String(v)); }}
                    className={cn(
                      "px-2.5 py-1 rounded-full text-xs font-medium border",
                      amountMl === v
                        ? "bg-blue-400 text-white border-blue-400"
                        : "bg-white text-gray-600 border-gray-200"
                    )}
                  >
                    {v}ml
                  </button>
                ))}
              </div>
            </div>
          )}

          {/* 모유 입력 */}
          {breastOn && (
            <div className="space-y-2.5 bg-blue-50/40 rounded-xl p-2.5">
              <p className="text-xs font-medium text-blue-700">모유 방향 · 시간</p>
              <div className="flex gap-2">
                {(["left", "right", "both"] as BreastSide[]).map((side) => (
                  <button
                    key={side}
                    onClick={() => setBreastSide(side)}
                    className={cn(
                      "flex-1 py-2 rounded-xl text-xs font-medium border",
                      breastSide === side
                        ? "bg-blue-400 text-white border-blue-400"
                        : "bg-white text-gray-600 border-gray-200"
                    )}
                  >
                    {side === "left" ? "좌" : side === "right" ? "우" : "양쪽"}
                  </button>
                ))}
              </div>
              <div className="flex items-center gap-2">
                <Input
                  type="number"
                  value={breastMinutes}
                  onChange={(e) => setBreastMinutes(parseInt(e.target.value, 10) || 0)}
                  className="text-center font-semibold tabular-nums h-9 w-20"
                  min={0}
                  max={120}
                />
                <span className="text-xs text-gray-500">분 동안</span>
              </div>
            </div>
          )}
        </div>
      </section>

      {/* 배변 섹션 */}
      <section className="rounded-2xl border border-orange-100 overflow-hidden">
        <div className="bg-orange-50 px-4 py-2.5 flex items-center gap-2">
          <BabyIcon className="w-4 h-4 text-orange-500" />
          <span className="text-sm font-semibold text-orange-700">배변</span>
        </div>

        <div className="p-3 space-y-3">
          <div className="grid grid-cols-4 gap-2">
            {([
              { v: "off", label: "안 함", emoji: "—" },
              { v: "pee", label: "소변", emoji: "💧" },
              { v: "poo", label: "대변", emoji: "💩" },
              { v: "both", label: "둘 다", emoji: "💧💩" },
            ] as { v: DiaperMode; label: string; emoji: string }[]).map(({ v, label, emoji }) => (
              <button
                key={v}
                onClick={() => setDiaperMode(v)}
                className={cn(
                  "flex flex-col items-center py-2.5 rounded-xl border",
                  diaperMode === v
                    ? "bg-orange-50 border-orange-400 text-orange-700"
                    : "bg-white border-gray-200 text-gray-500"
                )}
              >
                <span className="text-lg mb-0.5">{emoji}</span>
                <span className="text-xs font-medium">{label}</span>
              </button>
            ))}
          </div>

          {hasPoop && (
            <div className="space-y-2.5">
              <div>
                <p className="text-xs font-medium text-gray-600 mb-1.5">색상</p>
                <div className="flex gap-1.5 flex-wrap">
                  {STOOL_COLORS.map(({ value, label, hex }) => (
                    <button
                      key={value}
                      onClick={() => setStoolColor(value as StoolColor)}
                      className={cn(
                        "flex items-center gap-1.5 px-2 py-1.5 rounded-lg border-2",
                        stoolColor === value
                          ? "border-gray-700 bg-gray-50"
                          : "border-gray-100 bg-white"
                      )}
                    >
                      <span
                        className="w-3.5 h-3.5 rounded-full border border-gray-200"
                        style={{ backgroundColor: hex }}
                      />
                      <span className="text-xs text-gray-700">{label}</span>
                    </button>
                  ))}
                </div>
              </div>
              <div>
                <p className="text-xs font-medium text-gray-600 mb-1.5">상태</p>
                <div className="flex gap-1.5">
                  {STOOL_STATES.map(({ value, label }) => (
                    <button
                      key={value}
                      onClick={() => setStoolState(value as StoolState)}
                      className={cn(
                        "flex-1 py-1.5 rounded-lg text-xs font-medium border-2",
                        stoolState === value
                          ? "border-orange-400 bg-orange-50 text-orange-700"
                          : "border-gray-100 bg-white text-gray-600"
                      )}
                    >
                      {label}
                    </button>
                  ))}
                </div>
              </div>
            </div>
          )}
        </div>
      </section>

      {/* 공통: 시간 + 메모 */}
      <div className="space-y-3">
        {/* 시간 표시 / 편집 토글 */}
        <div className="flex items-center justify-between">
          <div className="flex items-center gap-2 text-sm text-gray-700">
            <Clock className="w-4 h-4 text-gray-400" />
            <span>기록 시간:</span>
            {!timeEditing ? (
              <>
                <span className="font-semibold tabular-nums">{timeStr}</span>
                <span className="text-xs text-gray-400">오늘</span>
              </>
            ) : (
              <Input
                type="time"
                value={timeStr}
                onChange={(e) => setTimeStr(e.target.value)}
                className="h-9 w-32"
              />
            )}
          </div>
          <button
            type="button"
            onClick={() => {
              if (timeEditing) {
                setTimeEditing(false);
              } else {
                setTimeStr(getNowHHMM());
                setTimeEditing(true);
              }
            }}
            className="text-xs text-blue-500 underline"
          >
            {timeEditing ? "완료" : "시간 수정"}
          </button>
        </div>

        <div>
          <Input
            placeholder="메모 (선택)"
            value={memo}
            onChange={(e) => setMemo(e.target.value)}
          />
        </div>
      </div>

      <Button
        onClick={handleSave}
        disabled={!canSave || isPending}
        className="w-full h-14 text-lg bg-blue-500 hover:bg-blue-600 disabled:bg-gray-200 disabled:text-gray-400"
      >
        {isPending ? "저장 중..." : saveLabel}
      </Button>
    </div>
  );
}
