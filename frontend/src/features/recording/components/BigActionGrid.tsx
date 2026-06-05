"use client";

/**
 * BigActionGrid — 2×3 큰 버튼 그리드 (홈 기록 캔버스).
 *
 * 탭: 디폴트 값으로 즉시 저장 / 타이머 시작
 * 길게 누르기(500ms): QuickOptionSheet 열림
 *
 * 진행 중 타이머(수면/놀이)가 있으면 해당 버튼에 "종료" 표시 + 활성 색상.
 */

import { useState, useRef, useCallback } from "react";
import { Loader2 } from "lucide-react";
import { useUIStore } from "@/shared/stores/uiStore";
import { useActivityTimerStore } from "@/shared/stores/activityTimerStore";
import { useRecordingDefaultsStore } from "@/shared/stores/recordingDefaultsStore";
import { useQuickSave } from "../hooks/useQuickSave";
import { QuickOptionSheet, type SheetActivity } from "./QuickOptionSheet";
import { getDateString, formatDate } from "@/lib/date-utils";

interface ActionDef {
  key: SheetActivity;
  emoji: string;
  label: string;
  activeLabel?: string;       // 타이머 진행 중일 때 표시
  activeBg: string;           // 진행 중 배경
  idleBg: string;             // 기본 배경
  activeText: string;
  idleText: string;
}

const ACTIONS: ActionDef[] = [
  {
    key: "formula",
    emoji: "🍼",
    label: "분유",
    activeBg: "bg-blue-100 border-blue-300",
    idleBg: "bg-blue-50 border-blue-100",
    activeText: "text-blue-800",
    idleText: "text-blue-700",
  },
  {
    key: "breast",
    emoji: "🤱",
    label: "모유",
    activeLabel: "모유 종료",
    activeBg: "bg-pink-100 border-pink-300",
    idleBg: "bg-pink-50 border-pink-100",
    activeText: "text-pink-800",
    idleText: "text-pink-700",
  },
  {
    key: "pee",
    emoji: "💧",
    label: "소변",
    activeBg: "bg-cyan-100 border-cyan-300",
    idleBg: "bg-cyan-50 border-cyan-100",
    activeText: "text-cyan-800",
    idleText: "text-cyan-700",
  },
  {
    key: "poo",
    emoji: "💩",
    label: "대변",
    activeBg: "bg-yellow-100 border-yellow-300",
    idleBg: "bg-yellow-50 border-yellow-100",
    activeText: "text-yellow-800",
    idleText: "text-yellow-700",
  },
  {
    key: "sleep",
    emoji: "😴",
    label: "수면 시작",
    activeLabel: "수면 종료",
    activeBg: "bg-purple-100 border-purple-300",
    idleBg: "bg-purple-50 border-purple-100",
    activeText: "text-purple-800",
    idleText: "text-purple-700",
  },
  {
    key: "play",
    emoji: "🎈",
    label: "놀이 시작",
    activeLabel: "놀이 종료",
    activeBg: "bg-green-100 border-green-300",
    idleBg: "bg-green-50 border-green-100",
    activeText: "text-green-800",
    idleText: "text-green-700",
  },
];

/* ─── 인라인 토스트 ─────────────────────────────────────────── */
interface ToastState { msg: string }

function useInlineToast() {
  const [toast, setToast] = useState<ToastState | null>(null);
  const timerRef = useRef<ReturnType<typeof setTimeout> | null>(null);

  function show(msg: string) {
    if (timerRef.current) clearTimeout(timerRef.current);
    setToast({ msg });
    timerRef.current = setTimeout(() => setToast(null), 3000);
  }

  return { toast, show };
}

/* ─── 메인 ─────────────────────────────────────────────────── */

