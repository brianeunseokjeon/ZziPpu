"use client";

import { LogOut } from "lucide-react";
import { useRouter } from "next/navigation";
import { useAuthStore } from "@/features/auth/store/authStore";

export function LogoutButton() {
  const router = useRouter();
  const clear = useAuthStore((s) => s.clear);

  function handleLogout() {
    if (!confirm("로그아웃 하시겠어요?")) return;
    clear();
    router.replace("/login");
  }

  // 설정 페이지는 인증 보호 영역이므로 항상 노출한다.
  return (
    <button
      onClick={handleLogout}
      className="w-full flex items-center justify-between py-3 px-1 rounded-xl hover:bg-red-50 transition-colors"
    >
      <div className="flex items-center gap-2.5">
        <LogOut className="w-4 h-4 text-red-500" />
        <span className="text-sm font-medium text-red-600">로그아웃</span>
      </div>
    </button>
  );
}
