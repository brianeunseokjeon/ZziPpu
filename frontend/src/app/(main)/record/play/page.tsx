import { PlayForm } from "@/features/play/components/PlayForm";
import { PlayList } from "@/features/play/components/PlayList";

export default function PlayPage() {
  return (
    <div className="space-y-4">
      <div className="bg-white rounded-2xl p-4 border-2 border-green-400">
        <PlayForm />
      </div>
      <div>
        <h3 className="text-sm font-semibold text-gray-500 mb-2">오늘 놀이 기록</h3>
        <PlayList />
      </div>
    </div>
  );
}
