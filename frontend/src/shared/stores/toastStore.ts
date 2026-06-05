import { create } from "zustand";

export type ToastVariant = "error" | "success" | "info";

export interface Toast {
  id: number;
  message: string;
  variant: ToastVariant;
}

interface ToastState {
  toasts: Toast[];
  show: (message: string, variant?: ToastVariant) => void;
  dismiss: (id: number) => void;
}

let _seq = 0;

export const useToastStore = create<ToastState>((set) => ({
  toasts: [],
  show: (message, variant = "info") => {
    const id = ++_seq;
    set((s) => ({ toasts: [...s.toasts, { id, message, variant }] }));
    // 3.5초 후 자동 제거
    setTimeout(() => {
      set((s) => ({ toasts: s.toasts.filter((t) => t.id !== id) }));
    }, 3500);
  },
  dismiss: (id) => set((s) => ({ toasts: s.toasts.filter((t) => t.id !== id) })),
}));

/** 컴포넌트 밖(훅/유틸)에서도 호출 가능한 헬퍼 */
export function toast(message: string, variant: ToastVariant = "info") {
  useToastStore.getState().show(message, variant);
}
