"use client";

import { useState, useEffect } from "react";
import type { BabyGender } from "@/features/baby/store/babyStore";

interface BabyAvatarProps {
  photoUrl?: string | null;
  gender?: BabyGender;
  /** 정사각형 크기 Tailwind 클래스 (예: "w-20 h-20") */
  sizeClass?: string;
}

/**
 * 아기 아바타.
 * - photoUrl 이 유효하면 사진 표시.
 * - 사진이 없거나 로드 실패(깨진 base64 등)면 성별별 귀여운 기본 일러스트로 대체.
 * onError 로 깨진 이미지를 자동 방어하므로 어떤 손상된 photoUrl 도 안전하다.
 */
export function BabyAvatar({ photoUrl, gender = "male", sizeClass = "w-20 h-20" }: BabyAvatarProps) {
  const [broken, setBroken] = useState(false);

  // photoUrl 이 바뀌면 broken 상태 초기화
  useEffect(() => setBroken(false), [photoUrl]);

  const showPhoto = !!photoUrl && !broken;

  if (showPhoto) {
    return (
      <div className={`${sizeClass} rounded-full overflow-hidden bg-gray-100`}>
        {/* eslint-disable-next-line @next/next/no-img-element */}
        <img
          src={photoUrl!}
          alt="아기 사진"
          className="w-full h-full object-cover"
          onError={() => setBroken(true)}
        />
      </div>
    );
  }

  return <BabyFallbackIllustration gender={gender} sizeClass={sizeClass} />;
}

/** 성별별 파스텔 아기 일러스트 (인라인 SVG — 네트워크/깨짐 없음). */
function BabyFallbackIllustration({
  gender,
  sizeClass,
}: {
  gender: BabyGender;
  sizeClass: string;
}) {
  const isMale = gender === "male";
  const bgFrom = isMale ? "#bae6fd" : "#fbcfe8"; // sky-200 / pink-200
  const bgTo = isMale ? "#60a5fa" : "#f472b6"; // blue-400 / pink-400
  const gid = `babybg-${gender}`;

  // OS 기본 아기 이모지 + 성별 그라데이션 배경.
  // SVG <text> 라 컨테이너 크기에 자동 스케일되고, 어떤 환경에서도 깨지지 않는다.
  return (
    <div className={`${sizeClass} rounded-full overflow-hidden`}>
      <svg viewBox="0 0 100 100" className="w-full h-full" role="img" aria-label="아기 기본 이미지">
        <defs>
          <radialGradient id={gid} cx="50%" cy="38%" r="75%">
            <stop offset="0%" stopColor={bgFrom} />
            <stop offset="100%" stopColor={bgTo} />
          </radialGradient>
        </defs>
        <rect width="100" height="100" fill={`url(#${gid})`} />
        <text
          x="50"
          y="54"
          fontSize="52"
          textAnchor="middle"
          dominantBaseline="central"
        >
          👶
        </text>
      </svg>
    </div>
  );
}
