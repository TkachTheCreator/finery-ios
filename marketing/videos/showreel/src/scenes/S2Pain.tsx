import React from 'react';
import {AbsoluteFill, interpolate, random, useCurrentFrame} from 'remotion';
import {C, FONT, B} from '../theme';
import {SPR, clamp, ein, eio, eout, fmt, lin, shake, sp} from '../anim';
import {SlamWord, Tag} from '../components/Kinetic';
import {GOLD_PETAL} from '../components/logoPaths';

// local frames; scene starts at beat 8
const L = (beat: number) => B(beat - 8);

const COLS = 7;
const ROWS = 18;

const Sheet: React.FC<{f: number}> = ({f}) => {
  const tick = Math.floor(f / 4);
  const cells = [];
  for (let r = 0; r < ROWS; r++) {
    for (let c = 0; c < COLS; c++) {
      const seed = `${r}-${c}`;
      const err = random(seed + 'e') < 0.08;
      const live = random(seed + 'l') < 0.35;
      const v = live ? random(seed + tick) : random(seed);
      const txt = c === 0 ? `${r + 2}` : err ? (random(seed + 'k') < 0.5 ? '#ЗНАЧ!' : '#ССЫЛКА!') : fmt(Math.floor(v * 90000) + 300);
      cells.push(
        <div
          key={seed}
          style={{
            position: 'absolute',
            left: c * 240,
            top: r * 84,
            width: 240,
            height: 84,
            borderRight: `2px solid ${C.line}`,
            borderBottom: `2px solid ${C.line}`,
            boxSizing: 'border-box',
            display: 'flex',
            alignItems: 'center',
            justifyContent: c === 0 ? 'center' : 'flex-end',
            padding: '0 20px',
            fontFamily: FONT,
            fontWeight: c === 0 ? 800 : 700,
            fontSize: 38,
            color: err ? C.expense : c === 0 ? C.muted : C.text,
            background: err ? 'rgba(192,78,53,0.10)' : c === 0 ? C.bg2 : '#fff',
            fontVariantNumeric: 'tabular-nums',
          }}
        >
          {txt}
        </div>,
      );
    }
  }
  return <div style={{position: 'relative', width: COLS * 240, height: ROWS * 84}}>{cells}</div>;
};

// tear-off calendar
const FLIPS = Array.from({length: 27}, (_, i) => 11 + 1.75 * Math.pow(i / 26, 0.7)); // day i+2 shows at beat

const Calendar: React.FC<{f: number}> = ({f}) => {
  let day = 1;
  let lastFlip = -999;
  FLIPS.forEach((bt, i) => {
    if (f >= L(bt)) {
      day = i + 2;
      lastFlip = L(bt);
    }
  });
  const leaving = f - lastFlip < 8 && day > 1 ? day - 1 : null;
  const lt = (f - lastFlip) / 8;
  const final = day === 28;
  const land = final ? sp(f, L(13), SPR.punch) : 1;
  const page = (d: number, style: React.CSSProperties) => (
    <div
      style={{
        position: 'absolute',
        inset: 0,
        top: 130,
        background: C.cream,
        display: 'flex',
        alignItems: 'center',
        justifyContent: 'center',
        fontFamily: FONT,
        fontWeight: 900,
        fontSize: 330,
        letterSpacing: -14,
        color: d === 28 ? C.expense : C.espresso,
        borderRadius: '0 0 40px 40px',
        ...style,
      }}
    >
      {d}
    </div>
  );
  return (
    <div
      style={{
        position: 'relative',
        width: 600,
        height: 640,
        transform: `scale(${final ? interpolate(land, [0, 1], [1.25, 1]) : 1}) rotate(${final ? (1 - land) * -6 : 0}deg)`,
      }}
    >
      <div
        style={{
          position: 'absolute',
          left: 0,
          right: 0,
          top: 0,
          height: 140,
          background: C.espresso,
          borderRadius: '40px 40px 0 0',
          display: 'flex',
          alignItems: 'center',
          justifyContent: 'center',
          fontFamily: FONT,
          fontWeight: 900,
          fontSize: 58,
          letterSpacing: 10,
          color: C.cream,
        }}
      >
        ОКТЯБРЬ
      </div>
      {/* rings */}
      {[150, 450].map((x) => (
        <div key={x} style={{position: 'absolute', left: x - 14, top: -30, width: 28, height: 80, borderRadius: 14, background: C.ivory, border: `4px solid ${C.espresso}`, zIndex: 3}} />
      ))}
      {page(day, {})}
      {leaving !== null
        ? page(leaving, {
            transformOrigin: 'top center',
            transform: `perspective(1200px) rotateX(${lt * 100}deg) translateY(${-lt * 60}px)`,
            opacity: 1 - lt,
          })
        : null}
    </div>
  );
};

