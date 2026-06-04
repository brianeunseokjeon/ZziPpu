"use client";

import { useEffect, useRef, useState } from "react";
import { useRouter } from "next/navigation";
import { Mail, Loader2, Ticket } from "lucide-react";

import {
  requestEmailOtp,
  verifyEmailOtp,
  redeemInviteCode,
} from "@/features/auth/api/authApi";
import { useAuthStore } from "@/features/auth/store/authStore";
import { useBabyStore } from "@/features/baby/store/babyStore";
import { resolveLandingAfterTerms } from "@/features/auth/lib/postLogin";

type Step = "email" | "code" | "invite";

const EMAIL_RE = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;

export default function LoginPage() {
  const router = useRouter();
  const setSession = useAuthStore((s) => s.setSession);
  const setBabyId = useBabyStore((s) => s.setBabyId);

  const [step, setStep] = useState<Step>("email");
  const [email, setEmail] = useState("");
  const [code, setCode] = useState("");
  const [invite, setInvite] = useState("");
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [resendLeft, setResendLeft] = useState(0);

  const codeRef = useRef<HTMLInputElement>(null);

  // 재전송 카운트다운
  useEffect(() => {
    if (resendLeft <= 0) return;
    const t = setTimeout(() => setResendLeft((n) => n - 1), 1000);
    return () => clearTimeout(t);
  }, [resendLeft]);

  // 코드 단계 진입 시 자동 포커스
  useEffect(() => {
    if (step === "code") codeRef.current?.focus();
  }, [step]);

  async function handleRequestOtp() {
    setError(null);
    if (!EMAIL_RE.test(email.trim())) {
      setError("올바른 이메일 주소를 입력해주세요.");
      return;
    }
    setLoading(true);
    try {
      await requestEmailOtp(email.trim());
      setStep("code");
      setResendLeft(60);
    } catch (e) {
      setError(e instanceof Error ? e.message : "전송에 실패했습니다.");
    } finally {
      setLoading(false);
    }
  }

  // 검증 성공 후 공통 흐름: 약관 필요하면 /terms, 아니면 babies 확인.
  async function routeAfterAuth(termsRequired: boolean) {
    if (termsRequired) {
      router.replace("/terms");
      return;
    }
    const dest = await resolveLandingAfterTerms();
    router.replace(dest);
  }

  async function handleVerifyOtp() {
    setError(null);
    if (code.length !== 6) {
      setError("인증번호 6자리를 입력해주세요.");
      return;
    }
    setLoading(true);
    try {
      const result = await verifyEmailOtp(email.trim(), code);
      setSession({
        accessToken: result.accessToken,
        userId: result.userId,
        isNewUser: result.isNewUser,
        termsRequired: result.termsRequired,
      });
      await routeAfterAuth(result.termsRequired);
    } catch (e) {
      setError(e instanceof Error ? e.message : "인증에 실패했습니다.");
    } finally {
      setLoading(false);
    }
  }

  async function handleResend() {
    if (resendLeft > 0) return;
    setError(null);
    setLoading(true);
    try {
      await requestEmailOtp(email.trim());
      setResendLeft(60);
      setCode("");
    } catch (e) {
      setError(e instanceof Error ? e.message : "재전송에 실패했습니다.");
    } finally {
      setLoading(false);
    }
  }

  async function handleRedeemInvite() {
    setError(null);
    if (!invite.trim()) {
      setError("초대코드를 입력해주세요.");
      return;
    }
    setLoading(true);
    try {
      const result = await redeemInviteCode(invite.trim());
      setSession({
        accessToken: result.accessToken,
        userId: result.userId,
        isNewUser: result.isNewUser,
        termsRequired: result.termsRequired,
      });
      // 코드 로그인은 아기가 이미 연결됨 → babyId 즉시 저장, 온보딩 없음.
      setBabyId(result.babyId);
      if (result.termsRequired) {
        router.replace("/terms");
      } else {
        router.replace("/");
      }
    } catch (e) {
      setError(e instanceof Error ? e.message : "코드 확인에 실패했습니다.");
    } finally {
      setLoading(false);
    }
  }

  return (
    <div className="space-y-6">
      <div className="text-center">
        <div className="text-5xl mb-3">👶</div>
        <h1 className="text-2xl font-bold text-gray-900">먹놀잠</h1>
        <p className="text-sm text-gray-500 mt-1">신생아 육아 기록</p>
      </div>

      <div className="bg-white rounded-2xl shadow-sm border border-gray-100 p-6 space-y-4">
        {step === "email" && (
          <>
            <label className="block">
              <span className="text-sm font-medium text-gray-700 flex items-center gap-1.5">
                <Mail className="w-4 h-4" /> 이메일
              </span>
              <input
                type="email"
                inputMode="email"
                autoComplete="email"
                placeholder="you@example.com"
                value={email}
                onChange={(e) => setEmail(e.target.value)}
                onKeyDown={(e) => e.key === "Enter" && !loading && handleRequestOtp()}
                className="mt-1.5 w-full h-12 px-4 rounded-xl border border-gray-200 text-lg focus:outline-none focus:ring-2 focus:ring-blue-400"
                autoFocus
              />
            </label>
            <button
              onClick={handleRequestOtp}
              disabled={loading || !email}
              className="w-full h-12 rounded-xl bg-blue-500 hover:bg-blue-600 disabled:bg-gray-200 disabled:text-gray-400 text-white font-semibold flex items-center justify-center gap-2"
            >
              {loading && <Loader2 className="w-4 h-4 animate-spin" />}
              인증번호 받기
            </button>
            <p className="text-xs text-gray-400 text-center">
              회원가입 없이 이메일 주소만으로 시작합니다.
            </p>

            <div className="pt-2 border-t border-gray-100">
              <button
                onClick={() => {
                  setStep("invite");
                  setError(null);
                }}
                className="w-full text-sm text-gray-500 flex items-center justify-center gap-1.5 hover:text-gray-700"
              >
                <Ticket className="w-4 h-4" /> 초대코드로 참여
              </button>
            </div>
          </>
        )}

        {step === "code" && (
          <>
            <div className="text-sm text-gray-600">
              <span className="text-gray-400">전송:</span>{" "}
              <span className="font-medium text-gray-800">{email}</span>
              <button
                onClick={() => {
                  setStep("email");
                  setCode("");
                  setError(null);
                }}
                className="ml-2 text-xs text-blue-500 underline"
              >
                이메일 변경
              </button>
            </div>

            <label className="block">
              <span className="text-sm font-medium text-gray-700">인증번호 6자리</span>
              <input
                ref={codeRef}
                type="text"
                inputMode="numeric"
                autoComplete="one-time-code"
                maxLength={6}
                placeholder="000000"
                value={code}
                onChange={(e) => setCode(e.target.value.replace(/[^0-9]/g, "").slice(0, 6))}
                onKeyDown={(e) => e.key === "Enter" && !loading && handleVerifyOtp()}
                className="mt-1.5 w-full h-14 px-4 rounded-xl border border-gray-200 text-2xl text-center tracking-[0.5em] tabular-nums focus:outline-none focus:ring-2 focus:ring-blue-400"
              />
            </label>

            <button
              onClick={handleVerifyOtp}
              disabled={loading || code.length !== 6}
              className="w-full h-12 rounded-xl bg-blue-500 hover:bg-blue-600 disabled:bg-gray-200 disabled:text-gray-400 text-white font-semibold flex items-center justify-center gap-2"
            >
              {loading && <Loader2 className="w-4 h-4 animate-spin" />}
              확인
            </button>

            <button
              onClick={handleResend}
              disabled={resendLeft > 0 || loading}
              className="w-full text-sm text-gray-500 disabled:text-gray-300"
            >
              {resendLeft > 0 ? `${resendLeft}초 후 재전송 가능` : "인증번호 재전송"}
            </button>
          </>
        )}

        {step === "invite" && (
          <>
            <label className="block">
              <span className="text-sm font-medium text-gray-700 flex items-center gap-1.5">
                <Ticket className="w-4 h-4" /> 초대코드
              </span>
              <input
                type="text"
                placeholder="공유받은 코드 입력"
                value={invite}
                onChange={(e) => setInvite(e.target.value.toUpperCase())}
                onKeyDown={(e) => e.key === "Enter" && !loading && handleRedeemInvite()}
                className="mt-1.5 w-full h-12 px-4 rounded-xl border border-gray-200 text-lg tracking-widest text-center uppercase focus:outline-none focus:ring-2 focus:ring-blue-400"
                autoFocus
              />
            </label>
            <button
              onClick={handleRedeemInvite}
              disabled={loading || !invite}
              className="w-full h-12 rounded-xl bg-blue-500 hover:bg-blue-600 disabled:bg-gray-200 disabled:text-gray-400 text-white font-semibold flex items-center justify-center gap-2"
            >
              {loading && <Loader2 className="w-4 h-4 animate-spin" />}
              참여하기
            </button>
            <p className="text-xs text-gray-400 text-center">
              초대받은 아기의 기록을 함께 남길 수 있어요.
            </p>

            <div className="pt-2 border-t border-gray-100">
              <button
                onClick={() => {
                  setStep("email");
                  setError(null);
                }}
                className="w-full text-sm text-gray-500 flex items-center justify-center gap-1.5 hover:text-gray-700"
              >
                <Mail className="w-4 h-4" /> 이메일로 로그인
              </button>
            </div>
          </>
        )}

        {error && (
          <div className="text-sm text-red-500 bg-red-50 border border-red-100 rounded-lg px-3 py-2">
            {error}
          </div>
        )}
      </div>
    </div>
  );
}
