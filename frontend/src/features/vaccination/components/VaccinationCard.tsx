"use client";

import { useState } from "react";
import { Badge } from "@/shared/components/ui/badge";
import { Button } from "@/shared/components/ui/button";
import { Input } from "@/shared/components/ui/input";
import { Dialog } from "@/shared/components/ui/dialog";
import { useMarkAdministered } from "../api/vaccinationApi";
import { MOCK_BABY_ID } from "@/config/constants";
import { formatDate } from "@/lib/date-utils";
import type { Vaccination } from "../types/vaccination";

interface VaccinationCardProps {
  vaccination: Vaccination;
  onMark?: () => void;
}

function StatusBadge({ v }: { v: Vaccination }) {
  if (v.administeredDate) {
    return (
      <span className="inline-flex items-center gap-1 px-2 py-0.5 rounded-full text-xs font-medium bg-green-100 text-green-700">
        ✓ 완료
      </span>
    );
  }
  if (v.isOverdue) {
    return (
      <span className="inline-flex items-center gap-1 px-2 py-0.5 rounded-full text-xs font-medium bg-red-100 text-red-700">
        ! 지남
      </span>
    );
  }
  return (
    <span className="inline-flex items-center gap-1 px-2 py-0.5 rounded-full text-xs font-medium bg-blue-100 text-blue-700">
      예정
    </span>
  );
}

export function VaccinationCard({ vaccination: v, onMark }: VaccinationCardProps) {
  const [modalOpen, setModalOpen] = useState(false);
  const [adminDate, setAdminDate] = useState(() =>
    new Date().toISOString().slice(0, 10)
  );
  const [hospitalName, setHospitalName] = useState("");
  const { mutate: markAdministered, isPending } = useMarkAdministered();

  function handleConfirm() {
    markAdministered(
      {
        babyId: MOCK_BABY_ID,
        vaccinationId: v.id,
        data: {
          administeredDate: adminDate,
          hospitalName: hospitalName || undefined,
        },
      },
      {
        onSuccess: () => {
          setModalOpen(false);
          onMark?.();
        },
      }
    );
  }

  const borderColor = v.administeredDate
    ? "border-green-100"
    : v.isOverdue
    ? "border-red-100"
    : "border-blue-100";

  return (
    <>
      <div
        className={`flex items-center justify-between bg-white rounded-2xl px-4 py-3 border ${borderColor}`}
      >
        <div className="flex items-center gap-3">
          <div
            className={`w-10 h-10 rounded-full flex items-center justify-center text-xl ${
              v.administeredDate
                ? "bg-green-50"
                : v.isOverdue
                ? "bg-red-50"
                : "bg-blue-50"
            }`}
          >
            💉
          </div>
          <div>
            <div className="flex items-center gap-2 flex-wrap">
              <p className="text-sm font-semibold text-gray-800">
                {v.vaccineName}
              </p>
              <span className="text-xs text-gray-400">{v.doseNumber}차</span>
              <StatusBadge v={v} />
            </div>
            <p className="text-xs text-gray-400 mt-0.5">
              예정일: {formatDate(v.scheduledDate)}
            </p>
            {v.administeredDate && (
              <p className="text-xs text-green-600 mt-0.5">
                접종: {formatDate(v.administeredDate)}
                {v.hospitalName && ` · ${v.hospitalName}`}
              </p>
            )}
            {!v.administeredDate && v.daysUntil !== null && (
              <p className="text-xs text-gray-400 mt-0.5">
                {v.daysUntil > 0
                  ? `D-${v.daysUntil}`
                  : v.daysUntil === 0
                  ? "오늘"
                  : `D+${Math.abs(v.daysUntil)}`}
              </p>
            )}
          </div>
        </div>
        {!v.administeredDate && (
          <Button
            size="sm"
            onClick={() => setModalOpen(true)}
            className="text-xs px-3 py-1.5 bg-teal-500 hover:bg-teal-600 shrink-0"
          >
            접종 완료
          </Button>
        )}
      </div>

      <Dialog
        open={modalOpen}
        onClose={() => setModalOpen(false)}
        title={`${v.vaccineName} ${v.doseNumber}차 접종 완료`}
      >
        <div className="space-y-4">
          <div>
            <p className="text-sm font-medium text-gray-700 mb-1.5">
              접종일
            </p>
            <Input
              type="date"
              value={adminDate}
              onChange={(e) => setAdminDate(e.target.value)}
            />
          </div>
          <div>
            <p className="text-sm font-medium text-gray-700 mb-1.5">
              병원명 (선택)
            </p>
            <Input
              placeholder="병원명을 입력하세요"
              value={hospitalName}
              onChange={(e) => setHospitalName(e.target.value)}
            />
          </div>
          <Button
            onClick={handleConfirm}
            disabled={isPending}
            className="w-full bg-teal-500 hover:bg-teal-600"
          >
            {isPending ? "저장 중..." : "확인"}
          </Button>
        </div>
      </Dialog>
    </>
  );
}
