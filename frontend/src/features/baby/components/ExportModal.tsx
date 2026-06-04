"use client";

import { useState } from "react";
import { Download, X } from "lucide-react";
import { Button } from "@/shared/components/ui/button";
import { API_BASE_URL } from "@/config/constants";
import { useBabyInfo } from "@/features/baby/hooks/useBabyInfo";
import { getAccessToken } from "@/features/auth/store/authStore";

interface Props {
  onClose: () => void;
}

export default function ExportModal({ onClose }: Props) {
  const { babyId } = useBabyInfo();
  const [format, setFormat] = useState<"json" | "csv">("json");
  const [startDate, setStartDate] = useState("");
  const [endDate, setEndDate] = useState("");
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState("");

  async function handleExport() {
    setLoading(true);
    setError("");

    const params = new URLSearchParams({ format });
    if (startDate) params.append("start_date", startDate);
    if (endDate) params.append("end_date", endDate);

    try {
      const token = getAccessToken();
      const res = await fetch(
        `${API_BASE_URL}/api/v1/babies/${babyId}/export?${params}`,
        { headers: token ? { Authorization: `Bearer ${token}` } : {} }
      );
      if (!res.ok) throw new Error("내보내기 실패");

      const blob = await res.blob();
      const url = URL.createObjectURL(blob);
      const a = document.createElement("a");
      a.href = url;
      a.download = `muknoljam_export.${format}`;
      a.click();
      URL.revokeObjectURL(url);
      onClose();
    } catch {
      setError("데이터 내보내기 중 오류가 발생했습니다.");
    } finally {
      setLoading(false);
    }
  }

  return (
    <div className="fixed inset-0 z-50 flex items-end justify-center bg-black/40">
      <div className="bg-white rounded-t-3xl w-full max-w-md p-6 space-y-5">
        <div className="flex items-center justify-between">
          <h2 className="text-base font-bold text-gray-900">데이터 내보내기</h2>
          <button onClick={onClose} className="p-1 rounded-full hover:bg-gray-100">
            <X className="w-5 h-5 text-gray-500" />
          </button>
        </div>

        {/* 형식 선택 */}
        <div>
          <p className="text-sm font-medium text-gray-700 mb-2">형식</p>
          <div className="flex gap-3">
            {(["json", "csv"] as const).map((f) => (
              <button
                key={f}
                onClick={() => setFormat(f)}
                className={`flex-1 py-2 rounded-xl text-sm font-medium border transition-colors ${
                  format === f
                    ? "bg-blue-500 text-white border-blue-500"
                    : "bg-white text-gray-600 border-gray-200"
                }`}
              >
                {f.toUpperCase()}
              </button>
            ))}
          </div>
        </div>

        {/* 날짜 범위 */}
        <div className="grid grid-cols-2 gap-3">
          <div>
            <p className="text-xs text-gray-500 mb-1">시작 날짜 (선택)</p>
            <input
              type="date"
              value={startDate}
              max={endDate || new Date().toISOString().slice(0, 10)}
              onChange={(e) => setStartDate(e.target.value)}
              className="w-full text-sm border border-gray-200 rounded-xl px-3 py-2 focus:outline-none focus:ring-2 focus:ring-blue-400"
            />
          </div>
          <div>
            <p className="text-xs text-gray-500 mb-1">종료 날짜 (선택)</p>
            <input
              type="date"
              value={endDate}
              min={startDate}
              max={new Date().toISOString().slice(0, 10)}
              onChange={(e) => setEndDate(e.target.value)}
              className="w-full text-sm border border-gray-200 rounded-xl px-3 py-2 focus:outline-none focus:ring-2 focus:ring-blue-400"
            />
          </div>
        </div>

        <p className="text-xs text-gray-400">
          날짜를 비워두면 전체 기간 데이터를 내보냅니다.
        </p>

        {error && (
          <p className="text-xs text-red-500">{error}</p>
        )}

        <Button
          onClick={handleExport}
          disabled={loading}
          className="w-full flex items-center justify-center gap-2"
        >
          <Download className="w-4 h-4" />
          {loading ? "내보내는 중..." : "다운로드"}
        </Button>
      </div>
    </div>
  );
}
