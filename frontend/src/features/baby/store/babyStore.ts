import { create } from "zustand";
import { persist } from "zustand/middleware";
import { MOCK_BABY_ID, MOCK_BIRTH_DATE } from "@/config/constants";

export type BabyGender = "male" | "female";

interface BabyState {
  babyId: string;
  name: string;
  birthDate: string;
  gender: BabyGender;
  photoUrl: string | null;
  setBabyId: (id: string) => void;
  setName: (name: string) => void;
  setBirthDate: (date: string) => void;
  setGender: (gender: BabyGender) => void;
  setPhotoUrl: (url: string | null) => void;
  update: (
    partial: Partial<Pick<BabyState, "name" | "birthDate" | "gender" | "photoUrl">>
  ) => void;
}

export const useBabyStore = create<BabyState>()(
  persist(
    (set) => ({
      babyId: MOCK_BABY_ID,
      name: "우리 아기",
      birthDate: MOCK_BIRTH_DATE,
      gender: "male",
      photoUrl: null,
      setBabyId: (babyId) => set({ babyId }),
      setName: (name) => set({ name }),
      setBirthDate: (birthDate) => set({ birthDate }),
      setGender: (gender) => set({ gender }),
      setPhotoUrl: (photoUrl) => set({ photoUrl }),
      update: (partial) => set(partial),
    }),
    { name: "muknoljam-baby" }
  )
);
