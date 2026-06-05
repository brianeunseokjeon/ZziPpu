"use client";

import { Plus, X, Milk, Baby, Moon, Gamepad2 } from "lucide-react";
import { useRouter } from "next/navigation";
import { useUIStore } from "@/shared/stores/uiStore";
import { VoiceMicButton } from "@/shared/components/VoiceMicButton";
import { cn } from "@/lib/utils";

const ACTIONS = [
  { icon: Milk, label: "수유", path: "/record/feeding", color: "bg-blue-400" },
  { icon: Baby, label: "배변", path: "/record/diaper", color: "bg-orange-400" },
  { icon: Moon, label: "수면", path: "/record/sleep", color: "bg-purple-400" },
  { icon: Gamepad2, label: "놀이", path: "/record/play", color: "bg-green-400" },
];

export function QuickActionFAB() {
  const router = useRouter();
  const { isQuickActionOpen, toggleQuickAction, setIsQuickActionOpen } =
    useUIStore();

  function handleAction(path: string) {
    setIsQuickActionOpen(false);
    router.push(path);
  }

  return (
    <>
      {isQuickActionOpen && (
        <div
          className="fixed inset-0 z-40"
          onClick={() => setIsQuickActionOpen(false)}
        />
      )}

      <div className="fixed bottom-[calc(56px+env(safe-area-inset-bottom)+12px)] right-4 z-50 flex flex-col items-end gap-3">
        {isQuickActionOpen &&
          ACTIONS.map(({ icon: Icon, label, path, color }, i) => (
            <button
              key={path}
              onClick={() => handleAction(path)}
              className={cn(
                "flex items-center gap-2 px-4 py-2.5 rounded-full text-white font-medium text-sm shadow-lg",
                "transition-all duration-200",
                color
              )}
              style={{
                animationDelay: `${i * 50}ms`,
                transform: isQuickActionOpen ? "scale(1)" : "scale(0)",
              }}
            >
              <Icon className="w-4 h-4" />
              <span>{label}</span>
            </button>
          ))}

        <div className="flex items-center gap-2">
          {!isQuickActionOpen && <VoiceMicButton />}
          <button
            onClick={toggleQuickAction}
            className={cn(
              "w-14 h-14 rounded-full bg-blue-500 text-white shadow-xl flex items-center justify-center",
              "transition-all duration-200 hover:bg-blue-600 active:scale-95"
            )}
          >
            {isQuickActionOpen ? (
              <X className="w-6 h-6" />
            ) : (
              <Plus className="w-6 h-6" />
            )}
          </button>
        </div>
      </div>
    </>
  );
}
