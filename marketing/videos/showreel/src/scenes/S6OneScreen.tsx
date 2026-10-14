import React from 'react';
import {AbsoluteFill, interpolate, random, useCurrentFrame} from 'remotion';
import {C, B} from '../theme';
import {SPR, clamp, ein, eio, lin, shake, sp} from '../anim';
import {HeroCard, TileId, TileView} from '../components/FineryUI';
import {SlamWord, Tag} from '../components/Kinetic';

// beats 36..44
const L = (beat: number) => B(beat - 36);
const SC = 1.95;

type El = {id: TileId | 'hero'; x: number; y: number; z: number; w: number; h: number};
const ELS: El[] = [
  {id: 'hero', x: 0, y: 0, z: 420, w: 358, h: 162},
  {id: 'add', x: 0, y: 174, z: 260, w: 173, h: 96},
  {id: 'tips', x: 185, y: 174, z: 330, w: 173, h: 96},
  {id: 'tax', x: 0, y: 282, z: 200, w: 358, h: 96},
  {id: 'dyn', x: 0, y: 390, z: 120, w: 173, h: 110},
  {id: 'clients', x: 185, y: 390, z: 170, w: 173, h: 110},
];

export const S6OneScreen: React.FC = () => {
  const f = useCurrentFrame();
  const ASM = L(40);
  const asm = sp(f, ASM, {damping: 12, stiffness: 150, mass: 0.9});
  const orbit = lin(f, 0, ASM, -40, -24);
  const rotX = interpolate(asm, [0, 1], [50, 0]);
  const rotZ = interpolate(asm, [0, 1], [orbit, 0]);
  const zMul = 1 - asm;
  const push = f > ASM ? eio(f, ASM + 20, L(43.5), 0, 0.08) : 0;
  const exit = ein(f, L(43.5), L(44));
  const sh = shake(f, [ASM], 30, 'one');

  const W = 358 * SC;
  const H = 500 * SC;

  return (
    <AbsoluteFill style={{background: C.bg, overflow: 'hidden'}}>
      {/* editorial grid */}
      <AbsoluteFill style={{opacity: 0.9}}>
        {Array.from({length: 9}).map((_, k) => (
          <div key={'v' + k} style={{position: 'absolute', left: k * 135, top: 0, bottom: 0, width: 2, background: C.line}} />
        ))}
        {Array.from({length: 15}).map((_, k) => (
          <div key={'h' + k} style={{position: 'absolute', top: k * 135, left: 0, right: 0, height: 2, background: C.line}} />
        ))}
      </AbsoluteFill>

      <AbsoluteFill
        style={{
          transform: `translate(${sh.x}px, ${sh.y - exit * 1900}px)`,
          filter: `blur(${exit * 20}px)`,
        }}
      >
        <AbsoluteFill style={{perspective: 2400, perspectiveOrigin: '50% 55%'}}>
          <div
            style={{
              position: 'absolute',
              left: 540 - W / 2,
              top: 590 + zMul * 170,
              width: W,
              height: H,
              transformStyle: 'preserve-3d',
              transform: `rotateX(${rotX}deg) rotateZ(${rotZ}deg) scale(${(1 + push) * interpolate(asm, [0, 1], [1.12, 1])})`,
              transformOrigin: '50% 45%',
            }}
          >
            {/* ghost slots on the base plane */}
            {ELS.map((e, i) => (
              <div
                key={'g' + i}
                style={{
                  position: 'absolute',
                  left: e.x * SC,
                  top: e.y * SC,
                  width: e.w * SC,
                  height: e.h * SC,
                  borderRadius: 18 * SC,
                  border: `3px dashed ${C.muted}`,
                  opacity: 0.45 * zMul,
                  boxSizing: 'border-box',
                }}
              />
            ))}
            {ELS.map((e, i) => {
              const at = L(36.5 + i * 0.5) - 6;
              const s = sp(f, at, SPR.punch);
              const z = e.z * zMul + (1 - s) * 1400;
              const sh = f > ASM + 10 ? ((f - ASM - 10 - random(e.id) * 60) % 150) / 70 : -1;
              return (
                <div
                  key={e.id}
                  style={{
                    position: 'absolute',
                    left: e.x * SC,
                    top: e.y * SC,
                    transform: `translateZ(${z}px) scale(${SC})`,
                    transformOrigin: '0 0',
                    opacity: f < at ? 0 : Math.min(1, s * 1.5),
                  }}
                >
                  {e.id === 'hero' ? (
                    <HeroCard income={59950} expense={21050} tax={2398} />
                  ) : (
                    <TileView id={e.id} shimmer={sh} />
                  )}
                </div>
              );
            })}
          </div>
        </AbsoluteFill>

        <div style={{position: 'absolute', top: 285, left: 64, right: 64, display: 'flex', flexDirection: 'column', alignItems: 'center', zIndex: 100, transform: 'translateZ(2000px)'}}>
          <Tag n="04" label="ВСЁ ВМЕСТЕ" at={0} color={C.muted} style={{marginBottom: 16}} />
          {f < ASM ? (
            <SlamWord text="Все твои деньги." at={4} size={104} color={C.espresso} from={1.7} out={ASM - 8} />
          ) : (
            <SlamWord text="Один экран." at={ASM} size={130} color={C.espresso} from={2.4} highlight={C.gold} highlightAt={ASM + 8} />
          )}
        </div>
      </AbsoluteFill>
    </AbsoluteFill>
  );
};
