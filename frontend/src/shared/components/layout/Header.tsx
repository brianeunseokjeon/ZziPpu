"use client";

import { ChevronLeft, ChevronRight } from "lucide-react";
import { useUIStore } from "@/shared/stores/uiStore";
import { formatDate, getAgeText, getDateString } from "@/lib/date-utils";
import { MOCK_BIRTH_DATE } from "@/config/constants";
import { addDays, subDays } from "date-fns";

export function Header() {
  const { selectedDate, setSelectedDate } = useUIStore();

  const dateObj = new Date(selectedDate + "T00:00:00");
  const isToday = selectedDate === getDateString(new Date());

  function goBack() {
    setSelectedDate(getDateString(subDays(dateObj, 1)));
  }

  function goForward() {
    if (!isToday) {
      setSelectedDate(getDateString(addDays(dateObj, 1)));
    }
  }

  function goToday() {
    setSelectedDate(getDateString(new Date()));
  }

  return (
    <header className="sticky top-0 z-30 bg-white border-b border-gray-100 pt-[env(safe-area-inset-top)]">
      <div className="max-w-md mx-auto px-4 h-14 flex items-center justify-between gap-2">
        <div className="flex flex-col leading-tight">
          <span className="text-base font-bold text-gray-900">먹놀잠 👶</span>
          <span className="text-xs text-gray-400">{getAgeText(MOCK_BIRTH_DATE)}</span>
        </div>

        <div className="flex items-center gap-1">
          <button
            onClick={goBack}
            className="p-1.5 rounded-full hover:bg-gray-100 transition-colors"
          >
            <ChevronLeft className="w-4 h-4 text-gray-500" />
          </button>

          <button
            onClick={goToday}
            className="text-sm font-medium text-gray-700 min-w-[110px] text-center"
          >
            {formatDate(dateObj)}
          </button>

          <button
            onClick={goForward}
            disabled={isToday}
            className="p-1.5 rounded-full hover:bg-gray-100 transition-colors disabled:opacity-30 disabled:cursor-not-allowed"
          >
            <ChevronRight className="w-4 h-4 text-gray-500" />
          </button>
        </div>
      </div>
    </header>
  );
}
