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
  const bgTo = isMale ? "#7dd3fc" : "#f9a8d4"; // sky-300 / pink-300
  const accent = isMale ? "#38bdf8" : "#f472b6"; // 모자/리본 색
  const gid = `babybg-${gender}`;

  return (
    <div className={`${sizeClass} rounded-full overflow-hidden`}>
      <svg viewBox="0 0 100 100" className="w-full h-full" role="img" aria-label="아기 기본 이미지">
        <defs>
          <radialGradient id={gid} cx="50%" cy="40%" r="70%">
            <stop offset="0%" stopColor={bgFrom} />
            <stop offset="100%" stopColor={bgTo} />
          </radialGradient>
        </defs>
        <rect width="100" height="100" fill={`url(#${gid})`} />
        {/* 얼굴 */}
        <circle cx="50" cy="55" r="26" fill="#ffe0c2" />
        {/* 볼터치 */}
        <circle cx="38" cy="60" r="4.5" fill="#ffb3a7" opacity="0.7" />
        <circle cx="62" cy="60" r="4.5" fill="#ffb3a7" opacity="0.7" />
        {/* 눈 */}
        <circle cx="42" cy="52" r="2.8" fill="#5b4636" />
        <circle cx="58" cy="52" r="2.8" fill="#5b4636" />
        {/* 미소 */}
        <path d="M43 63 Q50 69 57 63" stroke="#5b4636" strokeWidth="2.2" fill="none" strokeLinecap="round" />
        {/* 머리 위 장식: 남아=곱슬, 여아=리본 */}
        {isMale ? (
          <path
            d="M50 29 q-6 -8 2 -12 q-2 7 6 6"
            stroke={accent}
            strokeWidth="3"
            fill="none"
            strokeLinecap="round"
          />
        ) : (
          <g>
            <path d="M50 30 l-9 -6 l0 12 z" fill={accent} />
            <path d="M50 30 l9 -6 l0 12 z" fill={accent} />
            <circle cx="50" cy="30" r="3.2" fill={accent} />
          </g>
        )}
      </svg>
    </div>
  );
}
