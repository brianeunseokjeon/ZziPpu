import { create } from "zustand";
import { persist } from "zustand/middleware";

interface AuthState {
  accessToken: string | null;
  userId: string | null;
  babyId: string | null;
  isNewUser: boolean;
  setSession: (s: { accessToken: string; userId: string; babyId: string; isNewUser: boolean }) => void;
  clear: () => void;
}

export const useAuthStore = create<AuthState>()(
  persist(
    (set) => ({
      accessToken: null,
      userId: null,
      babyId: null,
      isNewUser: false,
      setSession: ({ accessToken, userId, babyId, isNewUser }) =>
        set({ accessToken, userId, babyId, isNewUser }),
      clear: () => set({ accessToken: null, userId: null, babyId: null, isNewUser: false }),
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
