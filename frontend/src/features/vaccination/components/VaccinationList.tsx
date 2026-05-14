"use client";

import { useVaccinations } from "../api/vaccinationApi";
import { VaccinationCard } from "./VaccinationCard";
import { MOCK_BABY_ID } from "@/config/constants";
import type { Vaccination } from "../types/vaccination";

function groupVaccinations(vaccinations: Vaccination[]) {
  const now = new Date();
  const currentMonth = now.getMonth();
  const currentYear = now.getFullYear();

  const thisMonth: Vaccination[] = [];
  const upcoming: Vaccination[] = [];
  const done: Vaccination[] = [];

  for (const v of vaccinations) {
    if (v.administered_date) {
      done.push(v);
      continue;
    }
    const scheduled = new Date(v.scheduled_date);
    if (
      scheduled.getFullYear() === currentYear &&
      scheduled.getMonth() === currentMonth
    ) {
      thisMonth.push(v);
    } else {
      upcoming.push(v);
    }
  }

  return { thisMonth, upcoming, done };
}

function Section({
  title,
  items,
}: {
  title: string;
  items: Vaccination[];
}) {
  if (items.length === 0) return null;
  return (
    <div className="space-y-2">
      <h3 className="text-sm font-semibold text-gray-500 px-1">{title}</h3>
      {items.map((v) => (
        <VaccinationCard key={v.id} vaccination={v} />
      ))}
    </div>
  );
}

export function VaccinationList() {
  const { data: vaccinations, isLoading } = useVaccinations(MOCK_BABY_ID);

  if (isLoading) {
    return (
      <div className="space-y-2">
        {[1, 2, 3, 4].map((i) => (
          <div key={i} className="h-16 bg-gray-100 rounded-2xl animate-pulse" />
        ))}
      </div>
    );
  }

  if (!vaccinations || vaccinations.length === 0) {
    return (
      <div className="text-center py-10 text-gray-400">
        <p className="text-4xl mb-2">💉</p>
        <p className="text-sm">예방접종 일정이 없어요</p>
      </div>
    );
  }

  const { thisMonth, upcoming, done } = groupVaccinations(vaccinations);

  return (
    <div className="space-y-5">
      <Section title="이번 달 예정" items={thisMonth} />
      <Section title="향후 예정" items={upcoming} />
      <Section title="완료" items={done} />
    </div>
  );
}
