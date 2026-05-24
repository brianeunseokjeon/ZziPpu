"use client";

/**
 * RecordEditSheet — 기록 수정 시트.
 *
 * PATCH 엔드포인트 없으므로 "삭제 → 재생성" 패턴 사용.
 * 기록 시간, 양/종류 등 핵심 필드 수정 가능.
 */

import { useState } from "react";
import { Trash2, Loader2, Clock } from "lucide-react";
import { Dialog } from "@/shared/components/ui/dialog";
import { useUIStore } from "@/shared/stores/uiStore";
import { useDeleteFeeding, useCreateFeeding } from "@/features/feeding/api/feedingApi";
import { useDeleteDiaper, useCreateDiaper } from "@/features/diaper/api/diaperApi";
import { useDeleteSleep, useCreateSleep } from "@/features/sleep/api/sleepApi";
import { useDeletePlay, useCreatePlay } from "@/features/play/api/playApi";
import { FeedingType } from "@/features/feeding/types/feeding";
import { DiaperType } from "@/features/diaper/types/diaper";
import { isoToTimeInput, applyTimeInput } from "@/lib/date-utils";
import type { TimelineRecord } from "./RecordPopover";

interface Props {
  record: TimelineRecord | null;
  onClose: () => void;
}

/* ─── TimeField — 어디를 눌러도 네이티브 피커 열리는 시간 입력 ─ */

function TimeField({
  label,
  value,
  onChange,
}: {
  label: string;
  value: string;
  onChange: (v: string) => void;
}) {
  // 12h → 표시용 "오전/오후 H:MM"
  function displayTime(hhmm: string): string {
    if (!hhmm) return "시간 선택";
    const [h, m] = hhmm.split(":").map(Number);
    const period = h < 12 ? "오전" : "오후";
    const hour = h % 12 === 0 ? 12 : h % 12;
    return `${period} ${hour}:${String(m).padStart(2, "0")}`;
  }

  return (
    <div className="space-y-1">
      <p className="text-xs text-gray-500 font-medium">{label}</p>
      {/* 눌리는 영역 전체에 투명 input 덮기 */}
      <div className="relative">
        {/* 보이는 스타일 박스 */}
        <div className="w-full px-4 py-3 border border-gray-200 rounded-xl bg-white flex items-center justify-between pointer-events-none">
          <span className="text-sm font-medium text-gray-800">{displayTime(value)}</span>
          <Clock className="w-4 h-4 text-gray-400" />
        </div>
        {/* 전체 영역을 커버하는 투명 input — 탭 시 네이티브 피커 오픈 */}
        <input
          type="time"
          value={value}
          onChange={(e) => onChange(e.target.value)}
          className="absolute inset-0 w-full h-full opacity-0 cursor-pointer"
        />
      </div>
    </div>
  );
}

function diffMinutes(startISO: string, endISO: string): number {
  return Math.round((new Date(endISO).getTime() - new Date(startISO).getTime()) / 60000);
}

const ML_PRESETS = [60, 80, 100, 120, 150, 180, 210, 240];
const PLAY_TYPES = [
  { value: "tummy_time", label: "터미타임" },
  { value: "free_play", label: "자유놀이" },
  { value: "sensory_play", label: "감각놀이" },
] as const;

/* ─── 메인 ─────────────────────────────────────────────────── */

