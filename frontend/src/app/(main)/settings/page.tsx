"use client";

import Link from "next/link";
import { Baby, Bell, Palette, Info, ChevronRight, TrendingUp, Syringe } from "lucide-react";
import { Card, CardContent } from "@/shared/components/ui/card";
import { useUIStore } from "@/shared/stores/uiStore";
import { getAgeText } from "@/lib/date-utils";
import { MOCK_BIRTH_DATE } from "@/config/constants";

const SETTINGS_SECTIONS = [
  {
    title: "아기 정보",
    icon: Baby,
    items: [
      { label: "이름 변경", sub: "아기 이름을 수정합니다" },
      { label: "생일 설정", sub: MOCK_BIRTH_DATE },
    ],
  },
  {
    title: "알림",
    icon: Bell,
    items: [
      { label: "수유 알림", sub: "마지막 수유 후 알림 설정" },
      { label: "수면 알림", sub: "수면 권장 시간 알림" },
    ],
  },
  {
    title: "앱 설정",
    icon: Palette,
    items: [
      { label: "테마", sub: "라이트 모드" },
      { label: "데이터 내보내기", sub: "CSV / JSON 형식" },
    ],
  },
];

export default function SettingsPage() {
  const { activeBabyId } = useUIStore();

  return (
    <div className="space-y-4">
      <Card>
        <CardContent className="pt-4">
          <div className="flex items-center gap-4">
            <div className="w-14 h-14 rounded-full bg-gradient-to-br from-blue-300 to-purple-300 flex items-center justify-center text-2xl">
              👶
            </div>
            <div>
              <p className="font-bold text-gray-900 text-lg">우리 아기</p>
              <p className="text-sm text-gray-500">{getAgeText(MOCK_BIRTH_DATE)}</p>
              <p className="text-xs text-gray-400 mt-0.5">ID: {activeBabyId}</p>
            </div>
          </div>
        </CardContent>
      </Card>

      {SETTINGS_SECTIONS.map(({ title, icon: Icon, items }) => (
        <Card key={title}>
          <CardContent className="pt-4">
            <div className="flex items-center gap-2 mb-3">
              <Icon className="w-4 h-4 text-gray-500" />
              <h3 className="text-sm font-semibold text-gray-700">{title}</h3>
            </div>
            <div className="space-y-1">
              {items.map(({ label, sub }) => (
                <button
                  key={label}
                  className="w-full flex items-center justify-between py-3 px-1 hover:bg-gray-50 rounded-xl transition-colors"
                >
                  <div className="text-left">
                    <p className="text-sm font-medium text-gray-800">{label}</p>
                    {sub && <p className="text-xs text-gray-400">{sub}</p>}
                  </div>
                  <ChevronRight className="w-4 h-4 text-gray-300" />
                </button>
              ))}
            </div>
          </CardContent>
        </Card>
      ))}

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

      <Card>
        <CardContent className="pt-4">
          <div className="flex items-center gap-2 mb-3">
            <Info className="w-4 h-4 text-gray-500" />
            <h3 className="text-sm font-semibold text-gray-700">앱 정보</h3>
          </div>
          <div className="text-sm text-gray-500 space-y-1">
            <p>버전: 1.0.0 (MVP)</p>
            <p>먹놀잠 - 신생아 육아 기록</p>
          </div>
        </CardContent>
      </Card>
    </div>
  );
}