export function BigActionGrid() {
  const { activeBabyId, selectedDate } = useUIStore();
  const isToday = selectedDate === getDateString(new Date());
  const timerStore = useActivityTimerStore();
  const defaults = useRecordingDefaultsStore();
  const { saveFormula, savePee, savePoo, isSaving } = useQuickSave();

  const [sheetActivity, setSheetActivity] = useState<SheetActivity | null>(null);
  const [savingKey, setSavingKey] = useState<SheetActivity | null>(null);
  const { toast, show: showToast } = useInlineToast();

  /* ─── 길게 누르기 감지 ─── */
  const longPressTimer = useRef<ReturnType<typeof setTimeout> | null>(null);
  const didLongPress = useRef(false);

  const onPressStart = useCallback((key: SheetActivity) => {
    didLongPress.current = false;
    longPressTimer.current = setTimeout(() => {
      didLongPress.current = true;
      setSheetActivity(key);
    }, 500);
  }, []);

  const onPressEnd = useCallback(() => {
    if (longPressTimer.current) clearTimeout(longPressTimer.current);
  }, []);

  /* ─── 탭 즉시 저장 ─── */
  async function handleTap(key: SheetActivity) {
    if (didLongPress.current || !activeBabyId || savingKey) return;
    // 과거 날짜 모드: 즉시저장/타이머 대신 시각 입력 시트를 연다
    if (!isToday) {
      setSheetActivity(key);
      return;
    }
    setSavingKey(key);
    try {
      switch (key) {
        case "formula": {
          await saveFormula(activeBabyId, defaults.formulaMl);
          showToast(`분유 ${defaults.formulaMl}ml 기록됐어요`);
          break;
        }
        case "breast": {
          const existing = timerStore.getSession("feeding");
          if (existing) {
            timerStore.finishSession("feeding");
            showToast("모유 수유 종료됐어요");
          } else {
            const feedingTypeMap = { left: "breast_left", right: "breast_right", both: "breast_both" } as const;
            timerStore.startSession("feeding", {
              babyId: activeBabyId,
              feedingType: feedingTypeMap[defaults.breastSide],
            });
            showToast(`모유 (${defaults.breastSide === "both" ? "양쪽" : defaults.breastSide === "left" ? "왼쪽" : "오른쪽"}) 타이머 시작됐어요`);
          }
          break;
        }
        case "pee": {
          await savePee(activeBabyId);
          showToast("소변 기록됐어요");
          break;
        }
        case "poo": {
          await savePoo(activeBabyId);
          showToast("대변 기록됐어요");
          break;
        }
        case "sleep": {
          const existing = timerStore.getSession("sleep");
          if (existing) {
            timerStore.finishSession("sleep");
            showToast("수면 타이머 종료됐어요");
          } else {
            timerStore.startSession("sleep", { babyId: activeBabyId });
            showToast("수면 타이머 시작됐어요");
          }
          break;
        }
        case "play": {
          const existing = timerStore.getSession("play");
          if (existing) {
            timerStore.finishSession("play");
            showToast("놀이 타이머 종료됐어요");
          } else {
            timerStore.startSession("play", {
              babyId: activeBabyId,
              playType: defaults.playType,
            });
            showToast("놀이 타이머 시작됐어요");
          }
          break;
        }
      }
    } catch {
      showToast("저장 실패. 다시 시도해주세요.");
    } finally {
      setSavingKey(null);
    }
  }

  function isTimerActive(key: SheetActivity): boolean {
    if (key === "breast") return !!timerStore.getSession("feeding");
    if (key === "sleep") return !!timerStore.getSession("sleep");
    if (key === "play") return !!timerStore.getSession("play");
    return false;
  }

  if (!activeBabyId) return null;

  return (
    <div className="space-y-2">
      {!isToday && (
        <div className="flex items-center gap-1.5 rounded-xl bg-amber-50 border border-amber-200 px-3 py-2 text-xs text-amber-700">
          📅 <span className="font-semibold">{formatDate(`${selectedDate}T12:00:00+09:00`)}</span>에 기록 중 · 버튼을 누르면 시각을 입력해요
        </div>
      )}

      <div className="grid grid-cols-3 gap-2">
        {ACTIONS.map((action) => {
          const active = isToday && isTimerActive(action.key);
          const loading = savingKey === action.key || (isSaving && (action.key === "formula" || action.key === "pee" || action.key === "poo"));

          return (
            <button
              key={action.key}
              onPointerDown={() => onPressStart(action.key)}
              onPointerUp={() => {
                onPressEnd();
                handleTap(action.key);
              }}
              onPointerLeave={onPressEnd}
              onPointerCancel={onPressEnd}
              disabled={!!savingKey}
              className={`relative flex flex-col items-center gap-1 py-3 rounded-xl border transition-all active:scale-95 select-none ${
                active
                  ? `${action.activeBg} ${action.activeText}`
                  : `${action.idleBg} ${action.idleText}`
              } disabled:opacity-60`}
            >
              <span className="text-xl">{action.emoji}</span>
              <span className="text-[11px] font-semibold leading-tight">
                {active && action.activeLabel ? action.activeLabel : action.label}
              </span>
              {loading && (
                <div className="absolute inset-0 flex items-center justify-center rounded-xl bg-white/60">
                  <Loader2 className="w-4 h-4 animate-spin text-gray-500" />
                </div>
              )}
            </button>
          );
        })}
      </div>

      {/* 인라인 토스트 */}
      {toast && (
        <div className="bg-gray-800 text-white text-xs rounded-xl px-3 py-2">
          ✅ {toast.msg}
        </div>
      )}

      {/* 옵션 시트 — activity가 바뀔 때마다 remount하여 시각 입력 초기화 */}
      <QuickOptionSheet
        key={sheetActivity ?? "none"}
        activity={sheetActivity}
        targetDate={selectedDate}
        onClose={() => setSheetActivity(null)}
        onSaved={(msg) => {
          setSheetActivity(null);
          showToast(msg);
        }}
      />
    </div>
  );
}
