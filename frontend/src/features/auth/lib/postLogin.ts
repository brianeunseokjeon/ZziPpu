import { apiClient } from "@/lib/api-client";
import { useBabyStore } from "@/features/baby/store/babyStore";

interface BabySummary {
  id: string;
  name: string;
  birthDate: string;
  gender?: "male" | "female";
  photoUrl?: string | null;
}

/**
 * 약관 통과 후 진입점 결정 (MSA 경계: baby 는 core 소유).
 * core GET /babies → 아기 있으면 babyStore 채우고 "/" , 없으면 "/onboarding".
 * 반환: 이동할 경로.
 */
export async function resolveLandingAfterTerms(): Promise<string> {
  const babies = await apiClient.get<BabySummary[]>("/api/v1/babies");
  if (babies.length > 0) {
    const b = babies[0];
    useBabyStore.getState().update({ name: b.name, birthDate: b.birthDate });
    useBabyStore.getState().setBabyId(b.id);
    if (b.gender) useBabyStore.getState().setGender(b.gender);
    if (b.photoUrl !== undefined) useBabyStore.getState().setPhotoUrl(b.photoUrl ?? null);
    return "/";
  }
  return "/onboarding";
}
