/**
 * 빠른 기록용 디폴트 값 (persist).
 *
 * BigActionGrid / QuickRepeatRow 에서 "즉시 저장" 시 사용할 기본값.
 * 설정 페이지에서 변경 가능. 앱 재시작 후에도 유지.
 */
import { create } from "zustand";
import { persist } from "zustand/middleware";

export type BreastSide = "left" | "right" | "both";
export type DefaultPlayType = "tummy_time" | "free_play" | "sensory_play";

interface RecordingDefaultsState {
  formulaMl: number;
  breastSide: BreastSide;
  playType: DefaultPlayType;
  setFormulaMl: (ml: number) => void;
  setBreastSide: (side: BreastSide) => void;
  setPlayType: (type: DefaultPlayType) => void;
  reset: () => void;
}

const INITIAL: Pick<RecordingDefaultsState, "formulaMl" | "breastSide" | "playType"> = {
  formulaMl: 100,
  breastSide: "both",
  playType: "tummy_time",
};

export const useRecordingDefaultsStore = create<RecordingDefaultsState>()(
  persist(
    (set) => ({
      ...INITIAL,
      setFormulaMl: (ml) => set({ formulaMl: ml }),
      setBreastSide: (side) => set({ breastSide: side }),
      setPlayType: (type) => set({ playType: type }),
      reset: () => set(INITIAL),
    }),
    { name: "muknoljam-recording-defaults" }
  )
);
