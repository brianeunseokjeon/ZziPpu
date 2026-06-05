"use client";

import { LogOut } from "lucide-react";
import { useRouter } from "next/navigation";
import { useQueryClient } from "@tanstack/react-query";
import { resetSession } from "@/shared/lib/resetSession";

export function LogoutButton() {
  const router = useRouter();
  const queryClient = useQueryClient();

  function handleLogout() {
    if (!confirm("로그아웃 하시겠어요?")) return;
    // 토큰·아기정보·캐시 전부 초기화 (다음 사용자에게 잔존 방지)
    resetSession(queryClient);
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
