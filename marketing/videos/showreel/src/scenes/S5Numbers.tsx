import React from 'react';
import {AbsoluteFill, interpolate, useCurrentFrame} from 'remotion';
import {C, FONT, B} from '../theme';
import {SPR, clamp, eio, eout, fmt, hit, shake, sp} from '../anim';
import {MotionBlur} from '../components/Blur';
import {RiseLine, SlamWord, Tag} from '../components/Kinetic';
import {Ring} from '../components/FineryUI';

// beats 28..36
const L = (beat: number) => B(beat - 28);

// rolling odometer: each digit column scrolls continuously
const Odometer: React.FC<{value: number; prev: number; size: number; color: string; digits: number}> = ({
  value,
  prev,
  size,
  color,
  digits,
}) => {
  const cols = [];
  const h = size * 1.0;
  for (let p = digits - 1; p >= 0; p--) {
    // real odometer: a digit moves only while the next lower digit rolls 9 -> 0
    const digitPos = (x: number): number => {
      let pos = x % 10;
      for (let q = 1; q <= p; q++) {
        const d = Math.floor(x / Math.pow(10, q)) % 10;
        pos = d + Math.max(0, pos - 9);
      }
      return pos;
    };
    const pos = digitPos(value);
    const speed = Math.min(Math.abs(pos - digitPos(prev)), 1.5);
    cols.push(
      <div key={p} style={{display: 'flex'}}>
        <MotionBlur y={Math.min(8, speed * 3)} style={{height: h, overflow: 'hidden', width: size * 0.6}}>
          <div style={{transform: `translateY(${-pos * h}px)`}}>
            {[0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 0].map((d, i) => (
              <div key={i} style={{height: h, lineHeight: `${h}px`, textAlign: 'center'}}>
                {d}
              </div>
            ))}
          </div>
        </MotionBlur>
        {p === 3 ? <div style={{width: size * 0.22}} /> : null}
      </div>,
    );
  }
  return (
    <div style={{display: 'flex', fontFamily: FONT, fontWeight: 900, fontSize: size, color, letterSpacing: -4}}>
      {cols}
      <div style={{marginLeft: size * 0.12, lineHeight: `${h}px`}}>₽</div>
    </div>
  );
};

