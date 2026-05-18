/**
 * 사용자별 기록 모드 디폴트 (persist).
 *
 * 각 폼에서 "기본 모드로 설정" 버튼을 누르면 이 store에 저장.
 * 다음 방문 시 그 모드로 시작.
 */
import { create } from "zustand";
import { persist } from "zustand/middleware";

export type RecordingMode = "now" | "timer" | "manual";

export type RecordingActivity =
  | "feedingFormula"
  | "feedingBreast"
  | "diaper"
  | "sleep"
  | "play";

interface DefaultModes {
  feedingFormula: RecordingMode;
  feedingBreast: RecordingMode;
  diaper: RecordingMode;
  sleep: RecordingMode;
  play: RecordingMode;
}

const DEFAULTS: DefaultModes = {
  feedingFormula: "now",
  feedingBreast: "timer",
  diaper: "now",
  sleep: "timer",
  play: "timer",
};

interface PreferencesState {
  defaultModes: DefaultModes;
  setDefaultMode: (activity: RecordingActivity, mode: RecordingMode) => void;
  reset: () => void;
}

export const useRecordingPreferencesStore = create<PreferencesState>()(
  persist(
    (set) => ({
      defaultModes: DEFAULTS,
      setDefaultMode: (activity, mode) =>
        set((s) => ({
          defaultModes: { ...s.defaultModes, [activity]: mode },
        })),
      reset: () => set({ defaultModes: DEFAULTS }),
    }),
    { name: "muknoljam-recording-prefs" }
  )
);
