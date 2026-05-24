"use client";

import { useState, useRef } from "react";
import { Download, Loader2, Sparkles, PlayCircle } from "lucide-react";
import { Button } from "@/shared/components/ui/button";
import { Input } from "@/shared/components/ui/input";
import { downloadTranscript, streamSummary } from "../api/youtubeApi";

export function YouTubeSummaryPage() {
  const [url, setUrl] = useState("");
  const [error, setError] = useState<string | null>(null);
  const [isDownloading, setIsDownloading] = useState(false);
  const [isSummarizing, setIsSummarizing] = useState(false);
  const [summary, setSummary] = useState<string>("");
  const [summaryDone, setSummaryDone] = useState(false);
  const abortRef = useRef<boolean>(false);

  const isValidUrl = url.trim() !== "" && (url.includes("youtube.com") || url.includes("youtu.be"));

  async function handleDownload() {
    setError(null);
    setIsDownloading(true);
    try {
      await downloadTranscript(url.trim());
    } catch (e) {
      setError(e instanceof Error ? e.message : "다운로드 실패");
    } finally {
      setIsDownloading(false);
    }
  }

  async function handleSummarize() {
    setError(null);
    setSummary("");
    setSummaryDone(false);
    abortRef.current = false;
    setIsSummarizing(true);

    try {
      for await (const chunk of streamSummary(url.trim())) {
        if (abortRef.current) break;
        setSummary((prev) => prev + chunk);
      }
      setSummaryDone(true);
    } catch (e) {
      setError(e instanceof Error ? e.message : "요약 실패");
    } finally {
      setIsSummarizing(false);
    }
  }

  /** 완성된 요약을 .txt로 저장 */
  function handleDownloadSummary() {
    const blob = new Blob([summary], { type: "text/plain; charset=utf-8" });
    const a = document.createElement("a");
    a.href = URL.createObjectURL(blob);
    a.download = "youtube_summary.txt";
    a.click();
    URL.revokeObjectURL(a.href);
  }

  return (
    <div className="space-y-5">
      {/* 헤더 */}
      <div className="flex items-center gap-2">
        <PlayCircle className="w-5 h-5 text-red-500" />
        <h2 className="text-base font-semibold text-gray-800">YouTube 자막 요약</h2>
      </div>

      {/* URL 입력 */}
      <div className="space-y-2">
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
        {error && (
          <p className="text-xs text-red-500">{error}</p>
        )}
      </div>

      {/* 액션 버튼 */}
      <div className="grid grid-cols-2 gap-3">
        <Button
          variant="outline"
          onClick={handleDownload}
          disabled={!isValidUrl || isDownloading || isSummarizing}
          className="h-11 gap-2 text-sm"
        >
          {isDownloading ? (
            <Loader2 className="w-4 h-4 animate-spin" />
          ) : (
            <Download className="w-4 h-4" />
          )}
          자막 .txt 저장
        </Button>
        <Button
          onClick={handleSummarize}
          disabled={!isValidUrl || isDownloading || isSummarizing}
          className="h-11 gap-2 text-sm bg-blue-500 hover:bg-blue-600"
        >
          {isSummarizing ? (
            <Loader2 className="w-4 h-4 animate-spin" />
          ) : (
            <Sparkles className="w-4 h-4" />
          )}
          AI 요약 시작
        </Button>
      </div>

      {/* 요약 결과 */}
      {(summary || isSummarizing) && (
        <div className="space-y-3">
          <div className="flex items-center justify-between">
            <span className="text-xs font-semibold text-gray-500 uppercase tracking-wide">
              AI 요약 결과
            </span>
            {isSummarizing && (
              <span className="text-xs text-blue-500 flex items-center gap-1">
                <Loader2 className="w-3 h-3 animate-spin" /> 요약 중...
              </span>
            )}
          </div>

          <div className="bg-gray-50 rounded-2xl border border-gray-100 p-4 max-h-[60vh] overflow-y-auto">
            <SummaryRenderer text={summary} />
          </div>

          {summaryDone && (
            <Button
              variant="outline"
              onClick={handleDownloadSummary}
              className="w-full h-10 gap-2 text-sm"
            >
              <Download className="w-4 h-4" />
              요약 .txt 저장
            </Button>
          )}
        </div>
      )}

      {/* 사용 안내 */}
      {!summary && !isSummarizing && (
        <div className="rounded-2xl border border-gray-100 bg-gray-50 p-4 space-y-1.5">
          <p className="text-xs font-semibold text-gray-600">사용 방법</p>
          <ul className="text-xs text-gray-500 space-y-1 list-disc list-inside">
            <li>유튜브 영상 URL을 입력하세요</li>
            <li><strong>자막 .txt 저장</strong> — 원본 자막을 텍스트 파일로 다운로드</li>
            <li><strong>AI 요약 시작</strong> — 섹션별 타이틀과 핵심 내용으로 요약</li>
            <li>한국어·영어 자막 모두 지원 (영어 자막은 한국어로 번역)</li>
          </ul>
        </div>
      )}
    </div>
  );
}

/** Markdown의 ## 헤더를 강조해 렌더링하는 컴포넌트 */
function SummaryRenderer({ text }: { text: string }) {
  if (!text) return null;

  const lines = text.split("\n");

  return (
    <div className="text-sm text-gray-800 leading-relaxed space-y-1">
      {lines.map((line, i) => {
        if (line.startsWith("## ")) {
          return (
            <p key={i} className="font-bold text-blue-700 text-base mt-4 first:mt-0">
              {line.slice(3)}
            </p>
          );
        }
        if (line.startsWith("# ")) {
          return (
            <p key={i} className="font-bold text-gray-900 text-lg mt-4 first:mt-0">
              {line.slice(2)}
            </p>
          );
        }
        if (line === "") {
          return <div key={i} className="h-2" />;
        }
        return <p key={i}>{line}</p>;
      })}
    </div>
  );
}
