import React from 'react';
import {useCurrentFrame} from 'remotion';
import {C, FONT} from '../theme';
import {SPR, clamp, sp} from '../anim';
import {interpolate} from 'remotion';

// A word that slams in: scale from big + blur -> sharp, with overshoot
export const SlamWord: React.FC<{
  text: string;
  at: number;
  size: number;
  color?: string;
  from?: number; // start scale
  weight?: number;
  rotate?: number;
  style?: React.CSSProperties;
  out?: number; // frame to leave
  highlight?: string; // marker color behind the word
  highlightAt?: number;
}> = ({text, at, size, color = C.text, from = 2.4, weight = 900, rotate = 0, style, out, highlight, highlightAt}) => {
  const f = useCurrentFrame();
  if (f < at - 1) return null;
  const s = sp(f, at, SPR.punch);
  const scale = s < 1 ? from + (1 - from) * s : 1 - Math.min(0.1, (s - 1) * 0.35);
  const blur = interpolate(f - at, [0, 6], [14, 0], clamp);
  const op = interpolate(f - at, [0, 3], [0, 1], clamp);
  let outT = 0;
  if (out !== undefined) outT = interpolate(f, [out, out + 8], [0, 1], clamp);
  const hl = highlight ? sp(f, highlightAt ?? at + 6, SPR.card) : 0;
  return (
    <div
      style={{
        position: 'relative',
        display: 'inline-block',
        fontFamily: FONT,
        fontWeight: weight,
        fontSize: size,
        lineHeight: 0.98,
        letterSpacing: -size * 0.035,
        color,
        transform: `scale(${scale * (1 - outT * 0.3)}) rotate(${rotate * (1 - s)}deg) translateY(${-outT * 60}px)`,
        filter: `blur(${blur + outT * 12}px)`,
        opacity: op * (1 - outT),
        whiteSpace: 'nowrap',
        ...style,
      }}
    >
      {highlight ? (
        <div
          style={{
            position: 'absolute',
            left: -size * 0.08,
            right: -size * 0.08,
            top: '18%',
            bottom: '6%',
            background: highlight,
            borderRadius: size * 0.12,
            transformOrigin: 'left center',
            transform: `scaleX(${hl})`,
            zIndex: -1,
          }}
        />
      ) : null}
      {text}
    </div>
  );
};

// Words rise in one by one with blur (TextReveal v2)
export const RiseLine: React.FC<{
  words: {t: string; color?: string; at: number}[];
  size: number;
  weight?: number;
  color?: string;
  align?: 'center' | 'left';
  out?: number;
  style?: React.CSSProperties;
}> = ({words, size, weight = 900, color = C.text, align = 'center', out, style}) => {
  const f = useCurrentFrame();
  const outT = out !== undefined ? interpolate(f, [out, out + 10], [0, 1], clamp) : 0;
  return (
    <div
      style={{
        fontFamily: FONT,
        fontWeight: weight,
        fontSize: size,
        lineHeight: 1.02,
        letterSpacing: -size * 0.03,
        color,
        textAlign: align,
        display: 'flex',
        flexWrap: 'wrap',
        justifyContent: align === 'center' ? 'center' : 'flex-start',
        columnGap: size * 0.26,
        opacity: 1 - outT,
        filter: `blur(${outT * 10}px)`,
        transform: `translateY(${-outT * 40}px)`,
        ...style,
      }}
    >
      {words.map((w, i) => {
        const s = sp(f, w.at, SPR.card);
        const blur = interpolate(f - w.at, [0, 9], [10, 0], clamp);
        return (
          <span
            key={i}
            style={{
              display: 'inline-block',
              color: w.color ?? color,
              opacity: f < w.at ? 0 : interpolate(f - w.at, [0, 5], [0, 1], clamp),
              transform: `translateY(${(1 - s) * size * 0.45}px)`,
              filter: `blur(${blur}px)`,
              whiteSpace: 'nowrap',
            }}
          >
            {w.t}
          </span>
        );
      })}
    </div>
  );
};

// small editorial label — "01 / ХАОС"
export const Tag: React.FC<{n: string; label: string; color?: string; at: number; style?: React.CSSProperties}> = ({
  n,
  label,
  color = C.muted,
  at,
  style,
}) => {
  const f = useCurrentFrame();
  const s = sp(f, at, SPR.card);
  const lineW = interpolate(s, [0, 1], [0, 90]);
  return (
    <div
      style={{
        fontFamily: FONT,
        fontWeight: 800,
        fontSize: 30,
        letterSpacing: 4,
        color,
        display: 'flex',
        alignItems: 'center',
        gap: 18,
        opacity: s,
        ...style,
      }}
    >
      <span>{n}</span>
      <span style={{width: lineW, height: 3, background: color, display: 'inline-block'}} />
      <span>{label}</span>
    </div>
  );
};
