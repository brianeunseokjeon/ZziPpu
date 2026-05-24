"use client";

import { getAccessToken } from "@/features/auth/store/authStore";

const API_BASE_URL = process.env.NEXT_PUBLIC_API_URL ?? "http://localhost:8081";

function authHeaders(): Record<string, string> {
  const h: Record<string, string> = { "Content-Type": "application/json" };
  const token = getAccessToken();
  if (token) h.Authorization = `Bearer ${token}`;
  return h;
}

/** YouTube 자막을 .txt 파일로 다운로드한다. */
export async function downloadTranscript(url: string): Promise<void> {
  const res = await fetch(`${API_BASE_URL}/api/v1/youtube/transcript`, {
    method: "POST",
    headers: authHeaders(),
    body: JSON.stringify({ url }),
  });

  if (!res.ok) {
    const data = await res.json().catch(() => ({}));
    throw new Error(data.detail ?? "자막 다운로드에 실패했습니다.");
  }

  const blob = await res.blob();
  const disposition = res.headers.get("Content-Disposition") ?? "";
  const filenameMatch = disposition.match(/filename="([^"]+)"/);
  const filename = filenameMatch?.[1] ?? "transcript.txt";

  const objectUrl = URL.createObjectURL(blob);
  const a = document.createElement("a");
  a.href = objectUrl;
  a.download = filename;
  a.click();
  URL.revokeObjectURL(objectUrl);
}

/** YouTube 자막을 AI로 요약하는 SSE 스트림을 소비하는 AsyncGenerator. */
export async function* streamSummary(url: string): AsyncGenerator<string> {
  const res = await fetch(`${API_BASE_URL}/api/v1/youtube/summarize`, {
    method: "POST",
    headers: authHeaders(),
    body: JSON.stringify({ url }),
  });

  if (!res.ok) {
    const data = await res.json().catch(() => ({}));
    throw new Error(data.detail ?? "요약에 실패했습니다.");
  }

  const reader = res.body!.getReader();
  const decoder = new TextDecoder();
  let buffer = "";

  while (true) {
    const { done, value } = await reader.read();
    if (done) break;

    buffer += decoder.decode(value, { stream: true });
    const lines = buffer.split("\n");
    buffer = lines.pop() ?? "";

    for (const line of lines) {
      if (!line.startsWith("data: ")) continue;
      try {
        const payload = JSON.parse(line.slice(6));
        if (payload.error) throw new Error(payload.error);
        if (payload.done) return;
        if (payload.chunk) yield payload.chunk as string;
      } catch {
        // JSON 파싱 실패 → 무시
      }
    }
  }
}
