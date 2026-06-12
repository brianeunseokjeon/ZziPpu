"use client";

import {
  BarChart,
  Bar,
  XAxis,
  YAxis,
  CartesianGrid,
  Tooltip,
  ResponsiveContainer,
  ReferenceLine,
  Cell,
} from "recharts";

interface ChartDataPoint {
  date: string;
  label?: string;
  value: number | null;
}

interface TrendChartProps {
  data: ChartDataPoint[];
  color: string;
  unit: string;
  title?: string;
  guidelineMin?: number;
  guidelineMax?: number;
}

/** Lighten a hex color by mixing with white (for null-value bars) */
function hexToRgba(hex: string, alpha: number): string {
  const clean = hex.replace("#", "");
  const r = parseInt(clean.slice(0, 2), 16);
  const g = parseInt(clean.slice(2, 4), 16);
  const b = parseInt(clean.slice(4, 6), 16);
  return `rgba(${r},${g},${b},${alpha})`;
}

/** Darken a hex color for today's bar */
function darkenHex(hex: string): string {
  const clean = hex.replace("#", "");
  const r = Math.max(0, parseInt(clean.slice(0, 2), 16) - 40);
  const g = Math.max(0, parseInt(clean.slice(2, 4), 16) - 40);
  const b = Math.max(0, parseInt(clean.slice(4, 6), 16) - 40);
  return `rgb(${r},${g},${b})`;
}

export function TrendChart({
  data,
  color,
  unit,
  title,
  guidelineMin,
  guidelineMax,
}: TrendChartProps) {
  const darkColor = darkenHex(color);
  const faintColor = hexToRgba(color, 0.3);

  // Normalize: replace null with 0 for rendering, track originals
  const chartData = data.map((d) => ({
    ...d,
    value: d.value ?? 0,
    hasData: d.value !== null,
  }));

  const hasGuideline =
    guidelineMin !== undefined && guidelineMax !== undefined;

  // interval for X axis: show every label when 7 days, every other when 14
  const xInterval = data.length > 7 ? 1 : 0;

  // Get X-axis key: prefer "label" (weekday), fall back to "date"
  const xKey = data[0]?.label !== undefined ? "label" : "date";

  return (
    <ResponsiveContainer width="100%" height={120}>
      <BarChart
        data={chartData}
        margin={{ top: 8, right: 4, bottom: 0, left: -20 }}
      >
        <CartesianGrid strokeDasharray="3 3" stroke="#f0f0f0" vertical={false} />

        {/* Guideline band — rendered before Bar so bars appear on top */}
        {hasGuideline && (
          <>
            <ReferenceLine
              y={guidelineMax}
              stroke={color}
              strokeDasharray="4 4"
              strokeOpacity={0.5}
            />
            <ReferenceLine
              y={guidelineMin}
              stroke={color}
              strokeDasharray="4 4"
              strokeOpacity={0.5}
            />
          </>
        )}

        <XAxis
          dataKey={xKey}
          tick={{ fontSize: 10, fill: "#9CA3AF" }}
          tickLine={false}
          axisLine={false}
          interval={xInterval}
        />

        <YAxis
          tick={{ fontSize: 10, fill: "#9CA3AF" }}
          tickLine={false}
          axisLine={false}
          width={28}
        />

        <Tooltip
          contentStyle={{
            borderRadius: "12px",
            border: "1px solid #e5e7eb",
            fontSize: "12px",
          }}
          formatter={(v: unknown, _name: unknown, entry: { payload?: { hasData?: boolean } }) => {
            if (!entry.payload?.hasData) return ["-", title ?? ""];
            return [`${v}${unit}`, title ?? ""];
          }}
          cursor={{ fill: "rgba(0,0,0,0.04)" }}
        />

        <Bar dataKey="value" radius={[4, 4, 0, 0]}>
          {chartData.map((d, i) => {
            const isToday = i === chartData.length - 1;
            const fill = !d.hasData
              ? faintColor
              : isToday
                ? darkColor
                : color;
            return <Cell key={d.date} fill={fill} />;
          })}
        </Bar>
      </BarChart>
    </ResponsiveContainer>
  );
}
