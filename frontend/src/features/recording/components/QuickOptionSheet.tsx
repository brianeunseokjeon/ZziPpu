"use client";

/**
 * QuickOptionSheet — BigActionGrid 버튼 길게 누르면 펼쳐지는 옵션 시트.
 *
 * 각 활동에 필요한 핵심 옵션만 노출 (전체 폼 대신).
 * 즉시 저장 활동(분유·소변·대변): ml/시간 조정.
 * 타이머 활동(모유·수면·놀이): 옵션 선택 후 시작.
 */

import { useState } from "react";
import { Loader2 } from "lucide-react";
import { Dialog } from "@/shared/components/ui/dialog";
import { TimeField } from "@/shared/components/ui/time-field";
import { useActivityTimerStore } from "@/shared/stores/activityTimerStore";
import { useQuickSave } from "../hooks/useQuickSave";
import { useRecordingDefaultsStore } from "@/shared/stores/recordingDefaultsStore";
import { useUIStore } from "@/shared/stores/uiStore";
import { nowTimeInput, dateTimeToISO, getDateString, formatDate } from "@/lib/date-utils";
import { useCreateSleep, useEndSleep } from "@/features/sleep/api/sleepApi";
import { useCreatePlay } from "@/features/play/api/playApi";

export type SheetActivity = "formula" | "breast" | "pee" | "poo" | "sleep" | "play";

interface Props {
  activity: SheetActivity | null;
  onClose: () => void;
  onSaved?: (msg: string) => void;
  /** 기록 대상 날짜 "YYYY-MM-DD" (KST). 미지정 시 오늘. 오늘이 아니면 과거 모드. */
  targetDate?: string;
}

const ML_PRESETS = [60, 80, 100, 120, 150, 180];
const PLAY_TYPES = [
  { value: "tummy_time", label: "터미타임" },
  { value: "free_play", label: "자유놀이" },
  { value: "sensory_play", label: "감각놀이" },
] as const;



