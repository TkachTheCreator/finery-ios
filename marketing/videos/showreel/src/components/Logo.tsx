import React from 'react';
import {C} from '../theme';
import {CREAM_PETAL, GOLD_PETAL, LOGO_BOX} from './logoPaths';

// Just the two petals, tightly boxed
export const LogoMark: React.FC<{
  size: number;
  cream?: string;
  gold?: string;
  creamStyle?: React.CSSProperties;
  goldStyle?: React.CSSProperties;
  style?: React.CSSProperties;
}> = ({size, cream = C.cream, gold = C.gold, creamStyle, goldStyle, style}) => {
  const h = size;
  const w = (size * LOGO_BOX.w) / LOGO_BOX.h;
  return (
    <svg
      width={w}
      height={h}
      viewBox={`${LOGO_BOX.x} ${LOGO_BOX.y} ${LOGO_BOX.w} ${LOGO_BOX.h}`}
      style={{overflow: 'visible', ...style}}
    >
      <path d={GOLD_PETAL} fill={gold} style={{transformBox: 'fill-box', transformOrigin: 'center', ...goldStyle}} />
      <path d={CREAM_PETAL} fill={cream} style={{transformBox: 'fill-box', transformOrigin: 'center', ...creamStyle}} />
    </svg>
  );
};

// App icon: espresso squircle with the mark (iOS rounds it; we draw the rounding)
export const AppIcon: React.FC<{
  size: number;
  radius?: number;
  shimmer?: number; // 0..1 sweep position, <0 = none
  children?: React.ReactNode;
  style?: React.CSSProperties;
  petalSpread?: number;
}> = ({size, radius, shimmer = -1, style, petalSpread = 0}) => {
  const r = radius ?? size * 0.225;
  return (
    <div
      style={{
        width: size,
        height: size,
        borderRadius: r,
        background: C.espresso,
        position: 'relative',
        overflow: 'hidden',
        ...style,
      }}
    >
      <svg width={size} height={size} viewBox="0 0 1000 1000" style={{position: 'absolute', inset: 0}}>
        <path d={GOLD_PETAL} fill={C.gold} transform={`translate(${-petalSpread * 40} ${petalSpread * 60})`} />
        <path d={CREAM_PETAL} fill={C.cream} transform={`translate(${petalSpread * 40} ${-petalSpread * 60})`} />
      </svg>
      {shimmer >= 0 && shimmer <= 1 ? (
        <div
          style={{
            position: 'absolute',
            top: -size * 0.5,
            left: -size + shimmer * size * 2.6,
            width: size * 0.32,
            height: size * 2,
            transform: 'rotate(25deg)',
            background:
              'linear-gradient(90deg, rgba(255,255,255,0) 0%, rgba(255,255,255,0.38) 50%, rgba(255,255,255,0) 100%)',
          }}
        />
      ) : null}
    </div>
  );
};
