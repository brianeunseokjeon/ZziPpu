import { create } from "zustand";
import { MOCK_BABY_ID } from "@/config/constants";
import { getDateString } from "@/lib/date-utils";

interface UIState {
  selectedDate: string;
  activeBabyId: string;
  isQuickActionOpen: boolean;
  setSelectedDate: (date: string) => void;
  setActiveBabyId: (id: string) => void;
  setIsQuickActionOpen: (open: boolean) => void;
  toggleQuickAction: () => void;
}

export const useUIStore = create<UIState>((set) => ({
  selectedDate: getDateString(new Date()),
  activeBabyId: MOCK_BABY_ID,
  isQuickActionOpen: false,
  setSelectedDate: (selectedDate) => set({ selectedDate }),
  setActiveBabyId: (activeBabyId) => set({ activeBabyId }),
  setIsQuickActionOpen: (isQuickActionOpen) => set({ isQuickActionOpen }),
  toggleQuickAction: () =>
    set((s) => ({ isQuickActionOpen: !s.isQuickActionOpen })),
}));