export function QuickOptionSheet({ activity, onClose, onSaved, targetDate }: Props) {
  const { activeBabyId } = useUIStore();
  const defaults = useRecordingDefaultsStore();
  const timerStore = useActivityTimerStore();
  const { saveFormula, saveBreast, savePee, savePoo, saveBoth, isSaving } = useQuickSave();
  const { mutateAsync: createSleep, isPending: isSavingSleep } = useCreateSleep();
  const { mutateAsync: endSleep, isPending: isEndingSleep } = useEndSleep();
  const { mutateAsync: createPlay, isPending: isSavingPlay } = useCreatePlay();

  // 기록 대상 날짜 (미지정 시 오늘). 오늘이 아니면 과거 모드 → 타이머 대신 시각 직접 입력.
  const dateStr = targetDate ?? getDateString(new Date());
  const isPast = dateStr !== getDateString(new Date());

  /* 분유 ml 상태 */
  const [formulaMl, setFormulaMl] = useState(defaults.formulaMl);
  /* 모유 side 상태 */
  const [breastSide, setBreastSide] = useState<"left" | "right" | "both">(defaults.breastSide);
  /* 놀이 타입 상태 */
  const [playType, setPlayType] = useState<"tummy_time" | "free_play" | "sensory_play">(defaults.playType);
  /* 시간 입력 (시작 시각) — 시트는 activity별로 remount되므로 초기값으로 충분 */
  const [recordTime, setRecordTime] = useState(nowTimeInput);
  /* 종료 시각 (과거 모드의 수면/놀이 완료 기록용) */
  const [endTime, setEndTime] = useState("");
  /* 분유 기록 중 배변 빠른 추가 상태 */
  const [addingDiaper, setAddingDiaper] = useState<"pee" | "poo" | "both" | null>(null);
  const [diaperAddedMsg, setDiaperAddedMsg] = useState<string | null>(null);

  const title: Record<SheetActivity, string> = {
    formula: "🍼 분유",
    breast: "🤱 모유",
    pee: "💧 소변",
    poo: "💩 대변",
    sleep: "😴 수면",
    play: "🎈 터미타임",
  };

  /* 분유 기록 중 배변 빠른 추가 — 기록 시간 필드의 시각으로 즉시 별도 저장 */
  async function handleAddDiaper(kind: "pee" | "poo" | "both") {
    if (!activeBabyId || addingDiaper) return;
    setAddingDiaper(kind);
    try {
      const at = dateTimeToISO(dateStr, recordTime);
      if (kind === "pee") await savePee(activeBabyId, at);
      else if (kind === "poo") await savePoo(activeBabyId, at);
      else await saveBoth(activeBabyId, at);
      setDiaperAddedMsg(
        kind === "pee" ? "💧 소변 기록됐어요" : kind === "poo" ? "💩 대변 기록됐어요" : "💧💩 둘다 기록됐어요"
      );
      setTimeout(() => setDiaperAddedMsg(null), 2500);
    } catch {
      /* 실패 무시 */
    } finally {
      setAddingDiaper(null);
    }
  }

  async function handleSave() {
    if (!activeBabyId || !activity) return;
    const at = dateTimeToISO(dateStr, recordTime);
    try {
      switch (activity) {
        case "formula": {
          await saveFormula(activeBabyId, formulaMl, at);
          defaults.setFormulaMl(formulaMl);
          onSaved?.(`분유 ${formulaMl}ml 기록됐어요`);
          break;
        }
        case "breast": {
          await saveBreast(activeBabyId, breastSide, at);
          defaults.setBreastSide(breastSide);
          onSaved?.("모유 수유 기록됐어요");
          break;
        }
        case "pee": {
          await savePee(activeBabyId, at);
          onSaved?.("소변 기록됐어요");
          break;
        }
        case "poo": {
          await savePoo(activeBabyId, at);
          onSaved?.("대변 기록됐어요");
          break;
        }
        case "sleep": {
          if (isPast) {
            // 과거 모드: 타이머 없이 시작 시각으로 생성 후, 종료 시각이 있으면 종료 처리.
            // (POST /sleeps 는 started_at 만 받으므로 종료는 /end 로 별도 호출)
            const created = await createSleep({ babyId: activeBabyId, startedAt: at });
            if (endTime) {
              await endSleep({
                babyId: activeBabyId,
                sleepId: created.id,
                endedAt: dateTimeToISO(dateStr, endTime),
              });
            }
            onSaved?.("수면 기록됐어요");
            break;
          }
          const existing = timerStore.getSession("sleep");
          if (existing) {
            timerStore.finishSession("sleep");
            onSaved?.("수면 타이머 종료됐어요");
          } else {
            timerStore.startSession("sleep", { babyId: activeBabyId });
            onSaved?.("수면 타이머 시작됐어요");
          }
          break;
        }
        case "play": {
          if (isPast) {
            // 과거 모드: 시작/종료 시각으로 완료 기록 저장 (duration 계산)
            const endedAt = endTime ? dateTimeToISO(dateStr, endTime) : undefined;
            const durationMinutes = endedAt
              ? Math.max(1, Math.round((new Date(endedAt).getTime() - new Date(at).getTime()) / 60000))
              : 1;
            await createPlay({
              babyId: activeBabyId,
              playType,
              durationMinutes,
              startedAt: at,
              endedAt,
            });
            defaults.setPlayType(playType);
            onSaved?.(`${PLAY_TYPES.find((p) => p.value === playType)?.label ?? "터미타임"} 기록됐어요`);
            break;
          }
          const existing = timerStore.getSession("play");
          if (existing) {
            timerStore.finishSession("play");
            onSaved?.("터미타임 타이머 종료됐어요");
          } else {
            timerStore.startSession("play", { babyId: activeBabyId, playType });
            defaults.setPlayType(playType);
            onSaved?.(`${PLAY_TYPES.find((p) => p.value === playType)?.label ?? "터미타임"} 시작됐어요`);
          }
          break;
        }
      }
      onClose();
    } catch {
      /* 저장 실패 무시 (호출처 toast 처리) */
    }
  }

  if (!activity) return null;

  return (
    <Dialog open={!!activity} onClose={onClose} title={title[activity]}>
      <div className="space-y-5">
        {/* 과거 날짜 기록 안내 배너 */}
        {isPast && (
          <div className="flex items-center gap-1.5 rounded-xl bg-amber-50 border border-amber-200 px-3 py-2 text-xs text-amber-700">
            📅 <span className="font-semibold">{formatDate(`${dateStr}T12:00:00+09:00`)}</span>에 기록합니다 · 시각을 직접 입력하세요
          </div>
        )}

        {/* 분유 — ml 슬라이더 + 프리셋 */}
        {activity === "formula" && (
          <div className="space-y-3">
            <div className="text-center">
              <span className="text-3xl font-bold text-blue-600">{formulaMl}</span>
              <span className="text-sm text-gray-500 ml-1">ml</span>
            </div>
            <div className="flex items-center gap-2">
              <button
                onClick={() => setFormulaMl((v) => Math.max(10, v - 10))}
                className="w-10 h-10 rounded-full bg-gray-100 text-gray-700 text-lg font-bold flex items-center justify-center active:bg-gray-200"
              >
                −
              </button>
              <input
                type="range"
                min={10}
                max={300}
                step={10}
                value={formulaMl}
                onChange={(e) => setFormulaMl(Number(e.target.value))}
                className="flex-1 accent-blue-500"
              />
              <button
                onClick={() => setFormulaMl((v) => Math.min(300, v + 10))}
                className="w-10 h-10 rounded-full bg-gray-100 text-gray-700 text-lg font-bold flex items-center justify-center active:bg-gray-200"
              >
                +
              </button>
            </div>
            <div className="flex gap-2 flex-wrap justify-center">
              {ML_PRESETS.map((ml) => (
                <button
                  key={ml}
                  onClick={() => setFormulaMl(ml)}
                  className={`px-3 py-1.5 rounded-full text-sm font-medium border transition-colors ${
                    formulaMl === ml
                      ? "bg-blue-500 text-white border-blue-500"
                      : "bg-white text-gray-600 border-gray-200 hover:border-blue-300"
                  }`}
                >
                  {ml}ml
                </button>
              ))}
            </div>

            {/* 배변 빠른 추가 — 기록 시간 필드의 시각으로 즉시 기록 */}
            <div className="pt-2 border-t border-gray-100 space-y-1.5">
              <p className="text-xs text-gray-500">이 시각에 배변도 함께 기록</p>
              <div className="grid grid-cols-3 gap-2">
                <button
                  type="button"
                  onClick={() => handleAddDiaper("pee")}
                  disabled={!!addingDiaper}
                  className="flex items-center justify-center gap-1 py-2.5 rounded-xl border-2 border-cyan-200 bg-cyan-50 text-cyan-700 text-xs font-medium disabled:opacity-50"
                >
                  {addingDiaper === "pee"
                    ? <Loader2 className="w-4 h-4 animate-spin" />
                    : <span>💧</span>}
                  소변
                </button>
                <button
                  type="button"
                  onClick={() => handleAddDiaper("poo")}
                  disabled={!!addingDiaper}
                  className="flex items-center justify-center gap-1 py-2.5 rounded-xl border-2 border-yellow-200 bg-yellow-50 text-yellow-800 text-xs font-medium disabled:opacity-50"
                >
                  {addingDiaper === "poo"
                    ? <Loader2 className="w-4 h-4 animate-spin" />
                    : <span>💩</span>}
                  대변
                </button>
                <button
                  type="button"
                  onClick={() => handleAddDiaper("both")}
                  disabled={!!addingDiaper}
                  className="flex items-center justify-center gap-1 py-2.5 rounded-xl border-2 border-orange-200 bg-orange-50 text-orange-700 text-xs font-medium disabled:opacity-50"
                >
                  {addingDiaper === "both"
                    ? <Loader2 className="w-4 h-4 animate-spin" />
                    : <span>💧💩</span>}
                  둘다
                </button>
              </div>
              {diaperAddedMsg && (
                <p className="text-xs text-green-600 font-medium text-center">✅ {diaperAddedMsg}</p>
              )}
            </div>
          </div>
        )}

        {/* 모유 — 좌/우/양쪽 선택 */}
        {activity === "breast" && (
          <div className="space-y-3">
            <p className="text-sm text-gray-600 text-center">어느 쪽으로 수유했나요?</p>
            <div className="grid grid-cols-3 gap-2">
              {(["left", "right", "both"] as const).map((side) => {
                const labels = { left: "왼쪽", right: "오른쪽", both: "양쪽" };
                const emojis = { left: "◀", right: "▶", both: "◀▶" };
                return (
                  <button
                    key={side}
                    onClick={() => setBreastSide(side)}
                    className={`py-3 rounded-xl text-sm font-medium border-2 transition-all ${
                      breastSide === side
                        ? "bg-pink-50 border-pink-400 text-pink-700"
                        : "bg-white border-gray-200 text-gray-600"
                    }`}
                  >
                    <div className="text-lg mb-0.5">{emojis[side]}</div>
                    {labels[side]}
                  </button>
                );
              })}
            </div>
            <p className="text-xs text-gray-400 text-center">
              타이머는 수유 시작 후 ActiveSessionBanner에서 관리
            </p>
          </div>
        )}

        {/* 소변 / 대변 — 확인만 */}
        {(activity === "pee" || activity === "poo") && (
          <div className="text-center space-y-2 py-2">
            <div className="text-4xl">{activity === "pee" ? "💧" : "💩"}</div>
            <p className="text-sm text-gray-600">
              {isPast ? "아래 시각으로" : "지금 시각으로"} {activity === "pee" ? "소변" : "대변"} 기록할게요.
            </p>
            <p className="text-xs text-gray-400">
              색상·상태 등 세부 정보는{" "}
              <a href="/record/diaper" className="underline text-blue-400">
                기록 페이지
              </a>
              에서 추가할 수 있어요.
            </p>
          </div>
        )}

        {/* 수면 */}
        {activity === "sleep" && (
          <div className="text-center space-y-2 py-2">
            <div className="text-4xl">😴</div>
            {isPast ? (
              <p className="text-sm text-gray-600">시작·종료 시각을 입력해 수면을 기록해요.</p>
            ) : timerStore.getSession("sleep") ? (
              <p className="text-sm text-gray-600">진행 중인 수면 타이머를 종료할게요.</p>
            ) : (
              <>
                <p className="text-sm text-gray-600">지금부터 수면 타이머를 시작해요.</p>
                <p className="text-xs text-gray-400">
                  종료는 화면 상단 배너 또는 여기서 다시 길게 누르세요.
                </p>
              </>
            )}
          </div>
        )}

        {/* 놀이 */}
        {activity === "play" && (
          <div className="space-y-3">
            {!isPast && timerStore.getSession("play") ? (
              <div className="text-center py-2">
                <div className="text-4xl mb-2">🎈</div>
                <p className="text-sm text-gray-600">진행 중인 터미타임 타이머를 종료할게요.</p>
              </div>
            ) : (
              <>
                <p className="text-sm text-gray-600 text-center">어떤 터미타임을 할까요?</p>
                <div className="grid grid-cols-3 gap-2">
                  {PLAY_TYPES.map(({ value, label }) => (
                    <button
                      key={value}
                      onClick={() => setPlayType(value)}
                      className={`py-3 rounded-xl text-sm font-medium border-2 transition-all ${
                        playType === value
                          ? "bg-green-50 border-green-400 text-green-700"
                          : "bg-white border-gray-200 text-gray-600"
                      }`}
                    >
                      {label}
                    </button>
                  ))}
                </div>
              </>
            )}
          </div>
        )}

        {/* 기록 시간 */}
        {(activity === "formula" || activity === "breast" || activity === "pee" || activity === "poo") && (
          <TimeField label="기록 시간" value={recordTime} onChange={setRecordTime} />
        )}

        {/* 과거 모드의 수면/놀이: 시작 + 종료 시각 직접 입력 */}
        {isPast && (activity === "sleep" || activity === "play") && (
          <div className="space-y-3">
            <TimeField label="시작 시각" value={recordTime} onChange={setRecordTime} />
            <TimeField label="종료 시각 (선택)" value={endTime} onChange={setEndTime} />
          </div>
        )}

        {/* 저장 버튼 */}
        <button
          onClick={handleSave}
          disabled={isSaving || isSavingSleep || isEndingSleep || isSavingPlay}
          className="w-full py-3.5 bg-blue-500 text-white rounded-2xl font-semibold text-sm active:bg-blue-600 disabled:opacity-50 transition-colors"
        >
          {isSaving || isSavingSleep || isEndingSleep || isSavingPlay ? "저장 중..." : "저장"}
        </button>
      </div>
    </Dialog>
  );
}
