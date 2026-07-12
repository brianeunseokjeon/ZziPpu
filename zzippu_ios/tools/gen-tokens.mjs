#!/usr/bin/env node
// AUTO-GENERATED GENERATOR — 손대지 말 것 (단, 이 스크립트 자체는 편집 가능)
// Usage: node tools/gen-tokens.mjs
// Input:  docs/design-system/tokens.json
// Output: zzippu/Shared/DesignSystem/Tokens/*.generated.swift
//         tools/out/tokens.generated.css

import { readFileSync, writeFileSync, mkdirSync } from 'fs';
import { resolve, dirname } from 'path';
import { fileURLToPath } from 'url';

const __dirname = dirname(fileURLToPath(import.meta.url));
const ROOT = resolve(__dirname, '..');

const tokensPath = resolve(ROOT, 'docs/design-system/tokens.json');
const iosOutDir  = resolve(ROOT, 'zzippu/Shared/DesignSystem/Tokens');
const cssOutPath = resolve(__dirname, 'out/tokens.generated.css');

const tokens = JSON.parse(readFileSync(tokensPath, 'utf8'));
mkdirSync(iosOutDir,              { recursive: true });
mkdirSync(dirname(cssOutPath),    { recursive: true });

// ─────────────────────────────────────────────
// 1. Primitive resolver
// ─────────────────────────────────────────────

/**
 * Resolves a "{primitive.color.blue.400}"-style reference to its raw value.
 * Works on the tokens.json object. Returns the raw value string/number/object.
 */
function resolve_ref(ref, root) {
  if (typeof ref !== 'string' || !ref.startsWith('{')) return ref;
  const path = ref.slice(1, -1).split('.');
  let cur = root;
  for (const seg of path) {
    if (cur == null) return ref;
    cur = cur[seg];
  }
  return (cur && typeof cur === 'object' && 'value' in cur) ? cur.value : cur;
}

/**
 * Fully resolves a value (may be a reference, or a light/dark object with references).
 */
function deep_resolve(val, root) {
  if (typeof val === 'string' && val.startsWith('{')) {
    return deep_resolve(resolve_ref(val, root), root);
  }
  if (val && typeof val === 'object' && ('light' in val || 'dark' in val)) {
    return {
      light: deep_resolve(val.light, root),
      dark:  deep_resolve(val.dark, root),
    };
  }
  return val;
}

// ─────────────────────────────────────────────
// 2. Colour helpers
// ─────────────────────────────────────────────

/** Parse hex colour string → { r, g, b } (0–255) */
function hex_to_rgb(hex) {
  const h = hex.replace('#', '');
  const n = parseInt(h, 16);
  if (h.length === 3) {
    return { r: ((n >> 8) & 0xf) * 17, g: ((n >> 4) & 0xf) * 17, b: (n & 0xf) * 17 };
  }
  return { r: (n >> 16) & 0xff, g: (n >> 8) & 0xff, b: n & 0xff };
}

/** Parse rgba(r,g,b,a) string → { r, g, b, a } */
function parse_rgba(s) {
  const m = s.match(/rgba?\(\s*([\d.]+)\s*,\s*([\d.]+)\s*,\s*([\d.]+)(?:\s*,\s*([\d.]+))?\s*\)/i);
  if (!m) return null;
  return { r: parseFloat(m[1]), g: parseFloat(m[2]), b: parseFloat(m[3]), a: m[4] != null ? parseFloat(m[4]) : 1 };
}

/**
 * Convert a resolved colour value to a Swift Color expression string.
 * Uses Color(hex: 0xRRGGBB) for opaque colours, Color(hex: 0xRRGGBB, opacity: a) for rgba.
 */
function swift_color(val) {
  if (!val || val === 'transparent') return '.clear';
  if (val === '#FFFFFF' || val === '#ffffff') return '.white';
  if (val === '#000000' || val === '#000000') return '.black';
  // rgba(...)
  const rgba = parse_rgba(val);
  if (rgba) {
    const hex = ((rgba.r & 0xff) << 16 | (rgba.g & 0xff) << 8 | (rgba.b & 0xff));
    const hexStr = hex.toString(16).padStart(6, '0').toUpperCase();
    if (Math.abs(rgba.a - 1) < 0.001) {
      return `Color(hex: 0x${hexStr})`;
    }
    return `Color(hex: 0x${hexStr}, opacity: ${rgba.a})`;
  }
  // hex
  if (val.startsWith('#')) {
    const { r, g, b } = hex_to_rgb(val);
    const hex = ((r & 0xff) << 16 | (g & 0xff) << 8 | (b & 0xff));
    const hexStr = hex.toString(16).padStart(6, '0').toUpperCase();
    return `Color(hex: 0x${hexStr})`;
  }
  return `.init()` // fallback
}

