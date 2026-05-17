import { useBabyStore } from "../store/babyStore";
import { getAgeDays } from "@/lib/date-utils";

export function useBabyInfo() {
  const { babyId, name, birthDate, photoUrl, setBirthDate, setName, setPhotoUrl, update } = useBabyStore();

  const ageDays = getAgeDays(birthDate);
  const ageMonths = Math.floor((ageDays - 1) / 30);
  const ageText = `생후 ${ageDays}일`;

  return { babyId, name, birthDate, photoUrl, ageDays, ageMonths, ageText, setBirthDate, setName, setPhotoUrl, update };
}
