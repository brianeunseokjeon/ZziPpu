"use client";

/**
 * QuickRepeatRow — "또 100ml" 1탭 반복 기록 버튼 모음.
 *
 * - 수유 버튼: 마지막 수유 타입/ml 기반. 기록 없으면 숨김.
 * - 배변 버튼(소변/대변): 항상 표시.
 * - 탭 1회 → 즉시 저장 → 토스트 + [되돌리기] 5초 노출.
 */

import { useState } from "react";
import { Loader2 } from "lucide-react";
import { useUIStore } from "@/shared/stores/uiStore";
import { useLastRecord } from "../hooks/useLastRecord";
import { useQuickSave } from "../hooks/useQuickSave";
import { FeedingType } from "@/features/feeding/types/feeding";
import type { UndoHandle } from "../hooks/useQuickSave";

/* ─── 인라인 토스트 ─────────────────────────────────────────── */

interface ToastState {
  msg: string;
  undo?: () => void;
}

function useToast() {
  const [toast, setToast] = useState<ToastState | null>(null);
  let timer: ReturnType<typeof setTimeout> | null = null;

  function show(msg: string, undoFn?: () => void) {
    if (timer) clearTimeout(timer);
    setToast({ msg, undo: undoFn });
    timer = setTimeout(() => setToast(null), 5000);
  }

  function dismiss() {
    if (timer) clearTimeout(timer);
    setToast(null);
  }

  return { toast, show, dismiss };
}

/* ─── 수유 버튼 텍스트 계산 ─────────────────────────────────── */

function feedingLabel(feedingType: FeedingType, amountMl?: number): string {
  switch (feedingType) {
    case FeedingType.Formula:
      return amountMl ? `🍼 또 ${amountMl}ml` : "🍼 또 분유";
    case FeedingType.BreastLeft:
      return "🤱 또 모유 왼쪽";
    case FeedingType.BreastRight:
      return "🤱 또 모유 오른쪽";
    case FeedingType.BreastBoth:
      return "🤱 또 모유 양쪽";
    default:
      return "🍼 또 수유";
  }
}

/* ─── 개별 버튼 ─────────────────────────────────────────────── */

interface QuickButtonProps {
  label: string;
  disabled?: boolean;
  loading?: boolean;
  onClick: () => void;
  color?: "blue" | "green" | "yellow" | "purple";
}

const COLOR_MAP: Record<string, string> = {
  blue: "bg-blue-50 text-blue-700 border-blue-100 active:bg-blue-100",
  green: "bg-green-50 text-green-700 border-green-100 active:bg-green-100",
  yellow: "bg-yellow-50 text-yellow-700 border-yellow-100 active:bg-yellow-100",
  purple: "bg-purple-50 text-purple-700 border-purple-100 active:bg-purple-100",
};

function QuickButton({ label, disabled, loading, onClick, color = "blue" }: QuickButtonProps) {
  return (
    <button
      onClick={onClick}
      disabled={disabled || loading}
      className={`flex items-center gap-1.5 px-3 py-2 rounded-xl border text-sm font-medium transition-all active:scale-95 disabled:opacity-50 ${COLOR_MAP[color]}`}
    >
      {loading ? <Loader2 className="w-3.5 h-3.5 animate-spin" /> : null}
      <span>{label}</span>
    </button>
  );
}

/* ─── 메인 컴포넌트 ─────────────────────────────────────────── */

export function QuickRepeatRow() {
  const { activeBabyId } = useUIStore();
  const { lastFeeding, lastPee: _lastPee, lastPoo: _lastPoo } = useLastRecord(activeBabyId);
  const { saveFormula, saveBreast, savePee, savePoo, isSaving } = useQuickSave();
  const { toast, show: showToast, dismiss } = useToast();
  const [savingAction, setSavingAction] = useState<string | null>(null);

  if (!activeBabyId) return null;

  async function handleAction(key: string, action: () => Promise<UndoHandle>, successMsg: string) {
    if (savingAction) return;
    setSavingAction(key);
    try {
      const handle = await action();
      showToast(successMsg, handle.undo);
    } catch {
      showToast("저장 실패. 다시 시도해주세요.");
    } finally {
      setSavingAction(null);
    }
  }

  function handleFeeding() {
    if (!lastFeeding) return;
    const { feedingType, amountMl } = lastFeeding;
    const label = feedingLabel(feedingType, amountMl);

    if (feedingType === FeedingType.Formula) {
      handleAction(
        "feeding",
        () => saveFormula(activeBabyId, amountMl ?? 100),
        `${label.replace("또 ", "")} 기록됐어요`
      );
    } else {
      const sideMap: Record<FeedingType, "left" | "right" | "both"> = {
        [FeedingType.BreastLeft]: "left",
        [FeedingType.BreastRight]: "right",
        [FeedingType.BreastBoth]: "both",
        [FeedingType.Formula]: "both",
      };
      handleAction(
        "feeding",
        () => saveBreast(activeBabyId, sideMap[feedingType]),
        "모유 수유 기록됐어요"
      );
    }
  }

  return (
    <div className="space-y-2">
      {/* 버튼 행 */}
      <div className="flex flex-wrap gap-2">
        {/* 수유 버튼 — 마지막 기록 있을 때만 */}
        {lastFeeding && (
          <QuickButton
            label={feedingLabel(lastFeeding.feedingType, lastFeeding.amountMl)}
            loading={savingAction === "feeding"}
            disabled={isSaving}
            onClick={handleFeeding}
            color="blue"
          />
        )}

        {/* 배변 버튼 — 항상 표시 */}
        <QuickButton
          label="💧 또 소변"
          loading={savingAction === "pee"}
          disabled={isSaving}
          onClick={() =>
            handleAction("pee", () => savePee(activeBabyId), "소변 기록됐어요")
          }
          color="green"
        />
        <QuickButton
          label="💩 또 대변"
          loading={savingAction === "poo"}
          disabled={isSaving}
          onClick={() =>
            handleAction("poo", () => savePoo(activeBabyId), "대변 기록됐어요")
          }
          color="yellow"
        />
      </div>

      {/* 인라인 토스트 */}
      {toast && (
        <div className="flex items-center justify-between gap-2 bg-gray-800 text-white text-xs rounded-xl px-3 py-2">
          <span>✅ {toast.msg}</span>
          {toast.undo && (
            <button
              onClick={() => {
                toast.undo?.();
                dismiss();
              }}
              className="underline text-yellow-300 shrink-0"
            >
              되돌리기
            </button>
          )}
        </div>
      )}
    </div>
  );
}