// ─────────────────────────────────────────────
// 3. Camel-case path helper
// ─────────────────────────────────────────────
function camel(parts) {
  return parts
    .map((p, i) => i === 0 ? p : p.charAt(0).toUpperCase() + p.slice(1))
    .join('');
}

// ─────────────────────────────────────────────
// 4. Walk primitive colours into flat map
// ─────────────────────────────────────────────
const primColors = {}; // e.g. { "blue400": "#60A5FA" }

function walk_prim_color(obj, parts) {
  if (!obj || typeof obj !== 'object') return;
  if ('value' in obj && typeof obj.value === 'string') {
    const key = camel(parts);
    primColors[key] = obj.value;
    return;
  }
  for (const [k, v] of Object.entries(obj)) {
    if (k.startsWith('$')) continue;
    walk_prim_color(v, [...parts, k]);
  }
}
walk_prim_color(tokens.primitive.color, []);

// ─────────────────────────────────────────────
// 5. Walk primitive scales (space/radius/size/font/shadow/motion/opacity)
// ─────────────────────────────────────────────
const primScales = {}; // e.g. { "space1": 4, "radiusMd": 12, ... }
const primShadows = {}; // shadow objects
const primMotion = {}; // motion values

function walk_prim_scale(obj, parts) {
  if (!obj || typeof obj !== 'object') return;
  if ('value' in obj) {
    const key = camel(parts);
    if (typeof obj.value === 'object' && ('x' in obj.value || 'response' in obj.value)) {
      primShadows[key] = obj.value;
    } else if (parts[0] === 'motion') {
      primMotion[key] = obj.value;
    } else {
      primScales[key] = obj.value;
    }
    return;
  }
  for (const [k, v] of Object.entries(obj)) {
    if (k.startsWith('$')) continue;
    walk_prim_scale(v, [...parts, k]);
  }
}
walk_prim_scale(tokens.primitive.space,   ['space']);
walk_prim_scale(tokens.primitive.radius,  ['radius']);
walk_prim_scale(tokens.primitive.size,    ['size']);
walk_prim_scale(tokens.primitive.font.weight, ['fontWeight']);
walk_prim_scale(tokens.primitive.font.scale,  ['fontScale']);
walk_prim_scale(tokens.primitive.opacity, ['opacity']);
walk_prim_scale(tokens.primitive.shadow,  ['shadow']);
walk_prim_scale(tokens.primitive.motion.duration, ['motionDuration']);
walk_prim_scale(tokens.primitive.motion,  ['motion']);

// ─────────────────────────────────────────────
// 6. Walk semantic colours into flat map
// ─────────────────────────────────────────────
const semColors = {}; // e.g. { "primary": { light: "#60A5FA", dark: "#3B82F6" } }

function walk_sem_color(obj, parts) {
  if (!obj || typeof obj !== 'object') return;
  if ('value' in obj) {
    const key = camel(parts);
    const resolved = deep_resolve(obj.value, tokens);
    semColors[key] = resolved;
    return;
  }
  for (const [k, v] of Object.entries(obj)) {
    if (k.startsWith('$')) continue;
    walk_sem_color(v, [...parts, k]);
  }
}
walk_sem_color(tokens.semantic.color, []);

// ─────────────────────────────────────────────
// 7. Walk semantic typography
// ─────────────────────────────────────────────
const semTypo = {};
for (const [name, entry] of Object.entries(tokens.semantic.typography)) {
  if (name.startsWith('$')) continue;
  // deep_resolve stops at plain objects (no light/dark); typography values are
  // {size, weight, lineHeight, ...} whose leaves are still "{primitive...}" refs.
  // Resolve each field individually so weight/size become concrete values.
  const raw = entry.value;
  const resolved = {};
  for (const [field, v] of Object.entries(raw)) {
    resolved[field] = deep_resolve(v, tokens);
  }
  semTypo[name] = resolved;
}

