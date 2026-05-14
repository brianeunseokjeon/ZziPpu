import { create } from "zustand";
import { FeedingType } from "../types/feeding";

interface FeedingFormState {
  feedingType: FeedingType;
  amountMl: number;
  breastSide: "left" | "right" | "both";
  startedAt: Date;
  memo: string;
  setFeedingType: (t: FeedingType) => void;
  setAmountMl: (v: number) => void;
  setBreastSide: (s: "left" | "right" | "both") => void;
  setStartedAt: (d: Date) => void;
  setMemo: (m: string) => void;
  reset: () => void;
}

const defaultState = {
  feedingType: FeedingType.Formula,
  amountMl: 100,
  breastSide: "both" as const,
  startedAt: new Date(),
  memo: "",
};

export const useFeedingStore = create<FeedingFormState>((set) => ({
  ...defaultState,
  setFeedingType: (feedingType) => set({ feedingType }),
  setAmountMl: (amountMl) => set({ amountMl }),
  setBreastSide: (breastSide) => set({ breastSide }),
  setStartedAt: (startedAt) => set({ startedAt }),
  setMemo: (memo) => set({ memo }),
  reset: () => set({ ...defaultState, startedAt: new Date() }),
}));
