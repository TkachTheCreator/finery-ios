import React from 'react';
import {AbsoluteFill, interpolate, useCurrentFrame} from 'remotion';
import {C, FONT, B} from '../theme';
import {SPR, clamp, ein, eout, hit, lin, shake, sp} from '../anim';
import {Phone, PHONE_RATIO} from '../components/Phone';
import {HomeScreen, QuickSheet, Toast} from '../components/FineryUI';
import {RiseLine, SlamWord, Tag} from '../components/Kinetic';

// beats 20..28
const L = (beat: number) => B(beat - 20);
const TYPED = 'Реклама 30 000';
const PW = 780;
const PX = 540 - PW / 2;
const PY = 590;
const SCALE = (PW - PW * 0.035 * 2) / 390;
const BEZ = PW * 0.035;

export const S4Quick: React.FC = () => {
  const f = useCurrentFrame();

  // phone enters from depth, showing its back
  const enter = sp(f, 0, {damping: 16, stiffness: 120, mass: 1});
  const flip = sp(f, L(22.9), {damping: 14, stiffness: 150, mass: 0.9});
  const rotY = interpolate(enter, [0, 1], [250, 180]) + flip * 180;
  const rotX = interpolate(enter, [0, 1], [24, 4]) - flip * 4;
  const knockA = hit(f, L(22), 10);
  const knockB = hit(f, L(22.5), 10);
  const jolt = 1 - (knockA + knockB) * 0.035;
  const z = interpolate(enter, [0, 1], [-2600, 0]);

  // sheet + typing
  const sheetIn = sp(f, L(23.25), SPR.card);
  const sheetOut = ein(f, L(26.15), L(26.45));
  const nChars = Math.max(0, Math.min(TYPED.length, Math.floor((f - L(23.5)) / (B(2) / TYPED.length)) + 1));
  const typed = f >= L(23.5) ? TYPED.slice(0, nChars) : '';
  const press = hit(f, L(26), 12);
  const toastIn = sp(f, L(26.5), SPR.punch);
  const check = eout(f, L(26.6), L(27.1));
  const added = eout(f, L(26.5), L(27.3));
  const income = 29950 + 30000 * added;
  const tax = 1198 + 1200 * added;

  // push into the hero card
  const push = ein(f, L(27.35), L(28));
  const heroX = PX + BEZ + (16 + 179) * SCALE;
  const heroY = PY + BEZ + (120 + 81) * SCALE;

  const sh = shake(f, [L(22), L(22.5), L(26), L(26.5)], 14, 'quick');

  // finger for the "Готово" tap — button center in screen pt (≈ 290, 54+18+... )
  const fingerT = eout(f, L(25.4), L(25.95));
  const btnX = PX + BEZ + 279 * SCALE;
  const btnY = PY + BEZ + 230 * SCALE;

  return (
    <AbsoluteFill style={{background: C.espresso, overflow: 'hidden'}}>
      {/* soft gold floor light */}
      <AbsoluteFill
        style={{
          background: 'radial-gradient(ellipse 60% 35% at 50% 78%, rgba(205,164,109,0.22), rgba(205,164,109,0) 70%)',
        }}
      />
      <AbsoluteFill
        style={{
          transform: `translate(${sh.x}px, ${sh.y}px) scale(${interpolate(push, [0, 1], [1, 6])})`,
          transformOrigin: `${heroX}px ${heroY}px`,
        }}
      >
        <AbsoluteFill style={{perspective: 2200, perspectiveOrigin: '50% 45%'}}>
          <div
            style={{
              position: 'absolute',
              left: PX,
              top: PY,
              transformStyle: 'preserve-3d',
              transform: `translateZ(${z}px) scale(${jolt})`,
            }}
          >
            <Phone
              width={PW}
              rotY={rotY}
              rotX={rotX}
              rotZ={(1 - enter) * -14}
              rim={knockA + knockB + (1 - flip) * 0.3}
              back={
                <>
                  {[L(22), L(22.5)].map((t, i) => {
                    const e = eout(f, t, t + 24);
                    return f >= t ? (
                      <div
                        key={i}
                        style={{
                          position: 'absolute',
                          left: PW / 2 - 60,
                          top: (PW * PHONE_RATIO) / 2 - 60,
                          width: 120,
                          height: 120,
                          borderRadius: '50%',
                          border: `${10 * (1 - e) + 2}px solid ${C.gold}`,
                          transform: `scale(${1 + e * 3.2})`,
                          opacity: 1 - e,
                          boxSizing: 'border-box',
                        }}
                      />
                    ) : null;
                  })}
                  {/* finger tip dot */}
                  <div
                    style={{
                      position: 'absolute',
                      left: PW / 2 - 46,
                      top: (PW * PHONE_RATIO) / 2 - 46,
                      width: 92,
                      height: 92,
                      borderRadius: '50%',
                      background: C.cream,
                      opacity: f > L(21.4) && f < L(22.85) ? 0.9 : 0,
                      transform: `scale(${1 - (knockA + knockB) * 0.25})`,
                    }}
                  />
                </>
              }
            >
              <HomeScreen income={income} tax={tax} />
              {/* quick sheet */}
              <div
                style={{
                  position: 'absolute',
                  left: 14,
                  top: 64,
                  transform: `translateY(${(1 - sheetIn) * -420 - sheetOut * 460}px)`,
                  zIndex: 70,
                }}
              >
                <QuickSheet text={typed} caret={Math.floor(f / 15) % 2 === 0 || (f > L(23.5) && f < L(25.6))} pressDone={press} />
              </div>
              {/* dim behind sheet */}
              <div
                style={{
                  position: 'absolute',
                  inset: 0,
                  background: 'rgba(26,21,16,0.35)',
                  opacity: sheetIn * (1 - sheetOut),
                  zIndex: 65,
                }}
              />
              {/* toast */}
              <div
                style={{
                  position: 'absolute',
                  left: 14,
                  top: 60,
                  transform: `translateY(${(1 - toastIn) * -200}px) scale(${0.9 + toastIn * 0.1})`,
                  opacity: f >= L(26.5) ? Math.min(1, toastIn * 2) * (1 - lin(f, L(27.4), L(27.6))) : 0,
                  zIndex: 80,
                }}
              >
                <Toast check={check} />
              </div>
            </Phone>
          </div>
        </AbsoluteFill>

        {/* tap finger on "Готово" */}
        {f > L(25.3) && f < L(26.5) ? (
          <div
            style={{
              position: 'absolute',
              left: btnX - 50 + (1 - fingerT) * 260,
              top: btnY - 50 + (1 - fingerT) * 380 - Math.sin(fingerT * Math.PI) * 60,
              width: 100,
              height: 100,
              borderRadius: '50%',
              background: 'rgba(242,234,222,0.55)',
              border: `4px solid ${C.cream}`,
              transform: `scale(${1 - press * 0.3})`,
            }}
          />
        ) : null}
        {press > 0 ? (
          <div
            style={{
              position: 'absolute',
              left: btnX - 60,
              top: btnY - 60,
              width: 120,
              height: 120,
              borderRadius: '50%',
              border: `6px solid ${C.gold}`,
              transform: `scale(${1 + (1 - press) * 2})`,
              opacity: press,
            }}
          />
        ) : null}

        {/* tok-tok labels */}
        {[
          {t: L(22), x: 120, y: 980, r: -12},
          {t: L(22.5), x: 760, y: 1120, r: 10},
        ].map((k, i) =>
          f >= k.t && f < L(23) ? (
            <div key={i} style={{position: 'absolute', left: k.x, top: k.y}}>
              <SlamWord text="тук" at={k.t} size={110} color={C.gold} from={2} rotate={k.r} />
            </div>
          ) : null,
        )}

        {/* captions */}
        <div style={{position: 'absolute', top: 285, left: 64, right: 64}}>
          {f < L(23) ? (
            <>
              <Tag n="02" label="БЫСТРЫЙ ВВОД" at={0} color={C.gold} style={{justifyContent: 'center', marginBottom: 14}} />
              <RiseLine
                size={112}
                color={C.ivory}
                out={L(22.75)}
                words={[
                  {t: 'Два', at: 4},
                  {t: 'тапа', at: 10},
                  {t: 'по', at: L(21)},
                  {t: 'спинке.', at: L(21) + 6, color: C.gold},
                ]}
              />
            </>
          ) : f < L(26.5) ? (
            <RiseLine
              size={112}
              color={C.ivory}
              out={L(26.3)}
              style={{marginTop: 50}}
              words={[
                {t: 'Пишешь', at: L(23.1)},
                {t: 'одной', at: L(23.3)},
                {t: 'фразой.', at: L(23.5), color: C.gold},
              ]}
            />
          ) : (
            <div style={{display: 'flex', justifyContent: 'center', marginTop: 90}}>
              <SlamWord text="Записано." at={L(26.5)} size={150} color={C.gold} from={2.2} />
            </div>
          )}
        </div>
      </AbsoluteFill>
      <AbsoluteFill style={{background: C.espresso, opacity: interpolate(push, [0.7, 1], [0, 1], clamp)}} />
    </AbsoluteFill>
  );
};
