import { create } from "zustand";
import { persist } from "zustand/middleware";

interface AuthState {
  accessToken: string | null;
  userId: string | null;
  isNewUser: boolean;
  termsRequired: boolean;
  setSession: (s: {
    accessToken: string;
    userId: string;
    isNewUser: boolean;
    termsRequired: boolean;
  }) => void;
  setTermsRequired: (v: boolean) => void;
  clear: () => void;
}

// babyId 는 더 이상 인증 응답에 없음 → core GET /babies 결과를 babyStore 에 저장.
// (MSA 경계: auth 는 user 신원만, baby 도메인은 core 소유)
export const useAuthStore = create<AuthState>()(
  persist(
    (set) => ({
      accessToken: null,
      userId: null,
      isNewUser: false,
      termsRequired: false,
      setSession: ({ accessToken, userId, isNewUser, termsRequired }) =>
        set({ accessToken, userId, isNewUser, termsRequired }),
      setTermsRequired: (termsRequired) => set({ termsRequired }),
      clear: () =>
        set({ accessToken: null, userId: null, isNewUser: false, termsRequired: false }),
    }),
    { name: "muknoljam-auth" }
  )
);

/**
 * SSR-safe하게 token만 읽는 헬퍼 (api-client에서 사용).
 * Zustand는 클라이언트 전용이라 SSR에서 호출되면 null 반환.
 */
export function getAccessToken(): string | null {
  if (typeof window === "undefined") return null;
  try {
    return useAuthStore.getState().accessToken;
  } catch {
    return null;
  }
}
