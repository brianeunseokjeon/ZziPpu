import { create } from "zustand";
import { persist } from "zustand/middleware";
import { MOCK_BABY_ID, MOCK_BIRTH_DATE } from "@/config/constants";

interface BabyState {
  babyId: string;
  name: string;
  birthDate: string;
  photoUrl: string | null;
  setBabyId: (id: string) => void;
  setName: (name: string) => void;
  setBirthDate: (date: string) => void;
  setPhotoUrl: (url: string | null) => void;
  update: (partial: Partial<Pick<BabyState, "name" | "birthDate" | "photoUrl">>) => void;
}

export const useBabyStore = create<BabyState>()(
  persist(
    (set) => ({
      babyId: MOCK_BABY_ID,
      name: "우리 아기",
      birthDate: MOCK_BIRTH_DATE,
      photoUrl: null,
      setBabyId: (babyId) => set({ babyId }),
      setName: (name) => set({ name }),
      setBirthDate: (birthDate) => set({ birthDate }),
      setPhotoUrl: (photoUrl) => set({ photoUrl }),
      update: (partial) => set(partial),
    }),
    { name: "muknoljam-baby" }
  )
);
