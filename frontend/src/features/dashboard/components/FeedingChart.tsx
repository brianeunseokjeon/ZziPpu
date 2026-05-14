"use client";

import {
  BarChart,
  Bar,
  XAxis,
  YAxis,
  CartesianGrid,
  Tooltip,
  ResponsiveContainer,
} from "recharts";
import { useFeedings } from "@/features/feeding/api/feedingApi";
import { useUIStore } from "@/shared/stores/uiStore";
import { FeedingType } from "@/features/feeding/types/feeding";
import { Card, CardHeader, CardTitle, CardContent } from "@/shared/components/ui/card";

interface HourlyData {
  hour: string;
  ml: number;
}

export function FeedingChart() {
  const { activeBabyId, selectedDate } = useUIStore();
  const { data: feedings, isLoading } = useFeedings(activeBabyId, selectedDate);

  const hourlyData: HourlyData[] = Array.from({ length: 24 }, (_, i) => ({
    hour: `${i}시`,
    ml: 0,
  }));

  if (feedings) {
    feedings.forEach((f) => {
      if (f.type === FeedingType.Formula && f.amountMl) {
        const hour = new Date(f.startedAt).getHours();
        hourlyData[hour].ml += f.amountMl;
      }
    });
  }

  const nonZero = hourlyData.filter((d) => d.ml > 0);
  const chartData = nonZero.length > 0 ? hourlyData : hourlyData.slice(6, 22);

  if (isLoading) {
    return (
      <Card>
        <CardHeader>
          <CardTitle className="text-base">수유량</CardTitle>
        </CardHeader>
        <CardContent>
          <div className="h-40 bg-gray-100 rounded-xl animate-pulse" />
        </CardContent>
      </Card>
    );
  }

  return (
    <Card>
      <CardHeader>
        <CardTitle className="text-base">🍼 시간별 수유량</CardTitle>
      </CardHeader>
      <CardContent>
        {nonZero.length === 0 ? (
          <div className="h-40 flex items-center justify-center text-gray-400 text-sm">
            수유 기록이 없어요
          </div>
        ) : (
          <ResponsiveContainer width="100%" height={160}>
            <BarChart data={chartData} margin={{ top: 4, right: 4, bottom: 0, left: -20 }}>
              <CartesianGrid strokeDasharray="3 3" stroke="#f0f0f0" />
              <XAxis
                dataKey="hour"
                tick={{ fontSize: 10, fill: "#9CA3AF" }}
                tickLine={false}
                axisLine={false}
                interval={2}
              />
              <YAxis
                tick={{ fontSize: 10, fill: "#9CA3AF" }}
                tickLine={false}
                axisLine={false}
              />
              <Tooltip
                contentStyle={{
                  borderRadius: "12px",
                  border: "1px solid #e5e7eb",
                  fontSize: "12px",
                }}
                formatter={(v) => [`${v ?? 0}ml`, "수유량"]}
              />
              <Bar dataKey="ml" fill="#60A5FA" radius={[4, 4, 0, 0]} />
            </BarChart>
          </ResponsiveContainer>
        )}
      </CardContent>
    </Card>
  );
}
