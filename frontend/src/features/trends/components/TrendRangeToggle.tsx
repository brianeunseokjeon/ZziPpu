"use client";

interface TrendRangeToggleProps {
  value: 7 | 14;
  onChange: (v: 7 | 14) => void;
}

export function TrendRangeToggle({ value, onChange }: TrendRangeToggleProps) {
  return (
    <div className="flex items-center gap-1 bg-gray-100 rounded-full p-1 self-start">
      {([7, 14] as const).map((days) => (
        <button
          key={days}
          onClick={() => onChange(days)}
          className={
            value === days
              ? "bg-gray-800 text-white rounded-full px-4 py-1.5 text-sm font-medium transition-all"
              : "text-gray-500 rounded-full px-4 py-1.5 text-sm font-medium transition-all"
          }
        >
          {days}일
        </button>
      ))}
    </div>
  );
}
