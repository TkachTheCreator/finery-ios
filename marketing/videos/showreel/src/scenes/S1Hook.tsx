import React from 'react';
import {AbsoluteFill, interpolate, useCurrentFrame} from 'remotion';
import {C, FONT, B} from '../theme';
import {SPR, clamp, ein, fmt, shake, sp} from '../anim';
import {SlamWord} from '../components/Kinetic';
import {MotionBlur} from '../components/Blur';

// 0 .. 8 beats
const NOTIFS = [
  {app: 'Boosty', sub: 'Подписка оформлена', amt: 4500, c: C.terra},
  {app: 'Донат', sub: '«на кофе и монтаж»', amt: 300, c: C.plum},
  {app: 'Реклама', sub: 'Интеграция оплачена', amt: 18000, c: C.amber},
  {app: 'Такси', sub: 'Поездка до студии', amt: -4000, c: '#8A847C'},
  {app: 'Заказ', sub: 'Анна К. перевела', amt: 12000, c: C.dusty},
  {app: 'Подписки', sub: 'Сервис монтажа', amt: -990, c: C.expense},
  {app: 'Платформы', sub: 'Выплата за сентябрь', amt: 8200, c: C.sage},
  {app: 'Курсы', sub: 'Новый ученик', amt: 2700, c: C.golden},
];

// deterministic layout
const POS = [
  {x: -40, y: 480, r: -6, dx: -1400, dy: 0},
  {x: 60, y: 620, r: 5, dx: 1400, dy: -200},
  {x: -70, y: 840, r: -3, dx: 0, dy: -1500},
  {x: 50, y: 900, r: 7, dx: 1400, dy: 300},
  {x: -30, y: 1040, r: -5, dx: -1400, dy: 200},
  {x: 70, y: 1180, r: 4, dx: 0, dy: 1500},
  {x: -60, y: 1320, r: -7, dx: -1400, dy: -300},
  {x: 30, y: 760, r: 2, dx: 1400, dy: 0},
];

const Notif: React.FC<{i: number; f: number}> = ({i, f}) => {
  const n = NOTIFS[i];
  const p = POS[i];
  const start = B(i * 0.5) - (i === 0 ? 30 : 8);
  if (f < start) return null;
  const s = sp(f, start, SPR.punch);
  const x = p.x + p.dx * (1 - s);
  const y = p.y + p.dy * (1 - s);
  // velocity for blur
  const s2 = sp(f - 1, start, SPR.punch);
  const vx = (p.dx * (s - s2)) * 0.35;
  const vy = (p.dy * (s - s2)) * 0.35;
  const plus = n.amt > 0;
  return (
    <MotionBlur
      x={vx}
      y={vy}
      style={{
        position: 'absolute',
        left: 540 - 420 + x,
        top: y,
        transform: `rotate(${p.r * s + (1 - s) * p.r * 3}deg)`,
        zIndex: i,
      }}
    >
      <div
        style={{
          width: 840,
          height: 150,
          borderRadius: 38,
          background: C.cream,
          display: 'flex',
          alignItems: 'center',
          padding: '0 30px',
          boxSizing: 'border-box',
          gap: 24,
          fontFamily: FONT,
          border: `2px solid rgba(26,21,16,0.08)`,
        }}
      >
        <div
          style={{
            width: 84,
            height: 84,
            borderRadius: 24,
            background: n.c,
            color: '#fff',
            fontWeight: 900,
            fontSize: 46,
            display: 'flex',
            alignItems: 'center',
            justifyContent: 'center',
            flexShrink: 0,
          }}
        >
          {n.app[0]}
        </div>
        <div style={{flex: 1, minWidth: 0}}>
          <div style={{fontSize: 38, fontWeight: 900, color: C.text, display: 'flex', justifyContent: 'space-between'}}>
            <span>{n.app}</span>
            <span style={{fontSize: 26, fontWeight: 700, color: C.muted, marginTop: 8}}>сейчас</span>
          </div>
          <div style={{fontSize: 29, fontWeight: 700, color: C.muted, whiteSpace: 'nowrap'}}>{n.sub}</div>
        </div>
        <div
          style={{
            fontSize: 44,
            fontWeight: 900,
            color: plus ? C.success : C.expense,
            whiteSpace: 'nowrap',
            letterSpacing: -1,
          }}
        >
          {plus ? '+' : '−'}
          {fmt(Math.abs(n.amt))}
          {' ₽'}
        </div>
      </div>
    </MotionBlur>
  );
};

