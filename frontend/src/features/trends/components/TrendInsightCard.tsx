"use client";

import { TrendChart } from "./TrendChart";

type TrendDirection = "up" | "down" | "stable";

interface ChartDataPoint {
  date: string;
  label?: string;
  value: number | null;
}

interface TrendInsightCardProps {
  title: string;
  emoji: string;
  value: string;
  trend: TrendDirection;
  trendLabel: string;
  insight: string;
  chartData: ChartDataPoint[];
  color: string;
  unit: string;
  guidelineMin?: number;
  guidelineMax?: number;
  accentColor: string;
  textColor: string;
  /** Controls whether "up" direction is positive (green) or negative (red). Defaults to true. */
  upIsGood?: boolean;
}

interface TrendBadgeProps {
  direction: TrendDirection;
  label: string;
  upIsGood: boolean;
}

function TrendBadge({ direction, label, upIsGood }: TrendBadgeProps) {
  if (direction === "stable") {
    return (
      <span className="flex items-center gap-1 text-xs font-medium text-gray-500">
        <span>—</span>
        <span>{label}</span>
      </span>
    );
  }

  const isPositive =
    (direction === "up" && upIsGood) || (direction === "down" && !upIsGood);

  const arrow = direction === "up" ? "↑" : "↓";
  const colorClass = isPositive ? "text-emerald-600" : "text-red-500";

  return (
    <span className={`flex items-center gap-0.5 text-xs font-semibold ${colorClass}`}>
      <span>{arrow}</span>
      <span>{label}</span>
    </span>
  );
}

export function TrendInsightCard({
  title,
  emoji,
  value,
  trend,
  trendLabel,
  insight,
  chartData,
  color,
  unit,
  guidelineMin,
  guidelineMax,
  accentColor,
  textColor,
  upIsGood = true,
}: TrendInsightCardProps) {
  return (
    <div className="bg-white rounded-2xl border border-gray-100 shadow-sm overflow-hidden">
      {/* Header */}
      <div className={`${accentColor} px-4 pt-4 pb-3`}>
        <div className="flex items-center justify-between">
          <div className="flex items-center gap-2">
            <span className="text-lg leading-none">{emoji}</span>
            <h3 className={`text-sm font-bold ${textColor}`}>{title}</h3>
          </div>
          <TrendBadge
            direction={trend}
            label={trendLabel}
            upIsGood={upIsGood}
          />
        </div>

        {/* Big value */}
        <p className="mt-2 text-2xl font-bold text-gray-900 tabular-nums leading-tight">
          {value}
        </p>
      </div>

      {/* Chart */}
      <div className="px-2 pt-2 pb-1">
        <TrendChart
          data={chartData}
          color={color}
          unit={unit}
          title={title}
          guidelineMin={guidelineMin}
          guidelineMax={guidelineMax}
        />
      </div>

      {/* Insight */}
      <div className="px-4 pb-4 pt-1">
        <p className="text-sm text-gray-600 bg-gray-50 rounded-xl px-3 py-2.5 leading-relaxed">
          {insight}
        </p>
      </div>
    </div>
  );
}
