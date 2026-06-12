"use client";

import { useEffect, useState } from "react";
import { Minus, Plus, Play, Pause, CheckCircle2, RotateCcw } from "lucide-react";
import { Button } from "@/shared/components/ui/button";
import { Input } from "@/shared/components/ui/input";
import { TimeField } from "@/shared/components/ui/time-field";
import { useActivityTimer, formatElapsed } from "@/shared/hooks/useActivityTimer";
import {
  useRecordingPreferencesStore,
  type RecordingMode,
} from "@/shared/stores/recordingPreferencesStore";
import { useCreateFeeding } from "../api/feedingApi";
import { FeedingType } from "../types/feeding";
import { useUIStore } from "@/shared/stores/uiStore";
import { ModeToggle } from "@/features/recording/components/ModeToggle";
import { cn } from "@/lib/utils";
import {
  nowTimeInput,
  applyTimeInput,
  getDateString,
  formatDate,
} from "@/lib/date-utils";
import { toast } from "@/shared/stores/toastStore";

type Tab = "formula" | "breast";
type BreastSide = "left" | "right" | "both";

/** KST 날짜("YYYY-MM-DD") + KST 시각("HH:MM") → UTC ISO */
function buildISO(dateStr: string, timeStr: string): string {
  // 선택된 KST 날짜의 정오를 기준으로 시각만 교체 (날짜 경계 안전)
  const baseISO = new Date(`${dateStr}T12:00:00+09:00`).toISOString();
  return applyTimeInput(baseISO, timeStr);
}

function sideToFeedingType(side: BreastSide): FeedingType {
  if (side === "left") return FeedingType.BreastLeft;
  if (side === "right") return FeedingType.BreastRight;
  return FeedingType.BreastBoth;
}

function metaToBreastSide(meta?: string): BreastSide {
  if (meta === "breast_left") return "left";
  if (meta === "breast_right") return "right";
  return "both";
}

