import { FeedingForm } from "@/features/feeding/components/FeedingForm";
import { FeedingList } from "@/features/feeding/components/FeedingList";

export default function FeedingPage() {
  return (
    <div className="space-y-4">
      <div className="bg-white rounded-2xl p-4 border-2 border-blue-400">
        <FeedingForm />
      </div>
      <div>
        <h3 className="text-sm font-semibold text-gray-500 mb-2">오늘 수유 기록</h3>
        <FeedingList />
      </div>
    </div>
  );
}
