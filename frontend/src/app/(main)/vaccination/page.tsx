"use client";

import { UpcomingAlert } from "@/features/vaccination/components/UpcomingAlert";
import { VaccinationList } from "@/features/vaccination/components/VaccinationList";

export default function VaccinationPage() {
  return (
    <div className="space-y-4">
      <UpcomingAlert />
      <div>
        <h2 className="text-sm font-semibold text-gray-500 mb-2 px-1">
          전체 접종 일정
        </h2>
        <VaccinationList />
      </div>
    </div>
  );
}
