"use client";

import { useState } from "react";
import { BookMarked } from "lucide-react";
import { Card, CardContent } from "@/shared/components/ui/card";
import { MOCK_BABY_ID } from "@/config/constants";
import {
  useSavedInfos,
  useDeleteSavedInfo,
  SavedInfoCard,
} from "@/features/ai-review";
import type { SavedInfo } from "@/features/ai-review";

const CATEGORY_FILTERS: {
  value: SavedInfo["category"] | "all";
  label: string;
}[] = [
  { value: "all", label: "전체" },
  { value: "feeding", label: "수유" },
  { value: "sleep", label: "수면" },
  { value: "development", label: "발달" },
  { value: "health", label: "건강" },
  { value: "general", label: "기타" },
];

export default function SavedInfoPage() {
  const [activeCategory, setActiveCategory] = useState<
    SavedInfo["category"] | "all"
  >("all");

  const { data: savedInfos = [], isLoading } = useSavedInfos(MOCK_BABY_ID);
  const deleteMutation = useDeleteSavedInfo();

  const filtered =
    activeCategory === "all"
      ? savedInfos
      : savedInfos.filter((info) => info.category === activeCategory);

  const handleDelete = (id: string) => {
    deleteMutation.mutate({ babyId: MOCK_BABY_ID, id });
  };

  return (
    <div className="space-y-4">
      {/* Header */}
      <Card>
        <CardContent className="pt-5">
          <div className="flex items-center gap-3">
            <div className="w-10 h-10 rounded-full bg-gradient-to-br from-green-400 to-teal-500 flex items-center justify-center">
              <BookMarked className="w-5 h-5 text-white" />
            </div>
            <div>
              <h2 className="text-base font-bold text-gray-900">저장된 정보</h2>
              <p className="text-xs text-gray-500">
                AI 채팅에서 저장한 유용한 정보
              </p>
            </div>
          </div>
        </CardContent>
      </Card>

      {/* Category Filter */}
      <div className="flex gap-2 overflow-x-auto pb-1">
        {CATEGORY_FILTERS.map((f) => (
          <button
            key={f.value}
            onClick={() => setActiveCategory(f.value)}
            className={`flex-shrink-0 px-4 py-2 rounded-xl text-sm font-medium transition-colors ${
              activeCategory === f.value
                ? "bg-blue-500 text-white"
                : "bg-white border border-gray-200 text-gray-600 hover:bg-gray-50"
            }`}
          >
            {f.label}
          </button>
        ))}
      </div>

      {/* Loading */}
      {isLoading && (
        <div className="flex items-center justify-center py-12">
          <div className="w-6 h-6 border-2 border-blue-400 border-t-transparent rounded-full animate-spin" />
        </div>
      )}

      {/* Content */}
      {!isLoading && filtered.length > 0 && (
        <div className="space-y-3">
          {filtered.map((info) => (
            <SavedInfoCard key={info.id} info={info} onDelete={handleDelete} />
          ))}
        </div>
      )}

      {/* Empty State */}
      {!isLoading && filtered.length === 0 && (
        <Card>
          <CardContent className="pt-6">
            <div className="flex flex-col items-center gap-4 py-8 text-center">
              <div className="w-14 h-14 rounded-full bg-green-50 flex items-center justify-center">
                <BookMarked className="w-7 h-7 text-green-300" />
              </div>
              <div>
                <p className="text-sm font-semibold text-gray-700 mb-1">
                  저장된 정보가 없어요
                </p>
                <p className="text-xs text-gray-400 leading-relaxed">
                  채팅에서 유용한 정보를 저장하면
                  <br />
                  여기에 표시됩니다
                </p>
              </div>
            </div>
          </CardContent>
        </Card>
      )}
    </div>
  );
}