// ─────────────────────────────────────────────
// 8. iOS fixed-pt weight mapping
//    (웹 px 1:1 수렴 위해 TextStyle 매핑 폐기 → 고정 pt 방출.
//     Dynamic Type 접근성은 뷰단 상한(dsTypeCap)으로만 허용.)
// ─────────────────────────────────────────────
const TYPO_WEIGHT_MAP = {
  400: '.regular',
  500: '.medium',
  600: '.semibold',
  700: '.bold',
};

// ─────────────────────────────────────────────
// 9. Component token flat map (for reference)
// ─────────────────────────────────────────────
const compTokens = {};
function walk_comp(obj, parts) {
  if (!obj || typeof obj !== 'object') return;
  if ('value' in obj) {
    const key = camel(parts);
    compTokens[key] = deep_resolve(obj.value, tokens);
    return;
  }
  for (const [k, v] of Object.entries(obj)) {
    if (k.startsWith('$')) continue;
    walk_comp(v, [...parts, k]);
  }
}
walk_comp(tokens.component, []);

// ─────────────────────────────────────────────
// 10. GENERATE: PrimitiveColors.generated.swift
// ─────────────────────────────────────────────
const BANNER = `// AUTO-GENERATED — 손대지 말 것
// Source: docs/design-system/tokens.json
// Generator: tools/gen-tokens.mjs  (node tools/gen-tokens.mjs)
// ⚠️  이 파일을 직접 수정하면 토큰 재생성 시 덮어씁니다.`;

let primColorSwift = `${BANNER}

import SwiftUI

// MARK: - Primitive Colors (internal — feature code 직접 사용 금지)
// Semantic/Component 토큰을 통해서만 참조합니다.
enum PrimitiveColor {
`;
for (const [key, val] of Object.entries(primColors)) {
  const swiftVal = swift_color(val);
  primColorSwift += `    static let ${key}: Color = ${swiftVal}\n`;
}
primColorSwift += '}\n';

writeFileSync(resolve(iosOutDir, 'PrimitiveColors.generated.swift'), primColorSwift);
console.log('✓ PrimitiveColors.generated.swift');

// ─────────────────────────────────────────────
// 11. GENERATE: PrimitiveScale.generated.swift
// ─────────────────────────────────────────────
let scaleSwift = `${BANNER}

import CoreGraphics

// MARK: - Primitive Scale (internal — feature code 직접 사용 금지)

enum PrimitiveScale {
`;
for (const [key, val] of Object.entries(primScales)) {
  if (typeof val === 'number') {
    scaleSwift += `    static let ${key}: CGFloat = ${val}\n`;
  }
}
scaleSwift += '}\n\n';
scaleSwift += '// MARK: - Primitive Motion\nenum PrimitiveMotion {\n';
for (const [key, val] of Object.entries(primMotion)) {
  if (typeof val === 'number') {
    scaleSwift += `    /// ${val}ms\n    static let ${key}: Double = ${val / 1000.0}\n`;
  }
}
scaleSwift += '}\n';

writeFileSync(resolve(iosOutDir, 'PrimitiveScale.generated.swift'), scaleSwift);
console.log('✓ PrimitiveScale.generated.swift');

// ─────────────────────────────────────────────
// 12. GENERATE: SemanticColors.generated.swift
// ─────────────────────────────────────────────

// Collect DynamicColor entries
let dynColorPairs = []; // { name, light, dark }
for (const [key, val] of Object.entries(semColors)) {
  if (val && typeof val === 'object' && 'light' in val && 'dark' in val) {
    dynColorPairs.push({ name: key, light: val.light, dark: val.dark });
  } else if (typeof val === 'string') {
    // same for light and dark
    dynColorPairs.push({ name: key, light: val, dark: val });
  }
}

let semColorSwift = `${BANNER}

import SwiftUI

// MARK: - Semantic Colors
// DynamicColor wraps a light/dark pair → resolves via system color scheme.
// Feature code references these through Theme.color.*

struct SemanticColorTokens {
`;
for (const { name, light, dark } of dynColorPairs) {
  const l = swift_color(light);
  const d = swift_color(dark);
  semColorSwift += `    let ${name}: DynamicColor = DynamicColor(light: ${l}, dark: ${d})\n`;
}
semColorSwift += '}\n\n';
semColorSwift += `extension SemanticColorTokens {
    static let \`default\` = SemanticColorTokens()
}\n`;

