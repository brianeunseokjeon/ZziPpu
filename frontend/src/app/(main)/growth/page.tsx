"use client";

import { GrowthChart } from "@/features/growth/components/GrowthChart";
import { GrowthForm } from "@/features/growth/components/GrowthForm";
import { GrowthList } from "@/features/growth/components/GrowthList";
import { Card, CardContent } from "@/shared/components/ui/card";

export default function GrowthPage() {
  return (
    <div className="space-y-4">
      <Card>
        <CardContent className="pt-4">
          <div className="flex items-center gap-2 mb-3">
            <span className="text-lg">🌱</span>
            <h2 className="text-sm font-semibold text-gray-700">성장 곡선</h2>
          </div>
          <GrowthChart />
        </CardContent>
      </Card>

      <Card>
        <CardContent className="pt-4">
          <div className="flex items-center gap-2 mb-3">
            <span className="text-lg">📝</span>
            <h2 className="text-sm font-semibold text-gray-700">새 기록 추가</h2>
          </div>
          <GrowthForm />
        </CardContent>
      </Card>

      <div>
        <h2 className="text-sm font-semibold text-gray-500 mb-2 px-1">기록 목록</h2>
        <GrowthList />
      </div>
    </div>
  );
}
