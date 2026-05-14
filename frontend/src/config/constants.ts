export const API_BASE_URL =
  process.env.NEXT_PUBLIC_API_URL ?? "http://localhost:8000";

export const TAB_ITEMS = [
  { icon: "Home", label: "홈", path: "/" },
  { icon: "ClipboardList", label: "기록", path: "/record" },
  { icon: "BarChart3", label: "대시보드", path: "/dashboard" },
  { icon: "Bot", label: "AI", path: "/ai/review" },
  { icon: "Settings", label: "설정", path: "/settings" },
] as const;

export const FEEDING_TYPES = [
  { value: "formula", label: "분유" },
  { value: "breast_left", label: "모유(좌)" },
  { value: "breast_right", label: "모유(우)" },
  { value: "breast_both", label: "모유(양쪽)" },
] as const;

export const DIAPER_TYPES = [
  { value: "pee", label: "소변" },
  { value: "poop", label: "대변" },
  { value: "both", label: "둘 다" },
] as const;

export const STOOL_COLORS = [
  { value: "yellow", label: "노란색", hex: "#FCD34D" },
  { value: "green", label: "녹색", hex: "#4ADE80" },
  { value: "brown", label: "갈색", hex: "#A16207" },
  { value: "black", label: "검은색", hex: "#1F2937" },
  { value: "red", label: "붉은색", hex: "#EF4444" },
  { value: "white", label: "흰색", hex: "#F3F4F6" },
] as const;

export const STOOL_STATES = [
  { value: "liquid", label: "액체" },
  { value: "soft", label: "무름" },
  { value: "normal", label: "보통" },
  { value: "hard", label: "딱딱" },
] as const;

export const PLAY_TYPES = [
  { value: "tummy_time", label: "터미타임", emoji: "🤸" },
  { value: "free_play", label: "자유놀이", emoji: "🎈" },
  { value: "sensory_play", label: "감각놀이", emoji: "🎵" },
] as const;

export const MOCK_BABY_ID = "baby-001";
export const MOCK_BIRTH_DATE = "2025-04-13";
