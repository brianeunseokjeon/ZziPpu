"use client";

import { ChevronLeft, ChevronRight } from "lucide-react";
import { useUIStore } from "@/shared/stores/uiStore";
import { formatDate, getDateString } from "@/lib/date-utils";
import { useBabyInfo } from "@/features/baby/hooks/useBabyInfo";
import { addDays, subDays } from "date-fns";

export function Header() {
  const { selectedDate, setSelectedDate } = useUIStore();
  const { ageText, photoUrl } = useBabyInfo();

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
        <div className="flex items-center gap-2">
          {/* 아기 아바타 */}
          <div className="w-8 h-8 rounded-full overflow-hidden border border-blue-100 bg-gradient-to-br from-blue-200 to-purple-200 flex items-center justify-center flex-shrink-0">
            {photoUrl ? (
              // eslint-disable-next-line @next/next/no-img-element
              <img src={photoUrl} alt="아기" className="w-full h-full object-cover" />
            ) : (
              <span className="text-base">👶</span>
            )}
          </div>
          <div className="flex flex-col leading-tight">
            <span className="text-base font-bold text-gray-900">먹놀잠</span>
            <span className="text-xs text-gray-400">{ageText}</span>
          </div>
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
