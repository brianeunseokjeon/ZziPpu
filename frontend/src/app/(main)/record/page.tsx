"use client";

import { useState } from "react";
import { FeedingForm } from "@/features/feeding/components/FeedingForm";
import { FeedingList } from "@/features/feeding/components/FeedingList";
import { DiaperForm } from "@/features/diaper/components/DiaperForm";
import { DiaperList } from "@/features/diaper/components/DiaperList";
import { SleepTimer } from "@/features/sleep/components/SleepTimer";
import { SleepList } from "@/features/sleep/components/SleepList";
import { PlayForm } from "@/features/play/components/PlayForm";
import { PlayList } from "@/features/play/components/PlayList";
import { cn } from "@/lib/utils";

type RecordTab = "feeding" | "diaper" | "sleep" | "play";

const TABS: { value: RecordTab; label: string; emoji: string }[] = [
  { value: "feeding", label: "수유", emoji: "🍼" },
  { value: "diaper", label: "배변", emoji: "🧷" },
  { value: "sleep", label: "수면", emoji: "😴" },
  { value: "play", label: "놀이", emoji: "🎈" },
];

const TAB_COLORS: Record<RecordTab, string> = {
  feeding: "border-blue-400 text-blue-600",
  diaper: "border-orange-400 text-orange-600",
  sleep: "border-purple-400 text-purple-600",
  play: "border-green-400 text-green-600",
};

export default function RecordPage() {
  const [activeTab, setActiveTab] = useState<RecordTab>("feeding");

  return (
    <div className="space-y-4">
      <div className="flex gap-1 bg-gray-100 rounded-2xl p-1">
        {TABS.map(({ value, label, emoji }) => (
          <button
            key={value}
            onClick={() => setActiveTab(value)}
            className={cn(
              "flex-1 flex flex-col items-center py-2.5 rounded-xl text-xs font-medium transition-all",
              activeTab === value
                ? "bg-white shadow-sm text-gray-900"
                : "text-gray-400 hover:text-gray-600"
            )}
          >
            <span className="text-base mb-0.5">{emoji}</span>
            {label}
          </button>
        ))}
      </div>

      <div className={cn("bg-white rounded-2xl p-4 border-2", TAB_COLORS[activeTab])}>
        {activeTab === "feeding" && <FeedingForm />}
        {activeTab === "diaper" && <DiaperForm />}
        {activeTab === "sleep" && <SleepTimer />}
        {activeTab === "play" && <PlayForm />}
      </div>

      <div>
        <h3 className="text-sm font-semibold text-gray-500 mb-2">오늘 기록</h3>
        {activeTab === "feeding" && <FeedingList />}
        {activeTab === "diaper" && <DiaperList />}
        {activeTab === "sleep" && <SleepList />}
        {activeTab === "play" && <PlayList />}
      </div>
    </div>
  );
}