export function FeedingForm() {
  const { activeBabyId, selectedDate } = useUIStore();
  const { mutateAsync: createFeeding, isPending } = useCreateFeeding();
  const timer = useActivityTimer("feeding");
  const formulaDefault = useRecordingPreferencesStore((s) => s.defaultModes.feedingFormula);
  const breastDefault = useRecordingPreferencesStore((s) => s.defaultModes.feedingBreast);

  const [tab, setTab] = useState<Tab>(timer.isActive ? "breast" : "formula");
  const [formulaMode, setFormulaMode] = useState<RecordingMode>(
    formulaDefault === "timer" ? "now" : formulaDefault
  );
  const [breastMode, setBreastMode] = useState<RecordingMode>(
    timer.isActive ? "timer" : breastDefault
  );

  useEffect(() => {
    if (timer.isActive) {
      setTab("breast");
      setBreastMode("timer");
    }
  }, [timer.isActive]);

  // 분유 상태
  const [amountMl, setAmountMl] = useState(100);
  const [amountInput, setAmountInput] = useState("100");
  // 모유 상태
  const [breastSide, setBreastSide] = useState<BreastSide>(
    metaToBreastSide(timer.session?.meta.feedingType)
  );
  // 공통
  const [memo, setMemo] = useState("");

  // 시간/날짜 상태 (KST 기준) — 날짜는 헤더에서 선택한 날짜(selectedDate)를 따른다
  const [timeStr, setTimeStr] = useState(nowTimeInput);
  const [dateStr, setDateStr] = useState(selectedDate);

  // SSR 하이드레이션 대응: 시각은 마운트 시 현재로
  useEffect(() => {
    setTimeStr(nowTimeInput());
  }, []);

  // 헤더에서 날짜를 바꾸면 폼 날짜도 따라가도록 동기화
  useEffect(() => {
    setDateStr(selectedDate);
  }, [selectedDate]);

  const [manualMinutes, setManualMinutes] = useState<number | "">("");

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

  function handleBreastSideChange(s: BreastSide) {
    setBreastSide(s);
    if (timer.isActive) {
      timer.updateMeta({
        feedingType: s === "left" ? "breast_left" : s === "right" ? "breast_right" : "breast_both",
      });
    }
  }

  // === 저장 ===

  const ERR = "저장하지 못했어요. 잠시 후 다시 시도해 주세요.";

  async function saveFormulaNow() {
    if (amountMl <= 0) { alert("수유량을 입력해주세요"); return; }
    try {
      await createFeeding({ babyId: activeBabyId, feedingType: FeedingType.Formula, amountMl, startedAt: buildISO(dateStr, timeStr), memo: memo || undefined });
      setMemo(""); setTimeStr(nowTimeInput());
    } catch { toast(ERR, "error"); }
  }

  async function saveFormulaManual() {
    if (amountMl <= 0 || !dateStr || !timeStr) { alert("수유량과 시간을 입력해주세요"); return; }
    try {
      await createFeeding({ babyId: activeBabyId, feedingType: FeedingType.Formula, amountMl, startedAt: buildISO(dateStr, timeStr), memo: memo || undefined });
      setMemo("");
    } catch { toast(ERR, "error"); }
  }

  async function saveBreastNow() {
    try {
      await createFeeding({ babyId: activeBabyId, feedingType: sideToFeedingType(breastSide), startedAt: buildISO(dateStr, nowTimeInput()), memo: memo || undefined });
      setMemo("");
    } catch { toast(ERR, "error"); }
  }

  function handleTimerStart() {
    timer.start({
      feedingType: breastSide === "left" ? "breast_left" : breastSide === "right" ? "breast_right" : "breast_both",
      babyId: activeBabyId,
    });
  }

  async function handleTimerFinish() {
    const finished = timer.finish();
    if (!finished) return;
    try {
      await createFeeding({ babyId: activeBabyId, feedingType: sideToFeedingType(breastSide), durationMinutes: finished.durationMinutes, startedAt: finished.startedAt.toISOString(), memo: memo || undefined });
      setMemo("");
    } catch { toast(ERR, "error"); }
  }

  async function saveBreastManual() {
    if (!dateStr || !timeStr) { alert("시작 시간을 입력해주세요"); return; }
    const durationMinutes = manualMinutes !== "" && Number(manualMinutes) > 0 ? Math.round(Number(manualMinutes)) : undefined;
    try {
      await createFeeding({ babyId: activeBabyId, feedingType: sideToFeedingType(breastSide), durationMinutes, startedAt: buildISO(dateStr, timeStr), memo: memo || undefined });
      setMemo(""); setManualMinutes("");
    } catch { toast(ERR, "error"); }
  }

  return (
    <div className="space-y-5">
      {/* 선택한 날짜가 오늘이 아니면 기록 대상 날짜를 명확히 표시 */}
      {dateStr !== getDateString(new Date()) && (
        <div className="flex items-center gap-2 rounded-xl bg-amber-50 border border-amber-200 px-3 py-2 text-sm text-amber-700">
          📅 <span className="font-semibold">{formatDate(`${dateStr}T12:00:00+09:00`)}</span>
          에 기록됩니다
        </div>
      )}

      {/* 분유/모유 탭 */}
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
            {t === "formula" ? "🍼 분유" : "🤱 모유"}
          </button>
        ))}
      </div>

      {/* ── 분유 (단발성 — now / manual 만) ── */}
      {tab === "formula" && (
        <>
          <ModeToggle
            activity="feedingFormula"
            mode={formulaMode}
            onChange={(m) => setFormulaMode(m === "timer" ? "now" : m)}
            availableModes={["now", "manual"]}
          />

          <div className="space-y-3">
            <p className="text-sm font-medium text-gray-700">수유량 (ml)</p>
            <div className="flex items-center gap-3">
              <button
                onClick={() => adjustAmount(-10)}
                className="w-11 h-11 rounded-full bg-blue-50 flex items-center justify-center text-blue-500"
              >
                <Minus className="w-5 h-5" />
              </button>
              <Input
                type="number"
                value={amountInput}
                onChange={(e) => handleAmountInput(e.target.value)}
                className="text-center text-2xl font-bold tabular-nums h-14"
                min={0}
                max={500}
              />
              <button
                onClick={() => adjustAmount(10)}
                className="w-11 h-11 rounded-full bg-blue-50 flex items-center justify-center text-blue-500"
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
                    "px-3 py-1.5 rounded-full text-sm font-medium border",
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

          {/* 시간 입력 — now/manual 모두 표시 */}
          <div className="space-y-3">
            {formulaMode === "manual" && (
              <div>
                <p className="text-xs text-gray-500 font-medium mb-1">날짜</p>
                <Input
                  type="date"
                  value={dateStr}
                  max={getDateString(new Date())}
                  onChange={(e) => setDateStr(e.target.value)}
                  className="h-11"
                />
              </div>
            )}
            <TimeField
              label="기록 시간"
              value={timeStr}
              onChange={setTimeStr}
            />
          </div>

          <div>
            <p className="text-sm font-medium text-gray-700 mb-1.5">메모 (선택)</p>
            <Input value={memo} onChange={(e) => setMemo(e.target.value)} />
          </div>

          <Button
            onClick={formulaMode === "now" ? saveFormulaNow : saveFormulaManual}
            disabled={isPending}
            className="w-full h-14 text-lg bg-blue-500 hover:bg-blue-600"
          >
            {isPending ? "저장 중..." : formulaMode === "now" ? "지금 기록" : "저장"}
          </Button>
        </>
      )}

      {/* ── 모유 (3-mode) ── */}
      {tab === "breast" && (
        <>
          <ModeToggle activity="feedingBreast" mode={breastMode} onChange={setBreastMode} />

          <div>
            <p className="text-sm font-medium text-gray-700 mb-2">수유 방향</p>
            <div className="flex gap-2">
              {(["left", "right", "both"] as BreastSide[]).map((side) => (
                <button
                  key={side}
                  onClick={() => handleBreastSideChange(side)}
                  className={cn(
                    "flex-1 py-2.5 rounded-xl text-sm font-medium border",
                    breastSide === side
                      ? "bg-blue-400 text-white border-blue-400"
                      : "bg-white text-gray-600 border-gray-200"
                  )}
                >
                  {side === "left" ? "좌" : side === "right" ? "우" : "양쪽"}
                </button>
              ))}
            </div>
          </div>

          {/* ⚡ 지금 기록 */}
          {breastMode === "now" && (
            <div className="bg-blue-50 rounded-2xl p-4 space-y-3 border border-blue-100">
              <p className="text-sm text-blue-700">
                "방금 수유했어요" — 시간 측정 없이 단발 기록. 종료 시간은 옵셔널입니다.
              </p>
              <Button
                onClick={saveBreastNow}
                disabled={isPending}
                className="w-full h-14 bg-blue-500 hover:bg-blue-600"
              >
                {isPending ? "저장 중..." : "지금 기록"}
              </Button>
            </div>
          )}

          {/* ⏱ 타이머 */}
          {breastMode === "timer" && (
            <div className="flex flex-col items-center py-4 gap-4">
              <div className="text-5xl font-bold tabular-nums text-gray-900">
                {formatElapsed(timer.elapsedMs)}
              </div>
              {timer.isPaused && <div className="text-sm text-gray-500">⏸ 일시정지됨</div>}

              <div className="flex gap-2 flex-wrap justify-center">
                {!timer.isActive ? (
                  <Button
                    onClick={handleTimerStart}
                    className="px-6 bg-blue-500 hover:bg-blue-600 flex items-center gap-2"
                  >
                    <Play className="w-4 h-4" />
                    시작
                  </Button>
                ) : (
                  <>
                    {timer.isPaused ? (
                      <Button
                        onClick={timer.resume}
                        className="px-5 bg-blue-500 hover:bg-blue-600 flex items-center gap-2"
                      >
                        <Play className="w-4 h-4" />
                        재개
                      </Button>
                    ) : (
                      <Button
                        onClick={timer.pause}
                        variant="outline"
                        className="px-5 border-blue-300 text-blue-600 flex items-center gap-2"
                      >
                        <Pause className="w-4 h-4" />
                        일시정지
                      </Button>
                    )}
                    <Button
                      onClick={handleTimerFinish}
                      disabled={isPending}
                      className="px-5 bg-green-500 hover:bg-green-600 flex items-center gap-2"
                    >
                      <CheckCircle2 className="w-4 h-4" />
                      완료
                    </Button>
                    <Button onClick={timer.cancel} variant="ghost" size="sm" title="취소">
                      <RotateCcw className="w-4 h-4 text-gray-400" />
                    </Button>
                  </>
                )}
              </div>
              <p className="text-xs text-gray-400 text-center max-w-xs">
                종료 시간은 옵셔널이에요. 완료 못해도 진행 중 표시가 모든 화면에 보입니다.
              </p>
            </div>
          )}

          {/* ✏️ 수동 입력 */}
          {breastMode === "manual" && (
            <div className="space-y-3 bg-gray-50 rounded-2xl p-4 border border-gray-100">
              <div>
                <p className="text-xs text-gray-500 font-medium mb-1">날짜</p>
                <Input
                  type="date"
                  value={dateStr}
                  max={getDateString(new Date())}
                  onChange={(e) => setDateStr(e.target.value)}
                  className="h-11"
                />
              </div>
              <TimeField
                label="시작 시간"
                value={timeStr}
                onChange={setTimeStr}
              />
              <div>
                <p className="text-sm font-medium text-gray-700 mb-1.5">
                  수유 시간 (분) <span className="text-gray-400 text-xs">옵셔널</span>
                </p>
                <Input
                  type="number"
                  min={1}
                  max={120}
                  placeholder="예: 15 (비워두면 시작 시간만 기록)"
                  value={manualMinutes}
                  onChange={(e) =>
                    setManualMinutes(e.target.value === "" ? "" : Number(e.target.value))
                  }
                />
              </div>
            </div>
          )}

          <div>
            <p className="text-sm font-medium text-gray-700 mb-1.5">메모 (선택)</p>
            <Input value={memo} onChange={(e) => setMemo(e.target.value)} />
          </div>

          {breastMode === "manual" && (
            <Button
              onClick={saveBreastManual}
              disabled={isPending}
              className="w-full h-14 text-lg bg-blue-500 hover:bg-blue-600"
            >
              {isPending ? "저장 중..." : "저장"}
            </Button>
          )}
        </>
      )}
    </div>
  );
}
