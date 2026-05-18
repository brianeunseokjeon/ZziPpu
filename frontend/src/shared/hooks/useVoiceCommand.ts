"use client";

import { useEffect, useRef, useState } from "react";
import type { ActivityType } from "@/shared/stores/activityTimerStore";

export type VoiceCommandAction = "start" | "finish" | "pause" | "resume" | "cancel";

export interface VoiceCommand {
  action: VoiceCommandAction;
  activity?: ActivityType;
  meta?: { playType?: string; feedingType?: string };
  matchedText: string;
}

/** Web Speech API 타입 (브라우저 제공) */
interface SpeechRecognitionEvent extends Event {
  results: ArrayLike<{ 0: { transcript: string } }>;
}
interface SpeechRecognitionLike {
  lang: string;
  continuous: boolean;
  interimResults: boolean;
  start: () => void;
  stop: () => void;
  abort: () => void;
  onresult: ((e: SpeechRecognitionEvent) => void) | null;
  onerror: ((e: Event) => void) | null;
  onend: (() => void) | null;
}

function getRecognitionCtor(): (new () => SpeechRecognitionLike) | null {
  if (typeof window === "undefined") return null;
  const w = window as unknown as {
    SpeechRecognition?: new () => SpeechRecognitionLike;
    webkitSpeechRecognition?: new () => SpeechRecognitionLike;
  };
  return w.SpeechRecognition ?? w.webkitSpeechRecognition ?? null;
}

/** 한국어 명령어 매칭. 가장 첫 번째로 매칭되는 패턴 반환. */
export function parseVoiceCommand(text: string): VoiceCommand | null {
  const t = text.replace(/\s+/g, "").toLowerCase();

  // 시작 명령
  if (/(수면|잠|자기).*(시작|할래|시작해|시작할래)/.test(t) || t.includes("자기시작") || t.includes("수면시작")) {
    return { action: "start", activity: "sleep", matchedText: text };
  }
  if (/(터미타임|놀이|놀자).*(시작|시작해|할래)/.test(t) || t.includes("터미타임시작") || t.includes("놀이시작")) {
    return {
      action: "start",
      activity: "play",
      meta: { playType: t.includes("터미타임") ? "tummy_time" : "free_play" },
      matchedText: text,
    };
  }
  if (/(수유|모유|먹이기).*(시작|시작해|할래)/.test(t) || t.includes("수유시작") || t.includes("모유시작")) {
    return {
      action: "start",
      activity: "feeding",
      meta: { feedingType: "breast_both" },
      matchedText: text,
    };
  }

  // 종료 명령
  if (/(수면|잠|자기).*(종료|끝|끝났|완료)/.test(t) || t.includes("수면종료") || t.includes("잠끝")) {
    return { action: "finish", activity: "sleep", matchedText: text };
  }
  if (/(터미타임|놀이).*(종료|끝|끝났|완료)/.test(t) || t.includes("터미타임종료") || t.includes("놀이끝")) {
    return { action: "finish", activity: "play", matchedText: text };
  }
  if (/(수유|모유).*(종료|끝|완료)/.test(t) || t.includes("수유종료") || t.includes("모유끝")) {
    return { action: "finish", activity: "feeding", matchedText: text };
  }

  // 일시정지 / 재개 / 취소 (활동 미지정)
  if (/일시정지|잠시멈춤|잠깐멈춤|멈춰/.test(t)) {
    return { action: "pause", matchedText: text };
  }
  if (/재개|다시시작|이어서|계속/.test(t)) {
    return { action: "resume", matchedText: text };
  }
  if (/취소|그만|취소해/.test(t)) {
    return { action: "cancel", matchedText: text };
  }

  return null;
}

interface UseVoiceCommandOpts {
  onCommand?: (cmd: VoiceCommand) => void;
  onError?: (msg: string) => void;
  onUnrecognized?: (text: string) => void;
}

/**
 * Web Speech API 한국어 1회 인식.
 * 브라우저 미지원이면 isSupported=false → 호출처에서 마이크 버튼 숨김.
 */
export function useVoiceCommand({ onCommand, onError, onUnrecognized }: UseVoiceCommandOpts = {}) {
  const [isListening, setIsListening] = useState(false);
  const [isSupported, setIsSupported] = useState(false);
  const recogRef = useRef<SpeechRecognitionLike | null>(null);

  useEffect(() => {
    const Ctor = getRecognitionCtor();
    setIsSupported(!!Ctor);
  }, []);

  function start() {
    const Ctor = getRecognitionCtor();
    if (!Ctor) {
      onError?.("이 브라우저에서는 음성 인식이 지원되지 않습니다.");
      return;
    }

    // 기존 인스턴스가 있으면 중단
    if (recogRef.current) {
      try { recogRef.current.abort(); } catch { /* ignore */ }
    }

    const r = new Ctor();
    r.lang = "ko-KR";
    r.continuous = false;
    r.interimResults = false;

    r.onresult = (e: SpeechRecognitionEvent) => {
      const text = e.results[0]?.[0]?.transcript ?? "";
      if (!text) {
        onUnrecognized?.("");
        return;
      }
      const cmd = parseVoiceCommand(text);
      if (cmd) onCommand?.(cmd);
      else onUnrecognized?.(text);
    };
    r.onerror = () => {
      onError?.("음성 인식 오류가 발생했습니다.");
    };
    r.onend = () => setIsListening(false);

    recogRef.current = r;
    try {
      r.start();
      setIsListening(true);
    } catch {
      onError?.("음성 인식을 시작할 수 없습니다.");
    }
  }

  function stop() {
    try { recogRef.current?.stop(); } catch { /* ignore */ }
    setIsListening(false);
  }

  return { start, stop, isListening, isSupported };
}
