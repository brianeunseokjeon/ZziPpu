"use client";

import { useState } from "react";
import { Minus, Plus, Trash2 } from "lucide-react";
import { Dialog } from "@/shared/components/ui/dialog";
import { Button } from "@/shared/components/ui/button";
import { Input } from "@/shared/components/ui/input";
import { TimeField } from "@/shared/components/ui/time-field";
import { useUpdateFeeding, useDeleteFeeding } from "../api/feedingApi";
import { Feeding, FeedingType } from "../types/feeding";
import {
  isoToTimeInput,
  getDateString,
  applyTimeInput,
} from "@/lib/date-utils";
import { cn } from "@/lib/utils";

const FEEDING_LABELS: Record<FeedingType, string> = {
  [FeedingType.Formula]: "분유",
  [FeedingType.BreastLeft]: "모유(좌)",
  [FeedingType.BreastRight]: "모유(우)",
  [FeedingType.BreastBoth]: "모유(양쪽)",
};

/** "HH:MM" 에 분 단위 가감 (24h wrap) */
function shiftTime(hhmm: string, deltaMin: number): string {
  const [h, m] = hhmm.split(":").map(Number);
  let total = (h * 60 + m + deltaMin) % (24 * 60);
  if (total < 0) total += 24 * 60;
  const nh = Math.floor(total / 60);
  const nm = total % 60;
  return `${String(nh).padStart(2, "0")}:${String(nm).padStart(2, "0")}`;
}

export function FeedingEditModal({
  feeding,
  onClose,
}: {
  feeding: Feeding;
  onClose: () => void;
}) {
  const { mutateAsync: updateFeeding, isPending } = useUpdateFeeding();
  const { mutate: deleteFeeding } = useDeleteFeeding();

  const [timeStr, setTimeStr] = useState(() => isoToTimeInput(feeding.startedAt));
  const [dateStr, setDateStr] = useState(() => getDateString(feeding.startedAt));
  const [amountInput, setAmountInput] = useState(
    feeding.amountMl ? String(feeding.amountMl) : ""
  );
  const [durationInput, setDurationInput] = useState(
    feeding.durationMinutes ? String(feeding.durationMinutes) : ""
  );
  const [memo, setMemo] = useState(feeding.memo ?? "");

  const isFormula = feeding.feedingType === FeedingType.Formula;

  function handleDelete() {
    onClose();
    deleteFeeding({ babyId: feeding.babyId, feedingId: feeding.id });
  }

  async function handleSave() {
    // 선택된 KST 날짜 정오를 기준으로 시간만 교체 → UTC ISO
    const baseISO = new Date(`${dateStr}T12:00:00+09:00`).toISOString();
    const startedAt = applyTimeInput(baseISO, timeStr);

    const amountMl = amountInput ? Math.max(1, parseInt(amountInput, 10)) : undefined;
    const durationMinutes = durationInput
      ? Math.max(1, parseInt(durationInput, 10))
      : undefined;

    try {
      await updateFeeding({
        babyId: feeding.babyId,
        feedingId: feeding.id,
        feedingType: feeding.feedingType,
        startedAt,
        amountMl: isFormula ? amountMl : undefined,
        durationMinutes: isFormula ? undefined : durationMinutes,
        memo: memo.trim() || undefined,
      });
      onClose();
    } catch {
      // optimisticUpdateOptions.onError 가 이미 에러 토스트 처리 — 여기서 중복 토스트 금지
    }
  }

  return (
    <Dialog open onClose={onClose} title={`${FEEDING_LABELS[feeding.feedingType]} 기록 수정`}>
      <div className="space-y-5">
        {/* 시간 — 쉽게 수정: 전체 탭으로 피커 + 빠른 가감 */}
        <div className="space-y-2">
          <TimeField label="기록 시간" value={timeStr} onChange={setTimeStr} />
          {/* 빠른 가감 버튼 */}
          <div className="flex gap-1.5">
            {[-30, -10, -5, +5, +10, +30].map((d) => (
              <button
                key={d}
                onClick={() => setTimeStr((t) => shiftTime(t, d))}
                className="flex-1 py-1.5 rounded-lg text-xs font-medium bg-gray-50 text-gray-600 border border-gray-200 hover:bg-gray-100 active:scale-95 transition-all"
              >
                {d > 0 ? `+${d}` : d}분
              </button>
            ))}
          </div>
        </div>

        {/* 날짜 */}
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

        {/* 분유: 수유량 / 모유: 수유시간(분) */}
        {isFormula ? (
          <div>
            <p className="text-xs text-gray-500 font-medium mb-1.5">수유량 (ml)</p>
            <div className="flex items-center gap-3">
              <button
                onClick={() =>
                  setAmountInput((v) =>
                    String(Math.max(0, (parseInt(v || "0", 10) || 0) - 10))
                  )
                }
                className="w-11 h-11 rounded-full bg-blue-50 flex items-center justify-center text-blue-500"
              >
                <Minus className="w-5 h-5" />
              </button>
              <Input
                type="number"
                value={amountInput}
                onChange={(e) => setAmountInput(e.target.value)}
                className="text-center text-2xl font-bold tabular-nums h-14"
                min={0}
                max={500}
              />
              <button
                onClick={() =>
                  setAmountInput((v) =>
                    String(Math.min(500, (parseInt(v || "0", 10) || 0) + 10))
                  )
                }
                className="w-11 h-11 rounded-full bg-blue-50 flex items-center justify-center text-blue-500"
              >
                <Plus className="w-5 h-5" />
              </button>
            </div>
            <div className="flex gap-2 flex-wrap mt-2">
              {[60, 80, 100, 120, 150, 180].map((v) => (
                <button
                  key={v}
                  onClick={() => setAmountInput(String(v))}
                  className={cn(
                    "px-3 py-1.5 rounded-full text-sm font-medium border",
                    amountInput === String(v)
                      ? "bg-blue-400 text-white border-blue-400"
                      : "bg-white text-gray-600 border-gray-200"
                  )}
                >
                  {v}ml
                </button>
              ))}
            </div>
          </div>
        ) : (
          <div>
            <p className="text-xs text-gray-500 font-medium mb-1.5">
              수유 시간 (분) <span className="text-gray-400">옵셔널</span>
            </p>
            <Input
              type="number"
              min={1}
              max={120}
              placeholder="예: 15"
              value={durationInput}
              onChange={(e) => setDurationInput(e.target.value)}
            />
          </div>
        )}

        {/* 메모 */}
        <div>
          <p className="text-xs text-gray-500 font-medium mb-1.5">메모 (선택)</p>
          <Input value={memo} onChange={(e) => setMemo(e.target.value)} />
        </div>

        <div className="flex gap-2 pt-1">
          <button
            type="button"
            onClick={handleDelete}
            className="p-3 rounded-xl border border-red-200 text-red-400 hover:bg-red-50 active:bg-red-100 transition-colors flex-shrink-0"
          >
            <Trash2 className="w-5 h-5" />
          </button>
          <Button variant="outline" onClick={onClose} className="flex-1 h-12">취소</Button>
          <Button onClick={handleSave} disabled={isPending} className="flex-1 h-12 bg-blue-500 hover:bg-blue-600">
            {isPending ? "저장 중..." : "수정 완료"}
          </Button>
        </div>
      </div>
    </Dialog>
  );
}