export function RecordEditSheet({ record, onClose }: Props) {
  const { activeBabyId } = useUIStore();
  const [saving, setSaving] = useState(false);
  const [deleting, setDeleting] = useState(false);

  const deleteFeeding = useDeleteFeeding();
  const createFeeding = useCreateFeeding();
  const deleteDiaper = useDeleteDiaper();
  const createDiaper = useCreateDiaper();
  const deleteSleep = useDeleteSleep();
  const createSleep = useCreateSleep();
  const deletePlay = useDeletePlay();
  const createPlay = useCreatePlay();

  // ─── 각 타입별 로컬 상태 ───────────────────────────────────
  const [formulaMl, setFormulaMl] = useState<number>(
    record?.kind === "feeding" ? (record.amountMl ?? 100) : 100
  );
  const [breastSide, setBreastSide] = useState<"left" | "right" | "both">(
    record?.kind === "feeding"
      ? record.type === "breast_left" ? "left"
        : record.type === "breast_right" ? "right"
        : "both"
      : "both"
  );
  const [diaperType, setDiaperType] = useState<"pee" | "poo" | "both">(
    record?.kind === "diaper" ? (record.type as "pee" | "poo" | "both") : "pee"
  );
  const [playType, setPlayType] = useState<"tummy_time" | "free_play" | "sensory_play">(
    record?.kind === "play" ? (record.playType as "tummy_time" | "free_play" | "sensory_play") : "tummy_time"
  );

  // 시간 입력
  const primaryISO = record
    ? record.kind === "diaper"
      ? record.recordedAt
      : record.startedAt
    : new Date().toISOString();

  const [startTime, setStartTime] = useState(isoToTimeInput(primaryISO));
  const [endTime, setEndTime] = useState(
    record?.kind === "sleep" || record?.kind === "play" || record?.kind === "feeding"
      ? record.endedAt ? isoToTimeInput(record.endedAt) : ""
      : ""
  );

  if (!record || !activeBabyId) return null;

  /* ─── 저장 (삭제 → 재생성) ─── */
  async function handleSave() {
    if (!record || !activeBabyId) return;
    setSaving(true);
    try {
      const startISO = applyTimeInput(primaryISO, startTime);
      const endISO = endTime ? applyTimeInput(primaryISO, endTime) : undefined;

      switch (record.kind) {
        case "feeding": {
          await deleteFeeding.mutateAsync({ babyId: activeBabyId, feedingId: record.id });
          const isFormula = record.type === "formula";
          if (isFormula) {
            await createFeeding.mutateAsync({
              babyId: activeBabyId,
              feedingType: FeedingType.Formula,
              amountMl: formulaMl,
              startedAt: startISO,
            });
          } else {
            const typeMap: Record<string, FeedingType> = {
              left: FeedingType.BreastLeft,
              right: FeedingType.BreastRight,
              both: FeedingType.BreastBoth,
            };
            await createFeeding.mutateAsync({
              babyId: activeBabyId,
              feedingType: typeMap[breastSide],
              startedAt: startISO,
              endedAt: endISO,
              durationMinutes: endISO ? diffMinutes(startISO, endISO) : undefined,
            });
          }
          break;
        }
        case "diaper": {
          await deleteDiaper.mutateAsync({ babyId: activeBabyId, diaperId: record.id });
          const typeMap: Record<string, DiaperType> = {
            pee: DiaperType.Pee,
            poo: DiaperType.Poop,
            both: DiaperType.Both,
          };
          await createDiaper.mutateAsync({
            babyId: activeBabyId,
            diaperType: typeMap[diaperType],
            recordedAt: startISO,
          });
          break;
        }
        case "sleep": {
          await deleteSleep.mutateAsync({ babyId: activeBabyId, sleepId: record.id });
          await createSleep.mutateAsync({
            babyId: activeBabyId,
            startedAt: startISO,
            endedAt: endISO,
          });
          break;
        }
        case "play": {
          await deletePlay.mutateAsync({ babyId: activeBabyId, playId: record.id });
          const duration = endISO ? Math.max(1, diffMinutes(startISO, endISO)) : 0;
          await createPlay.mutateAsync({
            babyId: activeBabyId,
            playType,
            durationMinutes: duration,
            startedAt: startISO,
            endedAt: endISO,
          });
          break;
        }
      }
      onClose();
    } finally {
      setSaving(false);
    }
  }

  /* ─── 삭제 ─── */
  async function handleDelete() {
    if (!record || !activeBabyId) return;
    setDeleting(true);
    try {
      switch (record.kind) {
        case "feeding":
          await deleteFeeding.mutateAsync({ babyId: activeBabyId, feedingId: record.id });
          break;
        case "diaper":
          await deleteDiaper.mutateAsync({ babyId: activeBabyId, diaperId: record.id });
          break;
        case "sleep":
          await deleteSleep.mutateAsync({ babyId: activeBabyId, sleepId: record.id });
          break;
        case "play":
          await deletePlay.mutateAsync({ babyId: activeBabyId, playId: record.id });
          break;
      }
      onClose();
    } finally {
      setDeleting(false);
    }
  }

  const titleMap: Record<string, string> = {
    formula: "🍼 분유 수정",
    breast_left: "🤱 모유 수정",
    breast_right: "🤱 모유 수정",
    breast_both: "🤱 모유 수정",
    pee: "💧 소변 수정",
    poo: "💩 대변 수정",
    both: "💧💩 배변 수정",
    sleep: "😴 수면 수정",
    play: "🎈 놀이 수정",
  };

  const title =
    record.kind === "feeding"
      ? titleMap[record.type] ?? "수유 수정"
      : record.kind === "diaper"
      ? titleMap[record.type] ?? "배변 수정"
      : titleMap[record.kind] ?? "수정";

  return (
    <Dialog open={!!record} onClose={onClose} title={title}>
      <div className="space-y-4">

        {/* ── 분유 ── */}
        {record.kind === "feeding" && record.type === "formula" && (
          <div className="space-y-3">
            <div className="text-center">
              <span className="text-3xl font-bold text-blue-600">{formulaMl}</span>
              <span className="text-sm text-gray-500 ml-1">ml</span>
            </div>
            <div className="flex items-center gap-2">
              <button
                onClick={() => setFormulaMl((v) => Math.max(10, v - 10))}
                className="w-9 h-9 rounded-full bg-gray-100 text-lg font-bold flex items-center justify-center"
              >−</button>
              <input
                type="range" min={10} max={300} step={10}
                value={formulaMl}
                onChange={(e) => setFormulaMl(Number(e.target.value))}
                className="flex-1 accent-blue-500"
              />
              <button
                onClick={() => setFormulaMl((v) => Math.min(300, v + 10))}
                className="w-9 h-9 rounded-full bg-gray-100 text-lg font-bold flex items-center justify-center"
              >+</button>
            </div>
            <div className="flex gap-1.5 flex-wrap justify-center">
              {ML_PRESETS.map((ml) => (
                <button
                  key={ml}
                  onClick={() => setFormulaMl(ml)}
                  className={`px-2.5 py-1 rounded-full text-xs font-medium border ${
                    formulaMl === ml
                      ? "bg-blue-500 text-white border-blue-500"
                      : "bg-white text-gray-600 border-gray-200"
                  }`}
                >{ml}ml</button>
              ))}
            </div>
          </div>
        )}

        {/* ── 모유 ── */}
        {record.kind === "feeding" && record.type !== "formula" && (
          <div className="space-y-2">
            <p className="text-xs text-gray-500">어느 쪽으로 수유했나요?</p>
            <div className="grid grid-cols-3 gap-2">
              {(["left", "right", "both"] as const).map((side) => {
                const labels = { left: "왼쪽", right: "오른쪽", both: "양쪽" };
                return (
                  <button
                    key={side}
                    onClick={() => setBreastSide(side)}
                    className={`py-2.5 rounded-xl text-sm font-medium border-2 ${
                      breastSide === side
                        ? "bg-pink-50 border-pink-400 text-pink-700"
                        : "bg-white border-gray-200 text-gray-600"
                    }`}
                  >{labels[side]}</button>
                );
              })}
            </div>
          </div>
        )}

        {/* ── 배변 종류 ── */}
        {record.kind === "diaper" && (
          <div className="space-y-2">
            <p className="text-xs text-gray-500">배변 종류</p>
            <div className="grid grid-cols-3 gap-2">
              {([["pee", "💧 소변"], ["poo", "💩 대변"], ["both", "💧💩 둘다"]] as const).map(([val, lbl]) => (
                <button
                  key={val}
                  onClick={() => setDiaperType(val)}
                  className={`py-2.5 rounded-xl text-xs font-medium border-2 ${
                    diaperType === val
                      ? "bg-yellow-50 border-yellow-400 text-yellow-800"
                      : "bg-white border-gray-200 text-gray-600"
                  }`}
                >{lbl}</button>
              ))}
            </div>
          </div>
        )}

        {/* ── 놀이 종류 ── */}
        {record.kind === "play" && (
          <div className="space-y-2">
            <p className="text-xs text-gray-500">놀이 종류</p>
            <div className="grid grid-cols-3 gap-2">
              {PLAY_TYPES.map(({ value, label }) => (
                <button
                  key={value}
                  onClick={() => setPlayType(value)}
                  className={`py-2.5 rounded-xl text-sm font-medium border-2 ${
                    playType === value
                      ? "bg-green-50 border-green-400 text-green-700"
                      : "bg-white border-gray-200 text-gray-600"
                  }`}
                >{label}</button>
              ))}
            </div>
          </div>
        )}

        {/* ── 시간 입력 ── */}
        <div className="space-y-2.5">
          <TimeField
            label={record.kind === "diaper" ? "기록 시간" : "시작 시간"}
            value={startTime}
            onChange={setStartTime}
          />

          {/* 종료 시간 (모유/수면/놀이) */}
          {(record.kind === "sleep" || record.kind === "play" ||
            (record.kind === "feeding" && record.type !== "formula")) && (
            <TimeField
              label="종료 시간 (선택)"
              value={endTime}
              onChange={setEndTime}
            />
          )}
        </div>

        {/* ── 저장/삭제 버튼 ── */}
        <div className="flex gap-2 pt-1">
          <button
            onClick={handleDelete}
            disabled={deleting || saving}
            className="flex items-center justify-center gap-1.5 px-4 py-3 bg-red-50 text-red-500 rounded-xl text-sm font-medium disabled:opacity-50"
          >
            {deleting
              ? <Loader2 className="w-4 h-4 animate-spin" />
              : <Trash2 className="w-4 h-4" />}
            삭제
          </button>
          <button
            onClick={handleSave}
            disabled={saving || deleting}
            className="flex-1 py-3 bg-blue-500 text-white rounded-xl text-sm font-semibold disabled:opacity-50"
          >
            {saving ? "저장 중..." : "저장"}
          </button>
        </div>
      </div>
    </Dialog>
  );
}
