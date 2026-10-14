import React from 'react';
import {AbsoluteFill, interpolate, useCurrentFrame} from 'remotion';
import {C, FONT, B} from '../theme';
import {SPR, clamp, ein, eout, shake, sp} from '../anim';
import {AppIcon} from '../components/Logo';
import {MotionBlur} from '../components/Blur';

// beats 16..20
const L = (beat: number) => B(beat - 16);
const WORD = 'Finery'.split('');

export const S3Brand: React.FC = () => {
  const f = useCurrentFrame();
  const icon = sp(f, 0, {damping: 10, stiffness: 170, mass: 0.8});
  const sh = shake(f, [0, ...WORD.map((_, i) => L(16 + i * 0.5))], 22, 'brand');
  const zoom = ein(f, L(18.9), L(20));
  const zoomScale = interpolate(zoom, [0, 1], [1, 16]);
  const flash = interpolate(f, [0, 10], [1, 0], clamp);

  return (
    <AbsoluteFill style={{background: C.bg, overflow: 'hidden'}}>
      {/* concentric shock rings */}
      <AbsoluteFill>
        {[0, 6, 12].map((d, i) => {
          const t = eout(f, d, d + 50);
          return (
            <div
              key={i}
              style={{
                position: 'absolute',
                left: 540 - t * 1300,
                top: 720 - t * 1300,
                width: t * 2600,
                height: t * 2600,
                borderRadius: '50%',
                border: `${4 + (1 - t) * 14}px solid ${i === 1 ? C.gold : C.espresso}`,
                opacity: (1 - t) * 0.9,
                boxSizing: 'border-box',
              }}
            />
          );
        })}
      </AbsoluteFill>
      <AbsoluteFill
        style={{
          transform: `translate(${sh.x}px, ${sh.y}px) scale(${zoomScale})`,
          transformOrigin: '540px 720px',
        }}
      >
        <div
          style={{
            position: 'absolute',
            left: 540 - 170,
            top: 720 - 170,
            transform: `scale(${interpolate(icon, [0, 1], [0.3, 1])}) rotate(${(1 - icon) * -25}deg)`,
          }}
        >
          <AppIcon size={340} shimmer={interpolate(f, [L(17), L(18.2)], [0, 1], clamp)} petalSpread={Math.max(0, 1 - icon) * 3} />
        </div>
        <div
          style={{
            position: 'absolute',
            top: 990,
            left: 0,
            right: 0,
            display: 'flex',
            justifyContent: 'center',
            fontFamily: FONT,
            fontWeight: 900,
            fontSize: 250,
            letterSpacing: -8,
            color: C.espresso,
            opacity: 1 - zoom * 1.5,
          }}
        >
          {WORD.map((ch, i) => {
            const at = L(16 + i * 0.5) - 4;
            const s = sp(f, at, SPR.punch);
            const s2 = sp(f - 1, at, SPR.punch);
            const dir = i % 2 ? 1 : -1;
            return (
              <MotionBlur key={i} y={Math.abs(s - s2) * 40} style={{display: 'inline-block'}}>
                <span
                  style={{
                    display: 'inline-block',
                    opacity: f < at ? 0 : 1,
                    transform: `translateY(${(1 - s) * -700 * dir}px) rotate(${(1 - s) * 30 * dir}deg)`,
                  }}
                >
                  {ch}
                </span>
              </MotionBlur>
            );
          })}
        </div>
      </AbsoluteFill>
      <AbsoluteFill style={{background: C.gold, opacity: flash}} />
      <AbsoluteFill style={{background: C.espresso, opacity: interpolate(zoom, [0.75, 1], [0, 1], clamp)}} />
    </AbsoluteFill>
  );
};
