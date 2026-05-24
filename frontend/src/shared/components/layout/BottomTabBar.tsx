"use client";

import Link from "next/link";
import { usePathname } from "next/navigation";
import {
  Home,
  BarChart3,
  Bot,
  Sparkles,
  Settings,
} from "lucide-react";
import { cn } from "@/lib/utils";

const TABS = [
  { icon: Home, label: "홈", path: "/" },
  { icon: BarChart3, label: "대시보드", path: "/dashboard" },
  { icon: Bot, label: "AI", path: "/ai" },
  { icon: Sparkles, label: "발달", path: "/development" },
  { icon: Settings, label: "설정", path: "/settings" },
];

export function BottomTabBar() {
  const pathname = usePathname();

  function isActive(path: string) {
    if (path === "/") return pathname === "/";
    return pathname.startsWith(path);
  }

  return (
    <nav className="flex-shrink-0 z-40 bg-white border-t border-gray-100 pb-[env(safe-area-inset-bottom)]">
      <div className="max-w-md mx-auto flex">
        {TABS.map(({ icon: Icon, label, path }) => {
          const active = isActive(path);
          return (
            <Link
              key={path}
              href={path}
              className={cn(
                "flex flex-1 flex-col items-center justify-center py-2 gap-0.5 min-h-[56px] transition-colors",
                active ? "text-blue-500" : "text-gray-400 hover:text-gray-600"
              )}
            >
              <Icon
                className={cn("w-6 h-6", active && "stroke-[2.5]")}
                strokeWidth={active ? 2.5 : 1.8}
              />
              <span className={cn("text-[10px] font-medium", active && "font-semibold")}>
                {label}
              </span>
            </Link>
          );
        })}
      </div>
    </nav>
  );
}
