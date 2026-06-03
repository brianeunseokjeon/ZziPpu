"use client";

import { useState } from "react";
import { Users, Copy, Check, UserPlus, Ticket } from "lucide-react";
import { Card, CardContent } from "@/shared/components/ui/card";
import { useUIStore } from "@/shared/stores/uiStore";
import {
  useCaregivers,
  useCreateInvite,
  useJoinByCode,
} from "../api/caregiverApi";
import { formatTime } from "@/lib/date-utils";

export function CaregiverCard() {
  const { activeBabyId } = useUIStore();
  const { data: members } = useCaregivers(activeBabyId);
  const createInvite = useCreateInvite();
  const joinByCode = useJoinByCode();

  const [copied, setCopied] = useState(false);
  const [joinCode, setJoinCode] = useState("");
  const [joinMessage, setJoinMessage] = useState<string | null>(null);

  const invite = createInvite.data;

  async function handleGenerate() {
    setCopied(false);
    await createInvite.mutateAsync(activeBabyId);
  }

  async function handleCopy() {
    if (!invite) return;
    try {
      await navigator.clipboard.writeText(invite.code);
      setCopied(true);
      setTimeout(() => setCopied(false), 2000);
    } catch {
      // 클립보드 미지원 환경은 무시
    }
  }

  async function handleJoin() {
    const code = joinCode.trim().toUpperCase();
    if (!code) return;
    setJoinMessage(null);
    try {
      const baby = await joinByCode.mutateAsync(code);
      setJoinMessage(`"${baby.name}" 아기에 참여했어요!`);
      setJoinCode("");
    } catch (e) {
      setJoinMessage(e instanceof Error ? e.message : "참여에 실패했어요");
    }
  }

  const memberCount = members?.length ?? 0;

  return (
    <Card>
      <CardContent className="pt-4">
        <div className="flex items-center gap-2 mb-3">
          <Users className="w-4 h-4 text-teal-500" />
          <h3 className="text-sm font-semibold text-gray-700">공동 양육자</h3>
          {memberCount > 0 && (
            <span className="ml-auto text-xs font-medium text-teal-600 bg-teal-50 px-2 py-0.5 rounded-full">
              함께 보는 사람 {memberCount}명
            </span>
          )}
        </div>

        <p className="text-xs text-gray-400 mb-3">
          초대코드를 공유하면 배우자도 같은 기록을 실시간으로 함께 볼 수 있어요.
        </p>

        {/* 초대코드 생성 */}
        <div className="py-2">
          {invite ? (
            <div className="flex items-center gap-2">
              <div className="flex-1 bg-teal-50 border border-teal-200 rounded-xl px-4 py-2.5 flex items-center justify-between">
                <span className="text-lg font-bold tracking-[0.3em] text-teal-700">
                  {invite.code}
                </span>
                <span className="text-[11px] text-teal-500">
                  {formatTime(invite.expiresAt)}까지
                </span>
              </div>
              <button
                onClick={handleCopy}
                className="p-2.5 rounded-xl bg-teal-500 text-white hover:bg-teal-600 transition-colors"
                aria-label="초대코드 복사"
              >
                {copied ? (
                  <Check className="w-4 h-4" />
                ) : (
                  <Copy className="w-4 h-4" />
                )}
              </button>
            </div>
          ) : (
            <button
              onClick={handleGenerate}
              disabled={createInvite.isPending}
              className="w-full flex items-center justify-center gap-2 py-2.5 rounded-xl border-2 border-teal-200 text-teal-700 font-medium text-sm hover:bg-teal-50 transition-colors disabled:opacity-50"
            >
              <Ticket className="w-4 h-4" />
              {createInvite.isPending ? "생성 중..." : "초대코드 만들기"}
            </button>
          )}
          {createInvite.isError && (
            <p className="text-xs text-red-500 mt-1.5">
              {createInvite.error instanceof Error
                ? createInvite.error.message
                : "초대코드 생성에 실패했어요"}
            </p>
          )}
          {invite && (
            <button
              onClick={handleGenerate}
              disabled={createInvite.isPending}
              className="text-xs text-gray-400 mt-2 hover:text-gray-600"
            >
              새 코드 발급
            </button>
          )}
        </div>

        {/* 코드로 참여 */}
        <div className="mt-3 pt-3 border-t border-gray-50">
          <p className="text-xs text-gray-400 mb-2 flex items-center gap-1">
            <UserPlus className="w-3.5 h-3.5" /> 받은 초대코드로 참여하기
          </p>
          <div className="flex items-center gap-2">
            <input
              type="text"
              value={joinCode}
              onChange={(e) => setJoinCode(e.target.value.toUpperCase())}
              onKeyDown={(e) => e.key === "Enter" && handleJoin()}
              placeholder="초대코드 입력"
              maxLength={12}
              className="flex-1 text-sm tracking-widest uppercase border border-gray-200 rounded-xl px-3 py-2 focus:outline-none focus:ring-2 focus:ring-teal-400"
            />
            <button
              onClick={handleJoin}
              disabled={joinByCode.isPending || !joinCode.trim()}
              className="px-4 py-2 rounded-xl bg-teal-500 text-white text-sm font-medium hover:bg-teal-600 transition-colors disabled:opacity-50"
            >
              {joinByCode.isPending ? "참여 중..." : "참여"}
            </button>
          </div>
          {joinMessage && (
            <p
              className={`text-xs mt-1.5 ${
                joinByCode.isError ? "text-red-500" : "text-teal-600"
              }`}
            >
              {joinMessage}
            </p>
          )}
        </div>
      </CardContent>
    </Card>
  );
}
