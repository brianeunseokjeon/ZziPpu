import { create } from "zustand";
import { MOCK_BABY_ID } from "@/config/constants";
import { getDateString } from "@/lib/date-utils";

interface UIState {
  selectedDate: string;
  activeBabyId: string;
  setSelectedDate: (date: string) => void;
  setActiveBabyId: (id: string) => void;
}

export const useUIStore = create<UIState>((set) => ({
  selectedDate: getDateString(new Date()),
  activeBabyId: MOCK_BABY_ID,
  setSelectedDate: (selectedDate) => set({ selectedDate }),
  setActiveBabyId: (activeBabyId) => set({ activeBabyId }),
}));
