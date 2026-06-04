"use client";

import { useState } from "react";
import { Button } from "@/shared/components/ui/button";
import { Input } from "@/shared/components/ui/input";
import { useCreateGrowthRecord } from "../api/growthApi";
import { useUIStore } from "@/shared/stores/uiStore";

export function GrowthForm() {
  const { mutate: createRecord, isPending } = useCreateGrowthRecord();
  const activeBabyId = useUIStore((s) => s.activeBabyId);

  const [recordedAt, setRecordedAt] = useState(() => {
    const now = new Date();
    return now.toISOString().slice(0, 10);
  });
  const [weightG, setWeightG] = useState("");
  const [heightCm, setHeightCm] = useState("");
  const [headCm, setHeadCm] = useState("");
  const [memo, setMemo] = useState("");

  function handleSave() {
    const hasData = weightG || heightCm || headCm;
    if (!hasData) return;

    createRecord(
      {
        babyId: activeBabyId,
        data: {
          recorded_at: recordedAt,
          weight_g: weightG ? parseFloat(weightG) : null,
          height_cm: heightCm ? parseFloat(heightCm) : null,
          head_circumference_cm: headCm ? parseFloat(headCm) : null,
          memo: memo || null,
        },
      },
      {
        onSuccess: () => {
          setWeightG("");
          setHeightCm("");
          setHeadCm("");
          setMemo("");
        },
      }
    );
  }

  return (
    <div className="space-y-4">
      <div>
        <p className="text-sm font-medium text-gray-700 mb-1.5">측정 날짜</p>
        <Input
          type="date"
          value={recordedAt}
          onChange={(e) => setRecordedAt(e.target.value)}
        />
      </div>

      <div className="grid grid-cols-3 gap-3">
        <div>
          <p className="text-sm font-medium text-gray-700 mb-1.5">
            체중 (g)
          </p>
          <Input
            type="number"
            placeholder="예: 4200"
            value={weightG}
            onChange={(e) => setWeightG(e.target.value)}
            min={0}
            step={1}
          />
        </div>
        <div>
          <p className="text-sm font-medium text-gray-700 mb-1.5">키 (cm)</p>
          <Input
            type="number"
            placeholder="예: 52.5"
            value={heightCm}
            onChange={(e) => setHeightCm(e.target.value)}
            min={0}
            step={0.1}
          />
        </div>
        <div>
          <p className="text-sm font-medium text-gray-700 mb-1.5">
            머리둘레 (cm)
          </p>
          <Input
            type="number"
            placeholder="예: 34.0"
            value={headCm}
            onChange={(e) => setHeadCm(e.target.value)}
            min={0}
            step={0.1}
          />
        </div>
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
        disabled={isPending || (!weightG && !heightCm && !headCm)}
        className="w-full h-12 text-base bg-purple-500 hover:bg-purple-600"
      >
        {isPending ? "저장 중..." : "저장"}
      </Button>
    </div>
  );
}
