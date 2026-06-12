"use client";

import { useState, useEffect } from "react";
import { Scale, Check, X, Pencil } from "lucide-react";
import { useCreateGrowthRecord } from "../api/growthApi";
import { todayDateString } from "@/lib/date-utils";
import { toast } from "@/shared/stores/toastStore";

/** 체중 인라인 입력/표시 (kg 단위 입력 → g 저장). */
export function WeightInline({
  babyId,
  weightG,
}: {
  babyId: string;
  weightG: number | null;
}) {
  const create = useCreateGrowthRecord();
  const [editing, setEditing] = useState(false);
  const [val, setVal] = useState("");
  // 저장 즉시 로컬 표시용 대기 체중
  // onSuccess에서 지우면 props(weightG) 업데이트 전 순간 null이 되어 "체중 입력"이 깜빡임 →
  // 대신 weightG prop이 pendingWeightG와 같아질 때(캐시 갱신 완료) useEffect로 클리어
  const [pendingWeightG, setPendingWeightG] = useState<number | null>(null);
  const displayWeightG = pendingWeightG ?? weightG;

  // 서버 응답 후 캐시가 갱신되어 weightG prop이 저장한 값으로 오면 pending 해제
  useEffect(() => {
    if (pendingWeightG !== null && weightG === pendingWeightG) {
      setPendingWeightG(null);
    }
  }, [weightG, pendingWeightG]);

  function save() {
    const kg = parseFloat(val);
    if (!kg || kg <= 0 || kg > 50) return;
    const newWeightG = Math.round(kg * 1000);
    setPendingWeightG(newWeightG); // 즉시 로컬 반영
    create.mutate(
      {
        babyId,
        data: { recordedAt: todayDateString(), weightG: newWeightG },
      },
      {
        onError: (err) => {
          setPendingWeightG(null); // 실패 시 롤백
          toast("체중을 저장하지 못했어요. 다시 시도해 주세요.", "error");
          console.error("[WeightInline] 체중 저장 실패", err);
        },
      }
    );
    setEditing(false);
    setVal("");
  }

  if (editing) {
    return (
      <div className="flex items-center gap-1.5">
        <input
          type="number"
          inputMode="decimal"
          step="0.01"
          value={val}
          onChange={(e) => setVal(e.target.value)}
          onKeyDown={(e) => e.key === "Enter" && save()}
          placeholder="예: 4.20"
          autoFocus
          className="w-20 text-sm border border-gray-200 rounded-lg px-2 py-1 text-right focus:outline-none focus:ring-2 focus:ring-blue-400"
        />
        <span className="text-xs text-gray-400">kg</span>
        <button
          onClick={save}
          disabled={create.isPending}
          className="p-1 text-green-500 hover:bg-green-50 rounded disabled:opacity-40"
        >
          <Check className="w-4 h-4" />
        </button>
        <button
          onClick={() => setEditing(false)}
          className="p-1 text-gray-400 hover:bg-gray-50 rounded"
        >
          <X className="w-4 h-4" />
        </button>
      </div>
    );
  }

  return (
    <button
      onClick={() => {
        setVal(weightG ? (weightG / 1000).toFixed(2) : "");
        setEditing(true);
      }}
      className="flex items-center gap-1.5 text-sm text-gray-600 hover:bg-gray-50 rounded-lg px-2 py-1 transition-colors"
    >
      <Scale className="w-3.5 h-3.5 text-gray-400" />
      {displayWeightG ? (
        <>
          <span className="font-semibold text-gray-800">{(displayWeightG / 1000).toFixed(2)}kg</span>
          <Pencil className="w-3 h-3 text-gray-300" />
        </>
      ) : (
        <span className="text-blue-500 font-medium">체중 입력</span>
      )}
    </button>
  );
}