export const S2Pain: React.FC = () => {
  const f = useCurrentFrame();
  const partB = L(11);
  const partC = L(14);

  const sh = shake(f, [L(8), L(8.5), L(10), partB, L(13), partC], 26, 'pain');

  // ---- A: spreadsheet
  const camY = lin(f, 0, partB, 0, -420);
  const camR = lin(f, 0, partB, -28, -20);
  const strike = eout(f, L(10), L(10.6));

  // ---- C: turn
  const suck = ein(f, L(15.1), L(15.8));
  const petal = ein(f, L(15.2), L(16));

  return (
    <AbsoluteFill style={{overflow: 'hidden', background: C.bg}}>
      {f < partB ? (
        <AbsoluteFill style={{transform: `translate(${sh.x}px, ${sh.y}px)`}}>
          <AbsoluteFill style={{perspective: 1500, perspectiveOrigin: '50% 30%'}}>
            <div
              style={{
                position: 'absolute',
                left: 540 - (COLS * 240) / 2,
                top: 420,
                transformStyle: 'preserve-3d',
                transform: `rotateX(54deg) rotateZ(${camR}deg) translateY(${camY}px) scale(${1 + lin(f, 0, partB, 0, 0.15)})`,
                opacity: 0.95,
              }}
            >
              <Sheet f={f} />
            </div>
          </AbsoluteFill>
          {/* formula bar */}
          <div
            style={{
              position: 'absolute',
              left: 64,
              right: 64,
              top: 1250,
              height: 110,
              borderRadius: 26,
              background: '#fff',
              border: `2px solid ${C.line}`,
              display: 'flex',
              alignItems: 'center',
              padding: '0 32px',
              gap: 22,
              fontFamily: FONT,
              fontSize: 42,
              fontWeight: 800,
              transform: `translateY(${(1 - sp(f, L(9), SPR.card)) * 300}px)`,
            }}
          >
            <span style={{color: C.muted, fontStyle: 'italic'}}>fx</span>
            <span style={{color: C.text}}>
              {'=СУММ(B2:B48)*0,04'.slice(0, Math.floor(lin(f, L(9), L(10.5), 0, 18)))}
            </span>
            <span style={{color: C.expense, marginLeft: 'auto', opacity: f > L(10.5) && Math.floor(f / 6) % 2 ? 1 : 0}}>#ЗНАЧ!</span>
          </div>
          {/* text on a paper band so it reads over the grid */}
          <div style={{position: 'absolute', top: 290, left: 0, right: 0, display: 'flex', flexDirection: 'column', alignItems: 'center'}}>
            <Tag n="01" label="РУТИНА" at={0} color={C.muted} style={{marginBottom: 26}} />
            <div style={{background: C.bg, padding: '6px 34px 16px', borderRadius: 30, display: 'flex', flexDirection: 'column', alignItems: 'center'}}>
              <SlamWord text="Считать" at={0} size={170} color={C.espresso} from={1.8} />
              <div style={{position: 'relative'}}>
                <SlamWord text="руками?" at={L(8.5)} size={170} color={C.espresso} from={1.8} />
                <svg width="640" height="120" viewBox="0 0 640 120" style={{position: 'absolute', left: -20, top: 40}}>
                  <path
                    d="M10 70 C 120 30, 220 100, 330 55 S 520 30, 630 62"
                    stroke={C.expense}
                    strokeWidth="18"
                    strokeLinecap="round"
                    fill="none"
                    strokeDasharray="700"
                    strokeDashoffset={700 * (1 - strike)}
                  />
                </svg>
              </div>
            </div>
          </div>
        </AbsoluteFill>
      ) : null}

      {f >= partB && f < partC ? (
        <AbsoluteFill style={{background: C.expense, transform: `translate(${sh.x}px, ${sh.y}px)`}}>
          <div style={{position: 'absolute', top: 300, left: 0, right: 0, display: 'flex', flexDirection: 'column', alignItems: 'center', gap: 8}}>
            <SlamWord text="Налог до 28-го." at={partB + 4} size={104} color={C.cream} from={1.6} />
            <SlamWord text="Это завтра." at={L(13)} size={150} color={C.espresso} from={2.6} rotate={-5} />
          </div>
          <div style={{position: 'absolute', left: 240, top: 760}}>
            <Calendar f={f} />
          </div>
        </AbsoluteFill>
      ) : null}

      {f >= partC ? (
        <AbsoluteFill style={{background: C.espresso}}>
          <AbsoluteFill
            style={{
              display: 'flex',
              flexDirection: 'column',
              alignItems: 'center',
              justifyContent: 'center',
              transform: `scale(${1 - suck * 0.95}) rotate(${suck * 40}deg)`,
              filter: `blur(${suck * 8}px)`,
              opacity: 1 - suck,
            }}
          >
            <SlamWord text="А если" at={partC} size={150} color={C.ivory} from={1.6} />
            <SlamWord text="не считать" at={L(14.5)} size={150} color={C.ivory} from={1.6} />
            <SlamWord text="вообще?" at={L(15)} size={170} color={C.gold} from={2.4} />
          </AbsoluteFill>
          {/* gold petal swallowing the frame */}
          <AbsoluteFill style={{display: 'flex', alignItems: 'center', justifyContent: 'center'}}>
            <svg
              width="1000"
              height="1000"
              viewBox="300 250 460 560"
              style={{
                transform: `scale(${interpolate(petal, [0, 1], [0, 9])}) rotate(${interpolate(petal, [0, 1], [-120, 0])}deg)`,
                opacity: f >= L(15.2) ? 1 : 0,
              }}
            >
              <path d={GOLD_PETAL} fill={C.gold} />
            </svg>
          </AbsoluteFill>
          <AbsoluteFill style={{background: C.gold, opacity: eio(f, L(15.85), L(16))}} />
        </AbsoluteFill>
      ) : null}
    </AbsoluteFill>
  );
};
