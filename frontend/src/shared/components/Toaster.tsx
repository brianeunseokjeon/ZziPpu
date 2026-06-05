"use client";

import { useToastStore } from "@/shared/stores/toastStore";
import { CheckCircle2, AlertCircle, Info, X } from "lucide-react";

const ICONS = {
  error: AlertCircle,
  success: CheckCircle2,
  info: Info,
} as const;

const STYLES = {
  error: "bg-red-50 border-red-200 text-red-700",
  success: "bg-green-50 border-green-200 text-green-700",
  info: "bg-gray-800 border-gray-700 text-white",
} as const;

/** 하단 중앙 토스트 — 자동 사라짐(3.5s), 탭하면 즉시 닫힘. */
export function Toaster() {
  const toasts = useToastStore((s) => s.toasts);
  const dismiss = useToastStore((s) => s.dismiss);

  if (toasts.length === 0) return null;

  return (
    <div className="fixed inset-x-0 bottom-[calc(56px+env(safe-area-inset-bottom)+16px)] z-[100] flex flex-col items-center gap-2 px-4 pointer-events-none">
      {toasts.map((t) => {
        const Icon = ICONS[t.variant];
        return (
          <button
            key={t.id}
            onClick={() => dismiss(t.id)}
            className={`pointer-events-auto flex items-center gap-2 max-w-sm w-full sm:w-auto px-4 py-3 rounded-xl border shadow-lg text-sm font-medium animate-[slideUp_0.2s_ease-out] ${STYLES[t.variant]}`}
          >
            <Icon className="w-4 h-4 flex-shrink-0" />
            <span className="flex-1 text-left">{t.message}</span>
            <X className="w-3.5 h-3.5 opacity-50 flex-shrink-0" />
          </button>
        );
      })}
    </div>
  );
}