writeFileSync(resolve(iosOutDir, 'SemanticColors.generated.swift'), semColorSwift);
console.log('✓ SemanticColors.generated.swift');

// ─────────────────────────────────────────────
// 13. GENERATE: Typography.generated.swift
// ─────────────────────────────────────────────
// input 자동줌 방지값(16 고정) — component.input.minFontSize 참조.
const inputMinFontSize = compTokens.inputMinFontSize ?? 16;

let typoSwift = `${BANNER}

import SwiftUI

// MARK: - Semantic Typography
// 고정 pt 방출(웹 px 1:1 수렴). Dynamic Type은 뷰단 상한만 허용(dsTypeCap / dsDynamicTypeCap).
// pt/weight 값은 전부 tokens.json(primitive.font.scale·semantic.typography)에서 옴.

struct SemanticTypography {
`;
for (const [name, val] of Object.entries(semTypo)) {
  const size = val.size != null ? val.size : 14;
  const weight = val.weight != null ? (TYPO_WEIGHT_MAP[val.weight] || '.regular') : '.regular';
  const isMono = name === 'mono' || (val.family && val.family.includes('monospace'));
  const isDisplayOrMono = name === 'display' || name === 'mono';

  // design: display uses .rounded (큰 숫자 통일), mono uses .monospaced.
  const design = name === 'display' ? '.rounded' : (isMono ? '.monospaced' : null);

  let fontExpr;
  if (design) {
    fontExpr = `.system(size: ${size}, weight: ${weight}, design: ${design})`;
  } else {
    fontExpr = `.system(size: ${size}, weight: ${weight})`;
  }
  // label: +0.3 tracking (자간) — 소형 라벨 가독·정돈.
  const tracking = name === 'label';

  let comment = `/// ${name}: ${size}pt, weight=${weight}`
    + `${design ? `, design=${design}` : ''}`
    + `${tracking ? ', tracking=+0.3' : ''}`
    + `${isDisplayOrMono ? ', dynamicTypeSize ≤ .xxLarge' : ''}`;
  typoSwift += `    ${comment}\n`;
  if (tracking) {
    // Font 자체엔 tracking API가 없어 별도 상수 + 헬퍼로 노출.
    typoSwift += `    let ${name}: Font = ${fontExpr}\n`;
    typoSwift += `    let ${name}Tracking: CGFloat = 0.3\n\n`;
  } else {
    typoSwift += `    let ${name}: Font = ${fontExpr}\n\n`;
  }
}
// 인풋 전용 폰트: 16pt 고정(iOS 자동줌 방지). callout이 14로 낮아져도 여기서 분리 유지.
typoSwift += `    /// input: ${inputMinFontSize}pt 고정 — iOS 자동줌 방지(callout 14와 분리)\n`;
typoSwift += `    let input: Font = .system(size: ${inputMinFontSize}, weight: .regular)\n\n`;
typoSwift += '}\n\n';
typoSwift += `extension SemanticTypography {
    static let \`default\` = SemanticTypography()
}

// MARK: - View modifiers for capping Dynamic Type
extension View {
    /// 전역 상한: 고정 pt 위에 접근성만 제한적으로 허용(신생아 아빠 배려 + 웹 레이아웃 유지).
    /// 앱 루트에 1회 적용 권장.
    @ViewBuilder
    func dsTypeCap() -> some View {
        if #available(iOS 15.0, *) {
            self.dynamicTypeSize(...DynamicTypeSize.xLarge)
        } else {
            self
        }
    }

    /// display/mono 등 큰 숫자·모노 스타일 국소 상한. 초대형에서 레이아웃 보호.
    @ViewBuilder
    func dsDynamicTypeCap() -> some View {
        if #available(iOS 15.0, *) {
            self.dynamicTypeSize(...DynamicTypeSize.xxLarge)
        } else {
            self
        }
    }
}\n`;

writeFileSync(resolve(iosOutDir, 'Typography.generated.swift'), typoSwift);
console.log('✓ Typography.generated.swift');

