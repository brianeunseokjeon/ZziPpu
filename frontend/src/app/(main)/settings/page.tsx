"use client";

import { useState } from "react";
import Link from "next/link";
import {
  Baby,
  Bell,
  Palette,
  Info,
  ChevronRight,
  TrendingUp,
  Syringe,
  Check,
  X,
  Download,
} from "lucide-react";
import { Card, CardContent } from "@/shared/components/ui/card";
import { useBabyInfo } from "@/features/baby/hooks/useBabyInfo";
import { API_BASE_URL, MOCK_BABY_ID } from "@/config/constants";
import ExportModal from "@/features/baby/components/ExportModal";
import { PhotoUploader } from "@/features/baby/components/PhotoUploader";
import { LogoutButton } from "@/features/auth/components/LogoutButton";

export default function SettingsPage() {
  const { name, birthDate, ageText, photoUrl, setName, setBirthDate, setPhotoUrl } = useBabyInfo();

  const [editingName, setEditingName] = useState(false);
  const [nameInput, setNameInput] = useState(name);

  const [editingBirth, setEditingBirth] = useState(false);
  const [birthInput, setBirthInput] = useState(birthDate);

  const [showExport, setShowExport] = useState(false);

  async function handlePhotoUpload(base64: string) {
    setPhotoUrl(base64);
    try {
      await fetch(`${API_BASE_URL}/api/v1/babies/${MOCK_BABY_ID}`, {
        method: "PATCH",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ photo_url: base64 }),
      });
    } catch {
      // 저장 실패해도 로컬 상태는 유지
    }
  }

  function saveName() {
    if (nameInput.trim()) {
      setName(nameInput.trim());
      fetch(`${API_BASE_URL}/api/v1/babies/${MOCK_BABY_ID}`, {
        method: "PATCH",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ name: nameInput.trim() }),
      }).catch(() => {});
    }
    setEditingName(false);
  }

  function saveBirth() {
    if (birthInput) {
      setBirthDate(birthInput);
      fetch(`${API_BASE_URL}/api/v1/babies/${MOCK_BABY_ID}`, {
        method: "PATCH",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ birth_date: birthInput }),
      }).catch(() => {});
    }
    setEditingBirth(false);
  }

  return (
    <div className="space-y-4">
      {/* 아기 프로필 카드 */}
      <Card>
        <CardContent className="pt-4">
          <div className="flex items-center gap-4">
            <div className="flex flex-col items-center gap-1">
              <PhotoUploader currentUrl={photoUrl} onUpload={handlePhotoUpload} />
              <span className="text-xs text-gray-400">사진 변경</span>
            </div>
            <div>
              <p className="font-bold text-gray-900 text-lg">{name}</p>
              <p className="text-sm text-gray-500">{ageText}</p>
              <p className="text-xs text-gray-400 mt-0.5">생일: {birthDate}</p>
            </div>
          </div>
        </CardContent>
      </Card>

      {/* 아기 정보 편집 */}
      <Card>
        <CardContent className="pt-4">
          <div className="flex items-center gap-2 mb-3">
            <Baby className="w-4 h-4 text-gray-500" />
            <h3 className="text-sm font-semibold text-gray-700">아기 정보</h3>
          </div>

          {/* 이름 편집 */}
          <div className="py-3 px-1 border-b border-gray-50">
            <p className="text-xs text-gray-400 mb-1">이름</p>
            {editingName ? (
              <div className="flex items-center gap-2">
                <input
                  type="text"
                  value={nameInput}
                  onChange={(e) => setNameInput(e.target.value)}
                  onKeyDown={(e) => e.key === "Enter" && saveName()}
                  className="flex-1 text-sm border border-gray-200 rounded-lg px-3 py-1.5 focus:outline-none focus:ring-2 focus:ring-blue-400"
                  autoFocus
                />
                <button onClick={saveName} className="p-1.5 text-green-500 hover:bg-green-50 rounded-lg">
                  <Check className="w-4 h-4" />
                </button>
                <button onClick={() => { setNameInput(name); setEditingName(false); }} className="p-1.5 text-gray-400 hover:bg-gray-50 rounded-lg">
                  <X className="w-4 h-4" />
                </button>
              </div>
            ) : (
              <button
                onClick={() => { setNameInput(name); setEditingName(true); }}
                className="w-full flex items-center justify-between hover:bg-gray-50 rounded-xl transition-colors"
              >
                <span className="text-sm font-medium text-gray-800">{name}</span>
                <ChevronRight className="w-4 h-4 text-gray-300" />
              </button>
            )}
          </div>

          {/* 생일 편집 */}
          <div className="py-3 px-1">
            <p className="text-xs text-gray-400 mb-1">생년월일</p>
            {editingBirth ? (
              <div className="flex items-center gap-2">
                <input
                  type="date"
                  value={birthInput}
                  max={new Date().toISOString().slice(0, 10)}
                  onChange={(e) => setBirthInput(e.target.value)}
                  className="flex-1 text-sm border border-gray-200 rounded-lg px-3 py-1.5 focus:outline-none focus:ring-2 focus:ring-blue-400"
                />
                <button onClick={saveBirth} className="p-1.5 text-green-500 hover:bg-green-50 rounded-lg">
                  <Check className="w-4 h-4" />
                </button>
                <button onClick={() => { setBirthInput(birthDate); setEditingBirth(false); }} className="p-1.5 text-gray-400 hover:bg-gray-50 rounded-lg">
                  <X className="w-4 h-4" />
                </button>
              </div>
            ) : (
              <button
                onClick={() => { setBirthInput(birthDate); setEditingBirth(true); }}
                className="w-full flex items-center justify-between hover:bg-gray-50 rounded-xl transition-colors"
              >
                <span className="text-sm font-medium text-gray-800">{birthDate}</span>
                <ChevronRight className="w-4 h-4 text-gray-300" />
              </button>
            )}
          </div>
        </CardContent>
      </Card>

      {/* 앱 설정 */}
      <Card>
        <CardContent className="pt-4">
          <div className="flex items-center gap-2 mb-3">
            <Palette className="w-4 h-4 text-gray-500" />
            <h3 className="text-sm font-semibold text-gray-700">앱 설정</h3>
          </div>
          <button
            onClick={() => setShowExport(true)}
            className="w-full flex items-center justify-between py-3 px-1 hover:bg-gray-50 rounded-xl transition-colors"
          >
            <div className="flex items-center gap-2">
              <Download className="w-4 h-4 text-blue-500" />
              <div className="text-left">
                <p className="text-sm font-medium text-gray-800">데이터 내보내기</p>
                <p className="text-xs text-gray-400">CSV / JSON 형식</p>
              </div>
            </div>
            <ChevronRight className="w-4 h-4 text-gray-300" />
          </button>
        </CardContent>
      </Card>

      {/* 건강 관리 */}
      <Card>
        <CardContent className="pt-4">
          <div className="flex items-center gap-2 mb-3">
            <TrendingUp className="w-4 h-4 text-purple-500" />
            <h3 className="text-sm font-semibold text-gray-700">건강 관리</h3>
          </div>
          <div className="space-y-1">
            <Link
              href="/growth"
              className="w-full flex items-center justify-between py-3 px-1 hover:bg-gray-50 rounded-xl transition-colors"
            >
              <div className="flex items-center gap-2.5">
                <span className="text-base">🌱</span>
                <div className="text-left">
                  <p className="text-sm font-medium text-gray-800">성장 기록</p>
                  <p className="text-xs text-gray-400">체중, 키, 머리둘레 기록</p>
                </div>
              </div>
              <ChevronRight className="w-4 h-4 text-gray-300" />
            </Link>
            <Link
              href="/vaccination"
              className="w-full flex items-center justify-between py-3 px-1 hover:bg-gray-50 rounded-xl transition-colors"
            >
              <div className="flex items-center gap-2.5">
                <span className="text-base">💉</span>
                <div className="text-left">
                  <p className="text-sm font-medium text-gray-800">예방접종 일정</p>
                  <p className="text-xs text-gray-400">접종 스케줄 및 완료 기록</p>
                </div>
              </div>
              <ChevronRight className="w-4 h-4 text-gray-300" />
            </Link>
          </div>
        </CardContent>
      </Card>

      {/* 앱 정보 */}
      <Card>
        <CardContent className="pt-4">
          <div className="flex items-center gap-2 mb-3">
            <Info className="w-4 h-4 text-gray-500" />
            <h3 className="text-sm font-semibold text-gray-700">앱 정보</h3>
          </div>
          <div className="text-sm text-gray-500 space-y-1">
            <p>버전: 1.2.0</p>
            <p>먹놀잠 - 신생아 육아 기록</p>
          </div>
        </CardContent>
      </Card>

      {/* 로그아웃 */}
      <LogoutButton />

      {showExport && <ExportModal onClose={() => setShowExport(false)} />}
    </div>
  );
}
