"use client";

import { useState } from "react";
import { Button } from "@/shared/components/ui/button";
import { Input } from "@/shared/components/ui/input";
import { useCreateDiaper } from "../api/diaperApi";
import { DiaperType, StoolColor, StoolState } from "../types/diaper";
import { useUIStore } from "@/shared/stores/uiStore";
import { STOOL_COLORS, STOOL_STATES } from "@/config/constants";
import { cn } from "@/lib/utils";

export function DiaperForm() {
  const { activeBabyId } = useUIStore();
  const { mutate: createDiaper, isPending } = useCreateDiaper();

  const [type, setType] = useState<DiaperType>(DiaperType.Pee);
  const [stoolColor, setStoolColor] = useState<StoolColor | undefined>();
  const [stoolState, setStoolState] = useState<StoolState | undefined>();
  const [memo, setMemo] = useState("");
  const [occurredAt, setOccurredAt] = useState(() => {
    return new Date().toISOString().slice(0, 16);
  });

  const hasPoop = type === DiaperType.Poop || type === DiaperType.Both;

  function handleSave() {
    createDiaper({
      babyId: activeBabyId,
      diaperType: type,
      stoolColor: hasPoop ? stoolColor : undefined,
      stoolState: hasPoop ? stoolState : undefined,
      recordedAt: new Date(occurredAt).toISOString(),
      memo: memo || undefined,
    });
    setMemo("");
    setStoolColor(undefined);
    setStoolState(undefined);
  }

  return (
    <div className="space-y-5">
      <div>
        <p className="text-sm font-medium text-gray-700 mb-2">종류</p>
        <div className="flex gap-3">
          {[
            { value: DiaperType.Pee, label: "소변", emoji: "💧" },
            { value: DiaperType.Poop, label: "대변", emoji: "💩" },
            { value: DiaperType.Both, label: "둘 다", emoji: "💧💩" },
          ].map(({ value, label, emoji }) => (
            <button
              key={value}
              onClick={() => setType(value)}
              className={cn(
                "flex-1 flex flex-col items-center py-4 rounded-2xl border-2 transition-all",
                type === value
                  ? "border-orange-400 bg-orange-50 text-orange-700"
                  : "border-gray-100 bg-white text-gray-600 hover:border-gray-200"
              )}
            >
              <span className="text-2xl mb-1">{emoji}</span>
              <span className="text-sm font-medium">{label}</span>
            </button>
          ))}
        </div>
      </div>

      {hasPoop && (
        <>
          <div>
            <p className="text-sm font-medium text-gray-700 mb-2">색상</p>
            <div className="flex gap-2 flex-wrap">
              {STOOL_COLORS.map(({ value, label, hex }) => (
                <button
                  key={value}
                  onClick={() => setStoolColor(value as StoolColor)}
                  className={cn(
                    "flex items-center gap-2 px-3 py-2 rounded-xl border-2 transition-all",
                    stoolColor === value
                      ? "border-gray-700 bg-gray-50"
                      : "border-gray-100 bg-white hover:border-gray-300"
                  )}
                >
                  <span
                    className="w-5 h-5 rounded-full border border-gray-200 flex-shrink-0"
                    style={{ backgroundColor: hex }}
                  />
                  <span className="text-sm text-gray-700">{label}</span>
                </button>
              ))}
            </div>
          </div>

          <div>
            <p className="text-sm font-medium text-gray-700 mb-2">상태</p>
            <div className="flex gap-2">
              {STOOL_STATES.map(({ value, label }) => (
                <button
                  key={value}
                  onClick={() => setStoolState(value as StoolState)}
                  className={cn(
                    "flex-1 py-2.5 rounded-xl text-sm font-medium border-2 transition-all",
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

      <div>
        <p className="text-sm font-medium text-gray-700 mb-1.5">기록 시간 (과거 날짜 입력 가능)</p>
        <Input
          type="datetime-local"
          value={occurredAt}
          max={new Date().toISOString().slice(0, 16)}
          onChange={(e) => setOccurredAt(e.target.value)}
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
        className="w-full h-14 text-lg bg-orange-400 hover:bg-orange-500"
      >
        {isPending ? "저장 중..." : "저장"}
      </Button>
    </div>
  );
}