export const S5Numbers: React.FC = () => {
  const f = useCurrentFrame();
  const B_ = L(31);
  const C_ = L(34);

  // A — odometer
  const roll = eout(f, 0, L(30));
  const rollPrev = eout(f - 1, 0, L(30));
  const val = 29950 + 30000 * roll;
  const prev = 29950 + 30000 * rollPrev;
  const land = sp(f, L(30), SPR.punch);
  const tilt = interpolate(sp(f, 0, SPR.page), [0, 1], [22, 0]);
  const whip = eio(f, B_ - 9, B_ + 3); // 0..1 horizontal pass

  // B — tax
  const taxVal = eout(f, L(32), L(33)) * 1200;
  const chip = sp(f, L(33.5), SPR.punch);

  // C — limit ring
  const wipe = eout(f, C_, C_ + 10);
  const ring = eout(f, C_ + 6, L(35.5));
  const sh = shake(f, [L(30), L(31), L(33.5), C_], 20, 'num');

  return (
    <AbsoluteFill style={{background: C.espresso, overflow: 'hidden'}}>
      {/* A */}
      {f < B_ + 3 ? (
        <AbsoluteFill
          style={{
            transform: `translate(${-whip * 1300 + sh.x}px, ${sh.y}px)`,
            filter: `blur(${Math.sin(whip * Math.PI) * 18}px)`,
          }}
        >
          <AbsoluteFill style={{perspective: 1600}}>
            <AbsoluteFill
              style={{
                display: 'flex',
                flexDirection: 'column',
                alignItems: 'center',
                justifyContent: 'center',
                transform: `rotateX(${tilt}deg) scale(${1 + (f / B(3)) * 0.06})`,
                gap: 56,
              }}
            >
              <Tag n="03" label="ДОХОД · ОКТЯБРЬ" at={4} color={C.gold} />
              <div style={{transform: `scale(${interpolate(land, [0, 1], [1.12, 1])})`}}>
                <Odometer value={val} prev={prev} size={176} color={f >= L(30) && f < L(30) + 10 ? C.gold : C.ivory} digits={5} />
              </div>
              <div
                style={{
                  transform: `scale(${sp(f, 14, SPR.punch)})`,
                  background: C.success,
                  color: '#fff',
                  fontFamily: FONT,
                  fontWeight: 900,
                  fontSize: 54,
                  padding: '16px 38px',
                  borderRadius: 60,
                }}
              >
                +30 000 ₽ · Реклама
              </div>
            </AbsoluteFill>
          </AbsoluteFill>
        </AbsoluteFill>
      ) : null}

      {/* B */}
      {f >= B_ - 9 && f < C_ + 10 ? (
        <AbsoluteFill
          style={{
            background: C.bg,
            transform: `translate(${(1 - whip) * 1300 + sh.x}px, ${sh.y}px)`,
            filter: `blur(${Math.sin(whip * Math.PI) * 18}px)`,
          }}
        >
          <div style={{position: 'absolute', top: 290, left: 64, right: 64}}>
            <RiseLine
              size={146}
              color={C.espresso}
              align="left"
              words={[
                {t: 'Налог', at: B_ - 2},
                {t: 'посчитан', at: B_ + 8},
              ]}
            />
            <div style={{marginTop: 4}}>
              <SlamWord text="сам." at={B_ + 20} size={146} color={C.espresso} from={1.8} highlight={C.gold} highlightAt={B_ + 26} />
            </div>
          </div>
          <div
            style={{
              position: 'absolute',
              top: 820,
              left: 64,
              fontFamily: FONT,
              fontWeight: 900,
              fontSize: 240,
              letterSpacing: -10,
              color: C.espresso,
              fontVariantNumeric: 'tabular-nums',
              opacity: f >= L(32) ? 1 : 0,
              transform: `scale(${1 + hit(f, L(33), 12) * 0.08})`,
              transformOrigin: 'left center',
            }}
          >
            {fmt(taxVal)}
            {' ₽'}
          </div>
          <div
            style={{
              position: 'absolute',
              top: 1110,
              left: 64,
              display: 'flex',
              alignItems: 'center',
              gap: 18,
              transform: `scale(${chip})`,
              transformOrigin: 'left center',
            }}
          >
            <div style={{background: C.espresso, color: C.cream, fontFamily: FONT, fontWeight: 900, fontSize: 50, padding: '16px 34px', borderRadius: 60}}>
              4% · отложи до 28-го
            </div>
          </div>
          <div
            style={{
              position: 'absolute',
              top: 1250,
              left: 64,
              fontFamily: FONT,
              fontWeight: 800,
              fontSize: 44,
              color: C.muted,
              opacity: chip,
            }}
          >
            с дохода 30 000 ₽ от физлица
          </div>
        </AbsoluteFill>
      ) : null}

      {/* C — gold, NPD limit ring */}
      {f >= C_ ? (
        <AbsoluteFill
          style={{
            background: C.gold,
            clipPath: `circle(${wipe * 160}% at 50% 62%)`,
            transform: `translate(${sh.x}px, ${sh.y}px)`,
          }}
        >
          <div style={{position: 'absolute', top: 290, left: 64, right: 64}}>
            <RiseLine
              size={118}
              color={C.espresso}
              words={[
                {t: 'Лимит', at: C_ + 2},
                {t: 'НПД', at: C_ + 8},
                {t: 'под', at: C_ + 16},
                {t: 'присмотром.', at: C_ + 22},
              ]}
            />
          </div>
          <div style={{position: 'absolute', left: 540 - 270, top: 640, transform: `rotate(${(1 - ring) * -90}deg)`}}>
            <Ring size={540} pct={ring * 0.1} stroke={44} color={C.espresso} track="rgba(26,21,16,0.16)" marker={0.8}>
              <div style={{transform: `rotate(${(1 - ring) * 90}deg)`, textAlign: 'center', fontFamily: FONT}}>
                <div style={{fontWeight: 900, fontSize: 150, color: C.espresso, letterSpacing: -6, lineHeight: 1}}>
                  {Math.round(ring * 10)}%
                </div>
                <div style={{fontWeight: 800, fontSize: 40, color: C.espresso, opacity: 0.75}}>из 2,4 млн ₽</div>
              </div>
            </Ring>
          </div>
          <div
            style={{
              position: 'absolute',
              top: 1230,
              left: 64,
              right: 64,
              textAlign: 'center',
              fontFamily: FONT,
              fontWeight: 800,
              fontSize: 46,
              color: C.espresso,
              opacity: eout(f, L(35), L(35.5)),
              transform: `translateY(${(1 - eout(f, L(35), L(35.5))) * 30}px)`,
            }}
          >
            На 80% — предупредим
          </div>
        </AbsoluteFill>
      ) : null}
    </AbsoluteFill>
  );
};
