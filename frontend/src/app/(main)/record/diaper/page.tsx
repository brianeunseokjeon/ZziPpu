import { DiaperForm } from "@/features/diaper/components/DiaperForm";
import { DiaperList } from "@/features/diaper/components/DiaperList";

export default function DiaperPage() {
  return (
    <div className="space-y-4">
      <div className="bg-white rounded-2xl p-4 border-2 border-orange-400">
        <DiaperForm />
      </div>
      <div>
        <h3 className="text-sm font-semibold text-gray-500 mb-2">오늘 배변 기록</h3>
        <DiaperList />
      </div>
    </div>
  );
}
