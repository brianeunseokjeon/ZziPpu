"use client";

import { useState } from "react";
import { Calculator, ArrowRight } from "lucide-react";
import { Input } from "@/shared/components/ui/input";
import { useBabyInfo } from "@/features/baby/hooks/useBabyInfo";
import {
  formatKoreanDate,
  getAgeDaysForDate,
  getDateForAgeDays,
} from "@/lib/milestoneMath";

type Mode = "daysToDate" | "dateToDays";

export function DateCalculator() {
  const { birthDate, name } = useBabyInfo();
  const [mode, setMode] = useState<Mode>("daysToDate");
  const [inputDays, setInputDays] = useState<number | "">("");
  const [inputDate, setInputDate] = useState("");

  const resultDate =
    mode === "daysToDate" && inputDays !== "" && inputDays > 0
      ? getDateForAgeDays(birthDate, Number(inputDays))
      : null;

  const resultDays =
    mode === "dateToDays" && inputDate
      ? getAgeDaysForDate(birthDate, inputDate)
      : null;

  return (
    <div className="bg-white rounded-2xl p-4 shadow-sm border border-gray-100 space-y-3">
      <div className="flex items-center gap-2">
        <Calculator className="w-4 h-4 text-indigo-500" />
        <h3 className="text-sm font-semibold text-gray-800">날짜 계산기</h3>
      </div>

      <div className="flex gap-1 bg-gray-100 p-1 rounded-xl text-xs">
        <button
          onClick={() => setMode("daysToDate")}
          className={`flex-1 py-1.5 rounded-lg transition ${
            mode === "daysToDate"
              ? "bg-white text-indigo-600 font-semibold shadow-sm"
              : "text-gray-500"
          }`}
        >
          생후 N일 → 날짜
        </button>
        <button
          onClick={() => setMode("dateToDays")}
          className={`flex-1 py-1.5 rounded-lg transition ${
            mode === "dateToDays"
              ? "bg-white text-indigo-600 font-semibold shadow-sm"
              : "text-gray-500"
          }`}
        >
          날짜 → 생후 며칠
        </button>
      </div>

      {mode === "daysToDate" ? (
        <div className="space-y-2">
          <label className="block">
            <span className="text-xs text-gray-500">생후 일수</span>
            <Input
              type="number"
              min={1}
              max={3000}
              placeholder="예: 100"
              value={inputDays}
              onChange={(e) =>
                setInputDays(e.target.value === "" ? "" : Number(e.target.value))
              }
              className="mt-1"
            />
          </label>
          {resultDate && (
            <div className="bg-indigo-50 rounded-xl p-3 flex items-center justify-between">
              <div>
                <div className="text-xs text-gray-500">{name}, 생후 {inputDays}일</div>
                <div className="text-base font-semibold text-indigo-700 mt-0.5">
                  {formatKoreanDate(resultDate)}
                </div>
              </div>
              <ArrowRight className="w-4 h-4 text-indigo-300" />
            </div>
          )}
        </div>
      ) : (
        <div className="space-y-2">
          <label className="block">
            <span className="text-xs text-gray-500">날짜</span>
            <Input
              type="date"
              value={inputDate}
              onChange={(e) => setInputDate(e.target.value)}
              className="mt-1"
            />
          </label>
          {resultDays !== null && (
            <div className="bg-indigo-50 rounded-xl p-3 flex items-center justify-between">
              <div>
                <div className="text-xs text-gray-500">그날 {name}는</div>
                <div className="text-base font-semibold text-indigo-700 mt-0.5">
                  {resultDays < 1
                    ? `출생 ${1 - resultDays}일 전`
                    : `생후 ${resultDays}일 (약 ${Math.floor((resultDays - 1) / 30)}개월)`}
                </div>
              </div>
              <ArrowRight className="w-4 h-4 text-indigo-300" />
            </div>
          )}
        </div>
      )}
    </div>
  );
}
