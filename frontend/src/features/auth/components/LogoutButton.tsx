"use client";

import { LogOut } from "lucide-react";
import { useRouter } from "next/navigation";
import { useAuthStore } from "@/features/auth/store/authStore";

export function LogoutButton() {
  const router = useRouter();
  const clear = useAuthStore((s) => s.clear);
  const accessToken = useAuthStore((s) => s.accessToken);

  // 토큰이 없으면 (DEV_MODE 등) 버튼 숨김
  if (!accessToken) return null;

  function handleLogout() {
    clear();
    router.replace("/login");
  }

  return (
    <button
      onClick={handleLogout}
      className="w-full flex items-center justify-center gap-2 py-3 rounded-xl bg-gray-50 hover:bg-gray-100 text-gray-600 text-sm font-medium"
    >
      <LogOut className="w-4 h-4" />
      로그아웃
    </button>
  );
}
