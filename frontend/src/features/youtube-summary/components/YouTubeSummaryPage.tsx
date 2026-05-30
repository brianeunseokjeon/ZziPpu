"use client";

import { useState } from "react";
import { Download, Loader2, Sparkles, PlayCircle, RefreshCw } from "lucide-react";
import { Button } from "@/shared/components/ui/button";
import { Input } from "@/shared/components/ui/input";
import { fetchTranscriptText, saveTranscriptFile, streamSummary } from "../api/youtubeApi";

type Step = "idle" | "fetching" | "loaded" | "summarizing" | "done";

export function YouTubeSummaryPage() {
  const [url, setUrl] = useState("");
  const [error, setError] = useState<string | null>(null);
  const [step, setStep] = useState<Step>("idle");
  const [transcript, setTranscript] = useState<string>("");
  const [summary, setSummary] = useState<string>("");

  const isValidUrl =
    url.trim() !== "" && (url.includes("youtube.com") || url.includes("youtu.be"));

  /** 영상 ID 파싱 (파일명용) */
  function parseVideoId(u: string): string {
    const m = u.match(/(?:v=|youtu\.be\/|shorts\/)([A-Za-z0-9_-]{11})/);
    return m?.[1] ?? "transcript";
  }

  async function handleFetch() {
    setError(null);
    setTranscript("");
    setSummary("");
    setStep("fetching");
    try {
      const text = await fetchTranscriptText(url.trim());
      setTranscript(text);
      setStep("loaded");
    } catch (e) {
      setError(e instanceof Error ? e.message : "자막을 가져오지 못했습니다.");
      setStep("idle");
    }
  }

  async function handleSummarize() {
    setError(null);
    setSummary("");
    setStep("summarizing");
    try {
      for await (const chunk of streamSummary(url.trim())) {
        setSummary((prev) => prev + chunk);
      }
      setStep("done");
    } catch (e) {
      setError(e instanceof Error ? e.message : "요약 실패");
      setStep("loaded");
    }
  }

  function handleReset() {
    setUrl("");
    setTranscript("");
    setSummary("");
    setError(null);
    setStep("idle");
  }

  const isBusy = step === "fetching" || step === "summarizing";

  return (
    <div className="space-y-5">
      {/* 헤더 */}
      <div className="flex items-center justify-between">
        <div className="flex items-center gap-2">
          <PlayCircle className="w-5 h-5 text-red-500" />
          <h2 className="text-base font-semibold text-gray-800">YouTube 자막 요약</h2>
        </div>
        {step !== "idle" && (
          <button
            onClick={handleReset}
            className="flex items-center gap-1 text-xs text-gray-400 hover:text-gray-600"
          >
            <RefreshCw className="w-3 h-3" /> 초기화
          </button>
        )}
      </div>

      {/* URL 입력 + 자막 가져오기 */}
      {step === "idle" && (
        <div className="space-y-3">
          <Input
            type="url"
            placeholder="https://youtube.com/watch?v=..."
            value={url}
            onChange={(e) => {
              setUrl(e.target.value);
              setError(null);
            }}
            className="h-11 text-sm"
          />
          {error && <p className="text-xs text-red-500">{error}</p>}
          <Button
            onClick={handleFetch}
            disabled={!isValidUrl}
            className="w-full h-11 bg-blue-500 hover:bg-blue-600 gap-2"
          >
            <PlayCircle className="w-4 h-4" />
            자막 가져오기
          </Button>

          {/* 안내 */}
          <div className="rounded-2xl border border-gray-100 bg-gray-50 p-4 space-y-1.5">
            <p className="text-xs font-semibold text-gray-600">사용 방법</p>
            <ul className="text-xs text-gray-500 space-y-1 list-disc list-inside">
              <li>유튜브 URL을 입력하고 자막을 불러오세요</li>
              <li>원문 전체를 확인하고 .txt로 저장할 수 있어요</li>
              <li>AI 요약으로 핵심 내용을 섹션별로 정리해드려요</li>
              <li>한국어·영어 자막 지원 (영어는 한국어로 번역)</li>
            </ul>
          </div>
        </div>
      )}

      {/* 자막 불러오는 중 */}
      {step === "fetching" && (
        <div className="flex flex-col items-center gap-3 py-10 text-gray-500">
          <Loader2 className="w-8 h-8 animate-spin text-blue-400" />
          <p className="text-sm">자막을 가져오는 중...</p>
        </div>
      )}

      {/* 자막 로드 완료 이후 */}
      {(step === "loaded" || step === "summarizing" || step === "done") && (
        <div className="space-y-4">
          {/* 현재 URL 표시 */}
          <div className="flex items-center gap-2 text-xs text-gray-400 bg-gray-50 rounded-xl px-3 py-2 truncate">
            <PlayCircle className="w-3.5 h-3.5 flex-shrink-0 text-red-400" />
            <span className="truncate">{url}</span>
          </div>

          {error && <p className="text-xs text-red-500">{error}</p>}

          {/* 원문 자막 */}
          <section className="space-y-2">
            <div className="flex items-center justify-between">
              <span className="text-xs font-semibold text-gray-600">원문 자막</span>
              <span className="text-xs text-gray-400">{transcript.split("\n").length}줄</span>
            </div>
            <pre className="whitespace-pre-wrap text-xs text-gray-700 leading-relaxed bg-gray-50 rounded-2xl border border-gray-100 p-4 overflow-y-auto max-h-[40vh]">
              {transcript}
            </pre>
            <Button
              variant="outline"
              onClick={() => saveTranscriptFile(transcript, parseVideoId(url))}
              className="w-full h-10 gap-2 text-sm"
              disabled={isBusy}
            >
              <Download className="w-4 h-4" />
              자막 원문 .txt 저장
            </Button>
          </section>

          {/* AI 요약 */}
          <section className="space-y-2">
            {step === "loaded" && (
              <Button
                onClick={handleSummarize}
                disabled={isBusy}
                className="w-full h-11 bg-blue-500 hover:bg-blue-600 gap-2 text-sm"
              >
                <Sparkles className="w-4 h-4" />
                AI 요약 시작
              </Button>
            )}

            {(step === "summarizing" || step === "done") && (
              <>
                <div className="flex items-center justify-between">
                  <span className="text-xs font-semibold text-gray-600">AI 요약 결과</span>
                  {step === "summarizing" && (
                    <span className="text-xs text-blue-500 flex items-center gap-1">
                      <Loader2 className="w-3 h-3 animate-spin" /> 요약 중...
                    </span>
                  )}
                </div>
                <div className="bg-gray-50 rounded-2xl border border-gray-100 p-4 overflow-y-auto max-h-[60vh]">
                  <SummaryRenderer text={summary} />
                </div>
                {step === "done" && (
                  <Button
                    variant="outline"
                    onClick={() => {
                      const blob = new Blob([summary], { type: "text/plain; charset=utf-8" });
                      const a = document.createElement("a");
                      a.href = URL.createObjectURL(blob);
                      a.download = `${parseVideoId(url)}_summary.txt`;
                      a.click();
                      URL.revokeObjectURL(a.href);
                    }}
                    className="w-full h-10 gap-2 text-sm"
                  >
                    <Download className="w-4 h-4" />
                    요약 .txt 저장
                  </Button>
                )}
              </>
            )}
          </section>
        </div>
      )}
    </div>
  );
}

function SummaryRenderer({ text }: { text: string }) {
  if (!text) return null;
  const lines = text.split("\n");
  return (
    <div className="text-sm text-gray-800 leading-relaxed space-y-1">
      {lines.map((line, i) => {
        if (line.startsWith("## "))
          return (
            <p key={i} className="font-bold text-blue-700 text-base mt-4 first:mt-0">
              {line.slice(3)}
            </p>
          );
        if (line.startsWith("# "))
          return (
            <p key={i} className="font-bold text-gray-900 text-lg mt-4 first:mt-0">
              {line.slice(2)}
            </p>
          );
        if (line === "") return <div key={i} className="h-2" />;
        return <p key={i}>{line}</p>;
      })}
    </div>
  );
}
