"use client";

import { useState } from "react";
import {
  LineChart,
  Line,
  XAxis,
  YAxis,
  CartesianGrid,
  Tooltip,
  ResponsiveContainer,
} from "recharts";
import { useGrowthRecords } from "../api/growthApi";
import { useUIStore } from "@/shared/stores/uiStore";
import { useBabyInfo } from "@/features/baby/hooks/useBabyInfo";

type MetricKey = "weight" | "height" | "head";

const TABS: { key: MetricKey; label: string; unit: string }[] = [
  { key: "weight", label: "체중", unit: "kg" },
  { key: "height", label: "키", unit: "cm" },
  { key: "head", label: "머리둘레", unit: "cm" },
];

export function GrowthChart() {
  const [activeTab, setActiveTab] = useState<MetricKey>("weight");
  const { birthDate } = useBabyInfo();
  const activeBabyId = useUIStore((s) => s.activeBabyId);
  const { data: records, isLoading } = useGrowthRecords(activeBabyId);

  function getBirthDays(recordedAt: string): number {
    const birth = new Date(birthDate);
    const recordDate = new Date(recordedAt);
    const diff = Math.floor(
      (recordDate.getTime() - birth.getTime()) / (1000 * 60 * 60 * 24)
    );
    return diff + 1;
  }

  if (isLoading) {
    return (
      <div className="h-52 bg-gray-100 rounded-2xl animate-pulse" />
    );
  }

  const sorted = [...(records ?? [])].sort(
    (a, b) =>
      new Date(a.recordedAt).getTime() - new Date(b.recordedAt).getTime()
  );

  const chartData = sorted
    .map((r) => {
      const dayNum = getBirthDays(r.recordedAt);
      const raw =
        activeTab === "weight"
          ? r.weightG
          : activeTab === "height"
          ? r.heightCm
          : r.headCircumferenceCm;

      if (raw === null || raw === undefined) return null;

      const value =
        activeTab === "weight" ? parseFloat((raw / 1000).toFixed(3)) : raw;

      return { day: `D+${dayNum}`, value };
    })
    .filter(Boolean) as { day: string; value: number }[];

  const currentTab = TABS.find((t) => t.key === activeTab)!;

  return (
    <div className="space-y-3">
      <div className="flex rounded-xl bg-gray-100 p-1">
        {TABS.map((tab) => (
          <button
            key={tab.key}
            onClick={() => setActiveTab(tab.key)}
            className={`flex-1 py-1.5 rounded-lg text-sm font-medium transition-all ${
              activeTab === tab.key
                ? "bg-white text-purple-700 shadow-sm"
                : "text-gray-500"
            }`}
          >
            {tab.label}
          </button>
        ))}
      </div>

      {chartData.length === 0 ? (
        <div className="flex flex-col items-center justify-center h-44 text-gray-400">
          <p className="text-3xl mb-2">🌱</p>
          <p className="text-sm">기록이 없어요</p>
        </div>
      ) : (
        <ResponsiveContainer width="100%" height={200}>
          <LineChart
            data={chartData}
            margin={{ top: 8, right: 16, left: 0, bottom: 8 }}
          >
            <CartesianGrid strokeDasharray="3 3" stroke="#f0f0f0" />
            <XAxis
              dataKey="day"
              tick={{ fontSize: 11, fill: "#9ca3af" }}
              axisLine={false}
              tickLine={false}
            />
            <YAxis
              tick={{ fontSize: 11, fill: "#9ca3af" }}
              axisLine={false}
              tickLine={false}
              width={40}
              tickFormatter={(v) => `${v}`}
            />
            <Tooltip
              formatter={(value) => [
                `${value} ${currentTab.unit}`,
                currentTab.label,
              ]}
              contentStyle={{
                borderRadius: "12px",
                border: "1px solid #e5e7eb",
                fontSize: "12px",
              }}
            />
            <Line
              type="monotone"
              dataKey="value"
              stroke="#a855f7"
              strokeWidth={2.5}
              dot={{ fill: "#a855f7", r: 4, strokeWidth: 0 }}
              activeDot={{ r: 6, fill: "#7c3aed" }}
            />
          </LineChart>
        </ResponsiveContainer>
      )}
    </div>
  );
}
