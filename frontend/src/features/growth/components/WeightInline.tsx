"use client";

import { useState } from "react";
import { Scale, Check, X, Pencil } from "lucide-react";
import { useCreateGrowthRecord } from "../api/growthApi";
import { todayDateString } from "@/lib/date-utils";

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

  function save() {
    const kg = parseFloat(val);
    if (!kg || kg <= 0 || kg > 50) return;
    create.mutate(
      {
        babyId,
        data: { recorded_at: todayDateString(), weight_g: Math.round(kg * 1000) },
      },
      {
        onError: (err) => console.error("[WeightInline] 체중 저장 실패", err),
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
      {weightG ? (
        <>
          <span className="font-semibold text-gray-800">{(weightG / 1000).toFixed(2)}kg</span>
          <Pencil className="w-3 h-3 text-gray-300" />
        </>
      ) : (
        <span className="text-blue-500 font-medium">체중 입력</span>
      )}
    </button>
  );
}