// ─────────────────────────────────────────────
// 14. GENERATE: Shadows.generated.swift
// ─────────────────────────────────────────────
let shadowSwift = `${BANNER}

import SwiftUI

// MARK: - Primitive Shadows

struct DSShadowStyle {
    let color: Color
    let radius: CGFloat
    let x: CGFloat
    let y: CGFloat
}

enum PrimitiveShadow {
`;
for (const [key, val] of Object.entries(primShadows)) {
  if (val && typeof val === 'object' && 'blur' in val) {
    const col = swift_color(val.color);
    const opacity = val.opacity ?? 0;
    const radius = (val.blur ?? 0) / 2;
    shadowSwift += `    static let ${key} = DSShadowStyle(color: ${col}.opacity(${opacity}), radius: ${radius}, x: ${val.x ?? 0}, y: ${val.y ?? 0})\n`;
  }
}
shadowSwift += '}\n';

writeFileSync(resolve(iosOutDir, 'Shadows.generated.swift'), shadowSwift);
console.log('✓ Shadows.generated.swift');

// ─────────────────────────────────────────────
// 15. GENERATE: Motion.generated.swift
// ─────────────────────────────────────────────
const springVal = tokens.primitive.motion.easing.spring?.value;
let motionSwift = `${BANNER}

import SwiftUI

// MARK: - Motion Tokens

enum DSMotion {
    /// 버튼/토스트 진입 — ${tokens.primitive.motion.duration.fast?.value}ms
    static let fast: Double = ${(tokens.primitive.motion.duration.fast?.value ?? 200) / 1000.0}
    /// 시트 전환 — ${tokens.primitive.motion.duration.normal?.value}ms
    static let normal: Double = ${(tokens.primitive.motion.duration.normal?.value ?? 300) / 1000.0}
    /// 느린 전환 — ${tokens.primitive.motion.duration.slow?.value}ms
    static let slow: Double = ${(tokens.primitive.motion.duration.slow?.value ?? 500) / 1000.0}
    /// 토스트 자동 소멸 — ${tokens.primitive.motion.toastAutoDismissMs?.value}ms
    static let toastAutoDismiss: Double = ${(tokens.primitive.motion.toastAutoDismissMs?.value ?? 3500) / 1000.0}
    /// SwiftUI spring: response=${springVal?.response}, damping=${springVal?.dampingFraction}
    static let spring: Animation = .spring(response: ${springVal?.response ?? 0.35}, dampingFraction: ${springVal?.dampingFraction ?? 0.85})
    static let springFast: Animation = .spring(response: ${(springVal?.response ?? 0.35) * 0.6}, dampingFraction: ${springVal?.dampingFraction ?? 0.85})
}
`;

writeFileSync(resolve(iosOutDir, 'Motion.generated.swift'), motionSwift);
console.log('✓ Motion.generated.swift');

// ─────────────────────────────────────────────
// 16. GENERATE: Web CSS (tools/out/tokens.generated.css)
// ─────────────────────────────────────────────
function css_var(parts) {
  return '--' + parts.join('-').replace(/([A-Z])/g, '-$1').toLowerCase();
}

let css = `/* AUTO-GENERATED — 손대지 말 것 */
/* Source: docs/design-system/tokens.json */
/* Generator: tools/gen-tokens.mjs */
/* Usage: @import this file in globals.css, then reference vars in Tailwind @theme */

:root {
`;

// primitive colors
for (const [key, val] of Object.entries(primColors)) {
  const segments = key.replace(/([A-Z0-9]+)/g, '-$1').toLowerCase().replace(/^-/, '').split('-');
  css += `  --primitive-color-${segments.join('-')}: ${val};\n`;
}

css += '\n  /* Semantic colors (light) */\n';
for (const { name, light } of dynColorPairs) {
  const cssName = name.replace(/([A-Z])/g, '-$1').toLowerCase();
  css += `  --color-${cssName}: ${typeof light === 'string' ? light : '#000'};\n`;
}

css += '\n  /* Primitive scales */\n';
const spaceMap = tokens.primitive.space;
for (const [k, v] of Object.entries(spaceMap)) {
  if (k.startsWith('$') || !v.value) continue;
  css += `  --space-${k}: ${v.value}px;\n`;
}

css += '}\n\n.dark {\n  /* Semantic colors (dark) */\n';
for (const { name, dark } of dynColorPairs) {
  const cssName = name.replace(/([A-Z])/g, '-$1').toLowerCase();
  css += `  --color-${cssName}: ${typeof dark === 'string' ? dark : '#fff'};\n`;
}
css += '}\n';

writeFileSync(cssOutPath, css);
console.log('✓ tools/out/tokens.generated.css');

console.log('\nAll tokens generated successfully.');
