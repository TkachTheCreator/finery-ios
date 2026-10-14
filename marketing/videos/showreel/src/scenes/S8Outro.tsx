import React from 'react';
import {AbsoluteFill, interpolate, useCurrentFrame} from 'remotion';
import {C, FONT, B} from '../theme';
import {SPR, clamp, eout, shake, sp} from '../anim';
import {AppIcon} from '../components/Logo';

// beats 50..58 — the clean final frame
const L = (beat: number) => B(beat - 50);
const WORD = 'Finery'.split('');

export const S8Outro: React.FC = () => {
  const f = useCurrentFrame();
  const icon = sp(f, 0, {damping: 11, stiffness: 150, mass: 0.8}); // brand spring 0.3 -> 1
  const sh = shake(f, [0], 30, 'out');
  const flash = interpolate(f, [0, 12], [1, 0], clamp);
  const tag = sp(f, L(52), SPR.card);
  const cta = sp(f, L(53), SPR.punch);
  const url = eout(f, L(53.4), L(54));
  const breathe = 1 + Math.sin(Math.max(0, f - L(54)) / 40) * 0.006;

  return (
    <AbsoluteFill style={{background: C.bg, overflow: 'hidden'}}>
      {/* expanding rings on the final hit */}
      {[0, 8].map((d, i) => {
        const t = eout(f, d, d + 60);
        return (
          <div
            key={i}
            style={{
              position: 'absolute',
              left: 540 - t * 1200,
              top: 690 - t * 1200,
              width: t * 2400,
              height: t * 2400,
              borderRadius: '50%',
              border: `${4 + (1 - t) * 10}px solid ${i ? C.gold : C.espresso}`,
              opacity: 1 - t,
              boxSizing: 'border-box',
            }}
          />
        );
      })}
      <AbsoluteFill style={{transform: `translate(${sh.x}px, ${sh.y}px) scale(${breathe})`}}>
        <div
          style={{
            position: 'absolute',
            left: 540 - 160,
            top: 690 - 160,
            transform: `scale(${interpolate(icon, [0, 1], [0.3, 1])})`,
          }}
        >
          <AppIcon size={320} shimmer={interpolate(f, [L(54), L(55.6)], [0, 1], clamp)} />
        </div>
        <div
          style={{
            position: 'absolute',
            top: 900,
            left: 0,
            right: 0,
            display: 'flex',
            justifyContent: 'center',
            fontFamily: FONT,
            fontWeight: 900,
            fontSize: 190,
            letterSpacing: -6,
            color: C.espresso,
            lineHeight: 1,
          }}
        >
          {WORD.map((ch, i) => {
            const s = sp(f, L(51) + i * 3, SPR.card);
            return (
              <span
                key={i}
                style={{
                  display: 'inline-block',
                  opacity: Math.min(1, s * 1.4),
                  transform: `translateY(${(1 - s) * 90}px)`,
                  filter: `blur(${(1 - Math.min(1, s)) * 10}px)`,
                }}
              >
                {ch}
              </span>
            );
          })}
        </div>
        <div
          style={{
            position: 'absolute',
            top: 1125,
            left: 64,
            right: 64,
            textAlign: 'center',
            fontFamily: FONT,
            fontWeight: 800,
            fontSize: 58,
            lineHeight: 1.15,
            color: C.muted,
            opacity: tag,
            transform: `translateY(${(1 - tag) * 24}px)`,
          }}
        >
          Все твои деньги. Один экран.
        </div>
        <div style={{position: 'absolute', top: 1260, left: 0, right: 0, display: 'flex', justifyContent: 'center'}}>
          <div
            style={{
              background: C.espresso,
              color: C.cream,
              fontFamily: FONT,
              fontWeight: 900,
              fontSize: 54,
              padding: '26px 56px',
              borderRadius: 999,
              transform: `scale(${cta})`,
              display: 'flex',
              alignItems: 'center',
              gap: 20,
            }}
          >
            <span style={{width: 18, height: 18, borderRadius: 9, background: C.gold, display: 'inline-block'}} />
            Скоро в App Store
          </div>
        </div>
        <div
          style={{
            position: 'absolute',
            top: 1430,
            left: 0,
            right: 0,
            textAlign: 'center',
            fontFamily: FONT,
            fontWeight: 800,
            fontSize: 40,
            letterSpacing: 1,
            color: C.muted,
            opacity: url,
          }}
        >
          для iPhone · finery.pro
        </div>
      </AbsoluteFill>
      <AbsoluteFill style={{background: '#fff', opacity: flash * 0.9}} />
    </AbsoluteFill>
  );
};
