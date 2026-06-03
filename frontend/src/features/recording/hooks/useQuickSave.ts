/**
 * 디폴트 값으로 즉시 저장하는 훅.
 *
 * 저장 성공 시 undo 함수를 반환하여 QuickRepeatRow 에서
 * "[되돌리기]" 버튼에 연결할 수 있게 한다.
 */
import { useCreateFeeding, useDeleteFeeding } from "@/features/feeding/api/feedingApi";
import { useCreateDiaper, useDeleteDiaper } from "@/features/diaper/api/diaperApi";
import { FeedingType } from "@/features/feeding/types/feeding";
import { DiaperType } from "@/features/diaper/types/diaper";

export interface UndoHandle {
  undo: () => void;
}

export function useQuickSave() {
  const { mutateAsync: createFeeding, isPending: isSavingFeeding } =
    useCreateFeeding();
  const { mutateAsync: deleteFeeding } = useDeleteFeeding();
  const { mutateAsync: createDiaper, isPending: isSavingDiaper } =
    useCreateDiaper();
  const { mutateAsync: deleteDiaper } = useDeleteDiaper();

  async function saveFormula(
    babyId: string,
    ml: number,
    at?: string
  ): Promise<UndoHandle> {
    const saved = await createFeeding({
      babyId,
      feedingType: FeedingType.Formula,
      amountMl: ml,
      startedAt: at ?? new Date().toISOString(),
    });
    return {
      undo: () => deleteFeeding({ babyId, feedingId: saved.id }),
    };
  }

  async function saveBreast(
    babyId: string,
    side: "left" | "right" | "both",
    at?: string
  ): Promise<UndoHandle> {
    const typeMap: Record<string, FeedingType> = {
      left: FeedingType.BreastLeft,
      right: FeedingType.BreastRight,
      both: FeedingType.BreastBoth,
    };
    const saved = await createFeeding({
      babyId,
      feedingType: typeMap[side],
      startedAt: at ?? new Date().toISOString(),
    });
    return {
      undo: () => deleteFeeding({ babyId, feedingId: saved.id }),
    };
  }

  async function savePee(babyId: string, at?: string): Promise<UndoHandle> {
    const saved = await createDiaper({
      babyId,
      diaperType: DiaperType.Pee,
      recordedAt: at ?? new Date().toISOString(),
    });
    return {
      undo: () => deleteDiaper({ babyId, diaperId: saved.id }),
    };
  }

  async function savePoo(babyId: string, at?: string): Promise<UndoHandle> {
    const saved = await createDiaper({
      babyId,
      diaperType: DiaperType.Poop,
      recordedAt: at ?? new Date().toISOString(),
    });
    return {
      undo: () => deleteDiaper({ babyId, diaperId: saved.id }),
    };
  }

  async function saveBoth(babyId: string, at?: string): Promise<UndoHandle> {
    const saved = await createDiaper({
      babyId,
      diaperType: DiaperType.Both,
      recordedAt: at ?? new Date().toISOString(),
    });
    return {
      undo: () => deleteDiaper({ babyId, diaperId: saved.id }),
    };
  }

  return {
    saveFormula,
    saveBreast,
    savePee,
    savePoo,
    saveBoth,
    isSaving: isSavingFeeding || isSavingDiaper,
  };
}
