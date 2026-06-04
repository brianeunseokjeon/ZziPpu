"use client";

import { useState } from "react";
import { useRouter } from "next/navigation";
import { Loader2 } from "lucide-react";

import { apiClient } from "@/lib/api-client";
import { useBabyStore } from "@/features/baby/store/babyStore";
import { useAuthStore } from "@/features/auth/store/authStore";

type Gender = "male" | "female" | "unknown";

interface CreatedBaby {
  id: string;
  name: string;
  birthDate: string;
}

export default function OnboardingPage() {
  const router = useRouter();
  const { setBabyId, setName, setBirthDate } = useBabyStore();
  const accessToken = useAuthStore((s) => s.accessToken);

  const [name, setNameLocal] = useState("");
  const [birthDate, setBirthDateLocal] = useState("");
  const [gender, setGender] = useState<Gender>("unknown");
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);

  // 비로그인 접근 차단
  if (!accessToken && typeof window !== "undefined") {
    router.replace("/login");
  }

  async function handleSubmit() {
    setError(null);
    if (!name.trim()) return setError("아기 이름을 입력해주세요.");
    if (!birthDate) return setError("생년월일을 입력해주세요.");

    setLoading(true);
    try {
      // 자동 baby 생성 제거됨 → 온보딩에서 POST 로 새로 생성.
      const baby = await apiClient.post<CreatedBaby>("/api/v1/babies", {
        name: name.trim(),
        birthDate,
        gender: gender === "unknown" ? null : gender,
      });
      setBabyId(baby.id);
      setName(baby.name);
      setBirthDate(baby.birthDate);
      router.replace("/");
    } catch (e) {
      setError(e instanceof Error ? e.message : "저장에 실패했습니다.");
    } finally {
      setLoading(false);
    }
  }

  const today = new Date().toISOString().slice(0, 10);

  return (
    <div className="space-y-6">
      <div className="text-center">
        <div className="text-5xl mb-3">🍼</div>
        <h1 className="text-2xl font-bold text-gray-900">아기 정보를 알려주세요</h1>
        <p className="text-sm text-gray-500 mt-1">맞춤형 기록과 AI 피드백을 위해 필요해요.</p>
      </div>

      <div className="bg-white rounded-2xl shadow-sm border border-gray-100 p-6 space-y-4">
        <label className="block">
          <span className="text-sm font-medium text-gray-700">아기 이름</span>
          <input
            type="text"
            placeholder="예: 우리 아기"
            value={name}
            onChange={(e) => setNameLocal(e.target.value)}
            maxLength={20}
            className="mt-1.5 w-full h-12 px-4 rounded-xl border border-gray-200 focus:outline-none focus:ring-2 focus:ring-blue-400"
            autoFocus
          />
        </label>

        <label className="block">
          <span className="text-sm font-medium text-gray-700">생년월일</span>
          <input
            type="date"
            value={birthDate}
            max={today}
            onChange={(e) => setBirthDateLocal(e.target.value)}
            className="mt-1.5 w-full h-12 px-4 rounded-xl border border-gray-200 focus:outline-none focus:ring-2 focus:ring-blue-400"
          />
        </label>

        <div>
          <span className="text-sm font-medium text-gray-700">성별</span>
          <div className="mt-1.5 grid grid-cols-3 gap-2">
            {(
              [
                { v: "male", label: "남아", emoji: "👦" },
                { v: "female", label: "여아", emoji: "👧" },
                { v: "unknown", label: "비공개", emoji: "·" },
              ] as { v: Gender; label: string; emoji: string }[]
            ).map(({ v, label, emoji }) => (
              <button
                key={v}
                onClick={() => setGender(v)}
                className={`h-12 rounded-xl border text-sm font-medium ${
                  gender === v
                    ? "bg-blue-50 border-blue-400 text-blue-700"
                    : "bg-white border-gray-200 text-gray-600"
                }`}
              >
                <span className="mr-1">{emoji}</span>
                {label}
              </button>
            ))}
          </div>
        </div>

        {error && (
          <div className="text-sm text-red-500 bg-red-50 border border-red-100 rounded-lg px-3 py-2">
            {error}
          </div>
        )}

        <button
          onClick={handleSubmit}
          disabled={loading || !name || !birthDate}
          className="w-full h-12 rounded-xl bg-blue-500 hover:bg-blue-600 disabled:bg-gray-200 disabled:text-gray-400 text-white font-semibold flex items-center justify-center gap-2"
        >
          {loading && <Loader2 className="w-4 h-4 animate-spin" />}
          시작하기
        </button>
      </div>
    </div>
  );
}
