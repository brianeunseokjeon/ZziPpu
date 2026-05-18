"use client";

import { useState } from "react";
import { Trash2, ChevronDown, ChevronUp } from "lucide-react";
import { Card, CardContent } from "@/shared/components/ui/card";
import { Badge } from "@/shared/components/ui/badge";
import { Button } from "@/shared/components/ui/button";
import type { SavedInfo } from "../types/aiReview";

interface Props {
  info: SavedInfo;
  onDelete: (id: string) => void;
}

const CATEGORY_CONFIG: Record<
  SavedInfo["category"],
  { label: string; variant: "feeding" | "sleep" | "play" | "diaper" | "default" | "secondary" }
> = {
  feeding: { label: "수유", variant: "feeding" },
  sleep: { label: "수면", variant: "sleep" },
  development: { label: "발달", variant: "play" },
  health: { label: "건강", variant: "destructive" as "default" },
  general: { label: "기타", variant: "secondary" },
};

export function SavedInfoCard({ info, onDelete }: Props) {
  const [expanded, setExpanded] = useState(false);
  const config = CATEGORY_CONFIG[info.category] ?? CATEGORY_CONFIG.general;

  const isLong = info.content.length > 80;
  const displayContent =
    !isLong || expanded ? info.content : info.content.slice(0, 80) + "...";

  const formattedDate = new Date(info.createdAt).toLocaleDateString("ko-KR", {
    month: "short",
    day: "numeric",
  });

  return (
    <Card>
      <CardContent className="pt-4">
        <div className="flex items-start justify-between gap-3">
          <div className="flex-1 min-w-0">
            <div className="flex items-center gap-2 mb-1.5 flex-wrap">
              <Badge variant={config.variant as Parameters<typeof Badge>[0]["variant"]}>
                {config.label}
              </Badge>
              <span className="text-xs text-gray-400">{formattedDate}</span>
            </div>
            <p className="text-sm font-semibold text-gray-800 mb-1">{info.title}</p>
            <p className="text-sm text-gray-600 leading-relaxed">{displayContent}</p>
            {isLong && (
              <button
                onClick={() => setExpanded((v) => !v)}
                className="flex items-center gap-1 mt-1 text-xs text-blue-500 hover:text-blue-600"
              >
                {expanded ? (
                  <>
                    <ChevronUp className="w-3 h-3" />
                    접기
                  </>
                ) : (
                  <>
                    <ChevronDown className="w-3 h-3" />
                    더 보기
                  </>
                )}
              </button>
            )}
          </div>
          <Button
            variant="ghost"
            size="icon"
            className="flex-shrink-0 text-gray-400 hover:text-red-400 h-8 w-8"
            onClick={() => onDelete(info.id)}
          >
            <Trash2 className="w-4 h-4" />
          </Button>
        </div>
      </CardContent>
    </Card>
  );
}
