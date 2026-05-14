import { SleepTimer } from "@/features/sleep/components/SleepTimer";
import { SleepList } from "@/features/sleep/components/SleepList";

export default function SleepPage() {
  return (
    <div className="space-y-4">
      <div className="bg-white rounded-2xl p-4 border-2 border-purple-400">
        <SleepTimer />
      </div>
      <div>
        <h3 className="text-sm font-semibold text-gray-500 mb-2">오늘 수면 기록</h3>
        <SleepList />
      </div>
    </div>
  );
}
