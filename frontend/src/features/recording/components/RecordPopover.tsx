"use client";

/**
 * RecordPopover — 타임라인 그리드의 점/막대 탭 시 표시되는 상세 + 삭제.
 *
 * Dialog 기반 (bottom sheet 또는 center modal — 화면 크기에 따라 자동).
 */

import { useState } from "react";
import { Trash2, Loader2 } from "lucide-react";
import { Dialog } from "@/shared/components/ui/dialog";
import { formatTime } from "@/lib/date-utils";
import { useUIStore } from "@/shared/stores/uiStore";
import { useDeleteFeeding } from "@/features/feeding/api/feedingApi";
import { useDeleteDiaper } from "@/features/diaper/api/diaperApi";
import { useDeleteSleep } from "@/features/sleep/api/sleepApi";
import { useDeletePlay } from "@/features/play/api/playApi";

export type TimelineRecord =
  | { kind: "feeding"; id: string; startedAt: string; endedAt?: string; type: string; amountMl?: number; durationMinutes?: number; memo?: string }
  | { kind: "diaper"; id: string; recordedAt: string; type: string; stoolColor?: string; stoolState?: string; memo?: string }
  | { kind: "sleep"; id: string; startedAt: string; endedAt?: string; durationMinutes?: number; memo?: string }
  | { kind: "play"; id: string; startedAt: string; endedAt?: string; playType: string; durationMinutes: number; memo?: string };

interface Props {
  record: TimelineRecord | null;
  onClose: () => void;
}

const FEEDING_LABEL: Record<string, string> = {
  formula: "🍼 분유",
  breast_left: "🤱 모유 왼쪽",
  breast_right: "🤱 모유 오른쪽",
  breast_both: "🤱 모유 양쪽",
};
const DIAPER_LABEL: Record<string, string> = {
  pee: "💧 소변",
  poo: "💩 대변",
  both: "💧💩 둘 다",
};
const PLAY_LABEL: Record<string, string> = {
  tummy_time: "🤸 터미타임",
  free_play: "🎈 자유놀이",
  sensory_play: "🌈 감각놀이",
};

export function RecordPopover({ record, onClose }: Props) {
  const { activeBabyId } = useUIStore();
  const [isDeleting, setIsDeleting] = useState(false);
  const deleteFeeding = useDeleteFeeding();
  const deleteDiaper = useDeleteDiaper();
  const deleteSleep = useDeleteSleep();
  const deletePlay = useDeletePlay();

  if (!record) return null;

  async function handleDelete() {
    if (!record || !activeBabyId || isDeleting) return;
    setIsDeleting(true);
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
      setIsDeleting(false);
    }
  }

  let title = "";
  let details: React.ReactNode = null;
  let timeText = "";

  switch (record.kind) {
    case "feeding": {
      title = FEEDING_LABEL[record.type] ?? "수유";
      timeText = formatTime(record.startedAt);
      details = (
        <div className="space-y-1 text-sm text-gray-700">
          {record.amountMl != null && <p>양: {record.amountMl}ml</p>}
          {record.durationMinutes != null && <p>지속: {record.durationMinutes}분</p>}
          {record.endedAt && <p>종료: {formatTime(record.endedAt)}</p>}
        </div>
      );
      break;
    }
    case "diaper": {
      title = DIAPER_LABEL[record.type] ?? "배변";
      timeText = formatTime(record.recordedAt);
      details = (
        <div className="space-y-1 text-sm text-gray-700">
          {record.stoolColor && <p>색상: {record.stoolColor}</p>}
          {record.stoolState && <p>상태: {record.stoolState}</p>}
        </div>
      );
      break;
    }
    case "sleep": {
      title = "😴 수면";
      timeText = `${formatTime(record.startedAt)}${record.endedAt ? ` ~ ${formatTime(record.endedAt)}` : " (진행 중)"}`;
      details = (
        <div className="space-y-1 text-sm text-gray-700">
          {record.durationMinutes != null && <p>지속: {record.durationMinutes}분</p>}
        </div>
      );
      break;
    }
    case "play": {
      title = PLAY_LABEL[record.playType] ?? "🎈 터미타임";
      timeText = `${formatTime(record.startedAt)}${record.endedAt ? ` ~ ${formatTime(record.endedAt)}` : ""}`;
      details = (
        <div className="space-y-1 text-sm text-gray-700">
          <p>지속: {record.durationMinutes}분</p>
        </div>
      );
      break;
    }
  }

  return (
    <Dialog open={!!record} onClose={onClose} title={title}>
      <div className="space-y-3">
        <div>
          <p className="text-xs text-gray-400">시간</p>
          <p className="text-sm font-medium text-gray-800">{timeText}</p>
        </div>
        {details}
        {record.memo && (
          <div>
            <p className="text-xs text-gray-400">메모</p>
            <p className="text-sm text-gray-700">{record.memo}</p>
          </div>
        )}
        <button
          onClick={handleDelete}
          disabled={isDeleting}
          className="w-full flex items-center justify-center gap-2 py-2.5 bg-red-50 text-red-600 rounded-xl text-sm font-medium hover:bg-red-100 disabled:opacity-50"
        >
          {isDeleting ? <Loader2 className="w-4 h-4 animate-spin" /> : <Trash2 className="w-4 h-4" />}
          삭제
        </button>
      </div>
    </Dialog>
  );
}
