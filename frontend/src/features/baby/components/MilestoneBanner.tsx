"use client";

import { useBabyInfo } from "../hooks/useBabyInfo";

const MILESTONES = [50, 100, 200, 300, 365, 500, 730];

function getMilestoneInfo(ageDays: number) {
  // 오늘이 마일스톤이면 축하
  if (MILESTONES.includes(ageDays)) {
    return { type: "celebrate" as const, days: ageDays };
  }
  // D-7 이내 다음 마일스톤
  const next = MILESTONES.find((m) => m > ageDays && m - ageDays <= 7);
  if (next) {
    return { type: "countdown" as const, days: next, daysLeft: next - ageDays };
  }
  return null;
}

const MILESTONE_EMOJI: Record<number, string> = {
  50: "🌱",
  100: "🎂",
  200: "🌟",
  300: "🏆",
  365: "🎉",
  500: "✨",
  730: "🥳",
};

export function MilestoneBanner() {
  const { ageDays, name } = useBabyInfo();
  const info = getMilestoneInfo(ageDays);
  if (!info) return null;

  const emoji = MILESTONE_EMOJI[info.days] ?? "🎊";

  if (info.type === "celebrate") {
    return (
      <div className="rounded-2xl p-4 bg-gradient-to-r from-yellow-50 to-orange-50 border border-yellow-200">
        <div className="flex items-center gap-3">
          <span className="text-3xl">{emoji}</span>
          <div>
            <p className="text-sm font-bold text-yellow-800">
              {name} 생후 {info.days}일 축하해요!
            </p>
            <p className="text-xs text-yellow-600 mt-0.5">
              {info.days === 100
                ? "백일을 진심으로 축하합니다 💛"
                : info.days === 365
                ? "첫 번째 생일을 축하해요 🎂"
                : info.days === 730
                ? "두 번째 생일을 축하해요 🥳"
                : `생후 ${info.days}일, 건강하게 자라줘서 고마워요`}
            </p>
          </div>
        </div>
      </div>
    );
  }

  return (
    <div className="rounded-2xl p-3.5 bg-gradient-to-r from-blue-50 to-indigo-50 border border-blue-200">
      <div className="flex items-center gap-3">
        <span className="text-2xl">{emoji}</span>
        <div>
          <p className="text-sm font-semibold text-blue-800">
            생후 {info.days}일까지{" "}
            <span className="text-blue-600 font-bold">D-{info.daysLeft}</span>
          </p>
          <p className="text-xs text-blue-500 mt-0.5">
            {info.days === 100
              ? "백일이 다가오고 있어요"
              : info.days === 365
              ? "첫돌이 코앞이에요!"
              : info.days === 730
              ? "두돌이 다가와요"
              : `${info.days}일 기념일이 다가오고 있어요`}
          </p>
        </div>
      </div>
    </div>
  );
}
