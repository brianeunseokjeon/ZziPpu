"use client";

import { useEffect, useState } from "react";
import { useRouter } from "next/navigation";
import { Loader2, FileText } from "lucide-react";

import { getTerms, agreeTerms, type TermDoc } from "@/features/auth/api/authApi";
import { useAuthStore } from "@/features/auth/store/authStore";
import { resolveLandingAfterTerms } from "@/features/auth/lib/postLogin";
import { Dialog } from "@/shared/components/ui/dialog";

export default function TermsPage() {
  const router = useRouter();
  const accessToken = useAuthStore((s) => s.accessToken);
  const setTermsRequired = useAuthStore((s) => s.setTermsRequired);

  const [terms, setTerms] = useState<TermDoc[]>([]);
  const [checked, setChecked] = useState<Record<string, boolean>>({});
  const [viewing, setViewing] = useState<TermDoc | null>(null);
  const [loading, setLoading] = useState(true);
  const [submitting, setSubmitting] = useState(false);
  const [error, setError] = useState<string | null>(null);

  // 비로그인 접근 차단
  useEffect(() => {
    if (!accessToken) router.replace("/login");
  }, [accessToken, router]);

  useEffect(() => {
    let alive = true;
    getTerms()
      .then((list) => {
        if (!alive) return;
        setTerms(list);
        setChecked(Object.fromEntries(list.map((t) => [t.type, false])));
      })
      .catch((e) => alive && setError(e instanceof Error ? e.message : "약관을 불러오지 못했습니다."))
      .finally(() => alive && setLoading(false));
    return () => {
      alive = false;
    };
  }, []);

  const requiredTerms = terms.filter((t) => t.required);
  const allRequiredChecked = requiredTerms.every((t) => checked[t.type]);
  const allChecked = terms.length > 0 && terms.every((t) => checked[t.type]);

  function toggleAll() {
    const next = !allChecked;
    setChecked(Object.fromEntries(terms.map((t) => [t.type, next])));
  }

  async function handleAgree() {
    setError(null);
    if (!allRequiredChecked) {
      setError("필수 약관에 모두 동의해주세요.");
      return;
    }
    setSubmitting(true);
    try {
      await agreeTerms(
        terms.filter((t) => checked[t.type]).map((t) => ({ type: t.type, version: t.version }))
      );
      setTermsRequired(false);
      try {
        const dest = await resolveLandingAfterTerms();
        router.replace(dest);
      } catch {
        router.replace("/onboarding");
      }
    } catch (e) {
      setError(e instanceof Error ? e.message : "동의 처리에 실패했습니다.");
    } finally {
      setSubmitting(false);
    }
  }

  if (loading) {
    return (
      <div className="flex justify-center py-16">
        <Loader2 className="w-6 h-6 animate-spin text-gray-400" />
      </div>
    );
  }

  return (
    <div className="space-y-6">
      <div className="text-center">
        <div className="text-5xl mb-3">📄</div>
        <h1 className="text-2xl font-bold text-gray-900">약관 동의</h1>
        <p className="text-sm text-gray-500 mt-1">서비스 이용을 위해 동의가 필요해요.</p>
      </div>

      <div className="bg-white rounded-2xl shadow-sm border border-gray-100 p-6 space-y-4">
        <button
          onClick={toggleAll}
          className={`w-full h-12 rounded-xl border text-sm font-semibold ${
            allChecked
              ? "bg-blue-50 border-blue-400 text-blue-700"
              : "bg-white border-gray-200 text-gray-700"
          }`}
        >
          {allChecked ? "전체 동의 해제" : "전체 동의"}
        </button>

        <div className="space-y-2">
          {terms.map((t) => (
            <div key={t.type} className="flex items-center gap-3 py-2">
              <input
                type="checkbox"
                id={`term-${t.type}`}
                checked={checked[t.type] ?? false}
                onChange={(e) =>
                  setChecked((prev) => ({ ...prev, [t.type]: e.target.checked }))
                }
                className="w-5 h-5 rounded accent-blue-500"
              />
              <label htmlFor={`term-${t.type}`} className="flex-1 text-sm text-gray-800">
                <span className={t.required ? "text-blue-600 font-medium" : "text-gray-400"}>
                  [{t.required ? "필수" : "선택"}]
                </span>{" "}
                {t.title}
              </label>
              <button
                onClick={() => setViewing(t)}
                className="text-gray-400 hover:text-gray-600 flex items-center gap-1 text-xs"
              >
                <FileText className="w-4 h-4" /> 전문
              </button>
            </div>
          ))}
        </div>

        {error && (
          <div className="text-sm text-red-500 bg-red-50 border border-red-100 rounded-lg px-3 py-2">
            {error}
          </div>
        )}

        <button
          onClick={handleAgree}
          disabled={submitting || !allRequiredChecked}
          className="w-full h-12 rounded-xl bg-blue-500 hover:bg-blue-600 disabled:bg-gray-200 disabled:text-gray-400 text-white font-semibold flex items-center justify-center gap-2"
        >
          {submitting && <Loader2 className="w-4 h-4 animate-spin" />}
          동의하고 시작하기
        </button>
      </div>

      <Dialog open={viewing !== null} onClose={() => setViewing(null)} title={viewing?.title}>
        <div className="prose prose-sm max-w-none whitespace-pre-wrap text-sm text-gray-700 leading-relaxed">
          {viewing?.content}
        </div>
      </Dialog>
    </div>
  );
}