export const S1Hook: React.FC = () => {
  const f = useCurrentFrame();
  const Q = B(4); // question starts
  const landings = NOTIFS.map((_, i) => B(i * 0.5) + 2);
  const wordHits = [Q, B(5), B(6)];
  const sh = shake(f, [...landings, ...wordHits, ...wordHits], f < Q ? 16 : 34, 'hook');

  // running total behind
  const total = NOTIFS.reduce((acc, n, i) => acc + (f >= B(i * 0.5) ? n.amt : 0), 0);

  const qT = f >= Q ? 1 : 0;
  const recede = sp(f, Q, SPR.page);
  const exit = ein(f, B(7.2), B(8), 0, 1);

  return (
    <AbsoluteFill style={{background: C.espresso, overflow: 'hidden'}}>
      {/* hairline editorial grid */}
      <AbsoluteFill style={{opacity: 0.5}}>
        {[1, 2, 3].map((k) => (
          <div key={k} style={{position: 'absolute', left: k * 270, top: 0, bottom: 0, width: 1, background: 'rgba(237,232,222,0.08)'}} />
        ))}
      </AbsoluteFill>
      <AbsoluteFill
        style={{
          transform: `translate(${sh.x}px, ${sh.y}px) rotate(${sh.r}deg) scale(${1 + exit * 5})`,
          transformOrigin: '540px 1080px',
          filter: `blur(${exit * 16}px)`,
        }}
      >
        {/* running total — the number is on screen from frame 0 */}
        <div
          style={{
            position: 'absolute',
            top: 280,
            width: '100%',
            textAlign: 'center',
            fontFamily: FONT,
            opacity: 1 - qT,
          }}
        >
          <div style={{fontWeight: 800, fontSize: 34, letterSpacing: 6, color: C.muted}}>ПРИШЛО ЗА ДЕНЬ</div>
          <div
            style={{
              fontWeight: 900,
              fontSize: 150,
              letterSpacing: -6,
              lineHeight: 1.05,
              color: C.gold,
              fontVariantNumeric: 'tabular-nums',
              transform: `scale(${1 + landings.reduce((a, l) => a + Math.max(0, 1 - Math.abs(f - l) / 6), 0) * 0.06})`,
            }}
          >
            {fmt(total)}
            {'\u00A0₽'}
          </div>
        </div>
        <AbsoluteFill
          style={{
            transform: `scale(${1 - recede * 0.12})`,
            filter: `blur(${recede * 14}px)`,
            opacity: 1 - recede * 0.72,
          }}
        >
          {NOTIFS.map((_, i) => (
            <Notif key={i} i={i} f={f} />
          ))}
        </AbsoluteFill>

        {/* the question */}
        <AbsoluteFill
          style={{
            display: 'flex',
            flexDirection: 'column',
            alignItems: 'center',
            justifyContent: 'center',
            gap: 20,
            paddingBottom: 60,
          }}
        >
          <SlamWord text="Сколько" at={Q} size={190} color={C.ivory} rotate={-8} />
          <SlamWord text="из этого —" at={B(5)} size={150} color={C.ivory} rotate={6} />
          <SlamWord text="налог?" at={B(6)} size={270} color={C.gold} from={3.2} rotate={-4} />
        </AbsoluteFill>
      </AbsoluteFill>
      {/* flash into the next scene */}
      <AbsoluteFill style={{background: C.bg, opacity: interpolate(f, [B(7.8), B(8)], [0, 1], clamp)}} />
    </AbsoluteFill>
  );
};
