"use client";

import { useState } from "react";
import Link from "next/link";
import {
  Palette,
  Info,
  ChevronRight,
  TrendingUp,
  ClipboardList,
  Check,
  X,
  Download,
  LogOut,
} from "lucide-react";
import { Card, CardContent } from "@/shared/components/ui/card";
import { useBabyInfo } from "@/features/baby/hooks/useBabyInfo";
import { apiClient } from "@/lib/api-client";
import ExportModal from "@/features/baby/components/ExportModal";
import { PhotoUploader } from "@/features/baby/components/PhotoUploader";
import { LogoutButton } from "@/features/auth/components/LogoutButton";
import { CaregiverCard } from "@/features/caregiver/components/CaregiverCard";
import { useRecordingDefaultsStore } from "@/shared/stores/recordingDefaultsStore";
import { WeightInline } from "@/features/growth/components/WeightInline";
import { useGrowthRecords } from "@/features/growth/api/growthApi";

const ML_PRESETS = [60, 80, 100, 120, 150, 180];

export default function SettingsPage() {
  const { babyId, name, birthDate, gender, ageText, photoUrl, setName, setBirthDate, setPhotoUrl } =
    useBabyInfo();
  const recordingDefaults = useRecordingDefaultsStore();

  const [editingName, setEditingName] = useState(false);
  const [nameInput, setNameInput] = useState(name);

  const [editingBirth, setEditingBirth] = useState(false);
  const [birthInput, setBirthInput] = useState(birthDate);

  const [showExport, setShowExport] = useState(false);

  const { data: growthRecords } = useGrowthRecords(babyId ?? "");
  const latestWeightG =
    growthRecords
      ?.filter((r) => r.weightG != null)
      .sort((a, b) => b.recordedAt.localeCompare(a.recordedAt))[0]?.weightG ?? null;

  async function handlePhotoUpload(base64: string) {
    setPhotoUrl(base64);
    try {
      await apiClient.patch(`/api/v1/babies/${babyId}`, { photoUrl: base64 });
    } catch {
      // 저장 실패해도 로컬 상태는 유지
    }
  }

  function saveName() {
    if (nameInput.trim()) {
      setName(nameInput.trim());
      apiClient.patch(`/api/v1/babies/${babyId}`, { name: nameInput.trim() }).catch(() => {});
    }
    setEditingName(false);
  }

  function saveBirth() {
    if (birthInput) {
      setBirthDate(birthInput);
      apiClient.patch(`/api/v1/babies/${babyId}`, { birthDate: birthInput }).catch(() => {});
    }
    setEditingBirth(false);
  }

  return (
    <div className="space-y-4">
      {/* 아기 프로필 + 정보 편집 (통합) */}
      <Card>
        <CardContent className="pt-4">
          {/* 사진 + 이름/나이 */}
          <div className="flex items-center gap-4 pb-3 border-b border-gray-50">
            <div className="flex flex-col items-center gap-1">
              <PhotoUploader currentUrl={photoUrl} gender={gender} onUpload={handlePhotoUpload} />
              <span className="text-xs text-gray-400">사진 변경</span>
            </div>
            <div>
              <p className="font-bold text-gray-900 text-lg">{name}</p>
              <p className="text-sm text-gray-500">{ageText}</p>
            </div>
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
          <div className="py-3 px-1 border-b border-gray-50">
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

          {/* 현재 체중 (growth record SSOT) */}
          <div className="py-3 px-1">
            <p className="text-xs text-gray-400 mb-1">현재 체중</p>
            {babyId && <WeightInline babyId={babyId} weightG={latestWeightG} />}
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

      {/* 공동 양육자 */}
      <CaregiverCard />

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

      {/* 기록 디폴트 */}
      <Card>
        <CardContent className="pt-4">
          <div className="flex items-center gap-2 mb-3">
            <ClipboardList className="w-4 h-4 text-blue-500" />
            <h3 className="text-sm font-semibold text-gray-700">기록 디폴트</h3>
          </div>

          {/* 디폴트 분유량 */}
          <div className="py-3 border-b border-gray-50">
            <p className="text-xs text-gray-400 mb-2">기본 분유량</p>
            <div className="flex flex-wrap gap-1.5">
              {ML_PRESETS.map((ml) => (
                <button
                  key={ml}
                  onClick={() => recordingDefaults.setFormulaMl(ml)}
                  className={`px-3 py-1.5 rounded-full text-xs font-medium border transition-colors ${
                    recordingDefaults.formulaMl === ml
                      ? "bg-blue-500 text-white border-blue-500"
                      : "bg-white text-gray-600 border-gray-200"
                  }`}
                >
                  {ml}ml
                </button>
              ))}
            </div>
          </div>

          {/* 디폴트 모유 측 */}
          <div className="py-3">
            <p className="text-xs text-gray-400 mb-2">기본 모유 방향</p>
            <div className="flex gap-2">
              {(["left", "right", "both"] as const).map((side) => {
                const labels = { left: "왼쪽", right: "오른쪽", both: "양쪽" };
                return (
                  <button
                    key={side}
                    onClick={() => recordingDefaults.setBreastSide(side)}
                    className={`flex-1 py-2 rounded-xl text-xs font-medium border-2 transition-all ${
                      recordingDefaults.breastSide === side
                        ? "bg-pink-50 border-pink-400 text-pink-700"
                        : "bg-white border-gray-200 text-gray-600"
                    }`}
                  >
                    {labels[side]}
                  </button>
                );
              })}
            </div>
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
            <p>찌뿌둥 - 신생아 육아 기록</p>
          </div>
        </CardContent>
      </Card>

      {/* 계정 */}
      <Card>
        <CardContent className="pt-4">
          <div className="flex items-center gap-2 mb-3">
            <LogOut className="w-4 h-4 text-gray-500" />
            <h3 className="text-sm font-semibold text-gray-700">계정</h3>
          </div>
          <LogoutButton />
        </CardContent>
      </Card>

      {showExport && <ExportModal onClose={() => setShowExport(false)} />}
    </div>
  );
}
