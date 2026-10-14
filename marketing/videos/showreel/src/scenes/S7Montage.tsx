import React from 'react';
import {AbsoluteFill, interpolate, useCurrentFrame} from 'remotion';
import {C, FONT, B} from '../theme';
import {SPR, clamp, eout, fmt, shake, sp} from '../anim';
import {SlamWord} from '../components/Kinetic';
import {GOLD_PETAL} from '../components/logoPaths';

// beats 44..50
const L = (beat: number) => B(beat - 44);

const Wipe: React.FC<{kind: number; t: number; color: string; children: React.ReactNode}> = ({kind, t, color, children}) => {
  let clip = 'none';
  if (kind === 0) clip = `circle(${t * 130}% at 50% 100%)`;
  if (kind === 1) clip = `polygon(0 0, ${t * 220}% 0, ${t * 220 - 100}% 100%, 0 100%)`;
  if (kind === 3) clip = `inset(0 0 ${(1 - t) * 100}% 0)`;
  return (
    <AbsoluteFill style={{background: color, clipPath: kind === 2 ? undefined : clip}}>
      {kind === 2 ? (
        <AbsoluteFill style={{display: 'flex', alignItems: 'center', justifyContent: 'center'}}>
          <svg width="1000" height="1000" viewBox="300 250 460 560" style={{transform: `scale(${t * 7}) rotate(${(1 - t) * 90}deg)`, position: 'absolute'}}>
            <path d={GOLD_PETAL} fill={color} />
          </svg>
          <AbsoluteFill style={{opacity: t >= 1 ? 1 : 0, background: color}} />
        </AbsoluteFill>
      ) : null}
      <AbsoluteFill style={{opacity: kind === 2 ? interpolate(t, [0.5, 1], [0, 1], clamp) : 1}}>{children}</AbsoluteFill>
    </AbsoluteFill>
  );
};

const Clients: React.FC<{f: number}> = ({f}) => (
  <div style={{position: 'absolute', top: 720, left: 110, right: 110, display: 'flex', flexDirection: 'column', gap: 22}}>
    {[
      ['Александр', 6000],
      ['Алексей', 3500],
      ['Олег', 1250],
    ].map(([n, v], i) => {
      const s = sp(f, 3 + i * 3, SPR.punch);
      return (
        <div
          key={i}
          style={{
            height: 128,
            borderRadius: 32,
            background: C.bg,
            display: 'flex',
            alignItems: 'center',
            padding: '0 34px',
            gap: 24,
            fontFamily: FONT,
            transform: `translateX(${(1 - s) * (i % 2 ? 900 : -900)}px)`,
          }}
        >
          <div style={{width: 70, height: 70, borderRadius: 35, background: C.sage, color: '#fff', fontWeight: 900, fontSize: 36, display: 'flex', alignItems: 'center', justifyContent: 'center'}}>
            {String(n)[0]}
          </div>
          <div style={{fontWeight: 900, fontSize: 44, color: C.text, flex: 1}}>{n}</div>
          <div style={{fontWeight: 900, fontSize: 44, color: C.success}}>
            {fmt(Number(v))}
            {' ₽'}
          </div>
        </div>
      );
    })}
  </div>
);

const Donut: React.FC<{f: number}> = ({f}) => {
  const segs = [
    {v: 0.42, c: C.cream},
    {v: 0.24, c: C.gold},
    {v: 0.19, c: C.espresso},
    {v: 0.15, c: '#E3B9A9'},
  ];
  const t = eout(f, 2, 26);
  const r = 200;
  const circ = 2 * Math.PI * r;
  let acc = 0;
  return (
    <div style={{position: 'absolute', left: 540 - 260, top: 680, width: 520, height: 520}}>
      <svg width="520" height="520" style={{transform: `rotate(${-90 + (1 - t) * -120}deg)`}}>
        {segs.map((s, i) => {
          const len = Math.max(0, Math.min(s.v, t - acc)) * circ;
          const off = acc * circ;
          acc += s.v;
          return (
            <circle
              key={i}
              cx="260"
              cy="260"
              r={r}
              fill="none"
              stroke={s.c}
              strokeWidth="96"
              strokeDasharray={`${Math.max(0, len - 6)} ${circ}`}
              strokeDashoffset={-off}
            />
          );
        })}
      </svg>
      <div style={{position: 'absolute', inset: 0, display: 'flex', alignItems: 'center', justifyContent: 'center', fontFamily: FONT, fontWeight: 900, fontSize: 64, color: C.cream}}>
        {fmt(21050 * t)}
        {' ₽'}
      </div>
    </div>
  );
};

const Widgets: React.FC<{f: number}> = ({f}) => {
  const a = sp(f, 2, SPR.punch);
  const b2 = sp(f, 7, SPR.punch);
  return (
    <div style={{position: 'absolute', top: 700, left: 0, right: 0, display: 'flex', justifyContent: 'center', gap: 40, fontFamily: FONT}}>
      <div
        style={{
          width: 380,
          height: 380,
          borderRadius: 80,
          background: C.bg,
          padding: 40,
          boxSizing: 'border-box',
          transform: `scale(${a}) rotate(${(1 - a) * -20}deg)`,
          display: 'flex',
          flexDirection: 'column',
          justifyContent: 'space-between',
        }}
      >
        <div style={{fontSize: 36, fontWeight: 800, color: C.muted}}>Доход · октябрь</div>
        <div style={{fontSize: 74, fontWeight: 900, color: C.text, letterSpacing: -2}}>59 950 ₽</div>
        <div style={{fontSize: 32, fontWeight: 800, color: C.amber}}>налог 2 398 ₽</div>
      </div>
      <div
        style={{
          width: 380,
          height: 380,
          borderRadius: 80,
          background: C.espresso,
          transform: `scale(${b2}) rotate(${(1 - b2) * 20}deg)`,
          display: 'flex',
          flexDirection: 'column',
          alignItems: 'center',
          justifyContent: 'center',
          gap: 18,
        }}
      >
        <div style={{width: 130, height: 130, borderRadius: 65, background: C.gold, display: 'flex', alignItems: 'center', justifyContent: 'center'}}>
          <svg width="64" height="64" viewBox="0 0 14 14">
            <path d="M7 2v10M2 7h10" stroke={C.espresso} strokeWidth="2.4" strokeLinecap="round" />
          </svg>
        </div>
        <div style={{fontSize: 44, fontWeight: 900, color: C.cream}}>Добавить</div>
      </div>
    </div>
  );
};

const Report: React.FC<{f: number}> = ({f}) => {
  const s = sp(f, 2, SPR.punch);
  return (
    <div
      style={{
        position: 'absolute',
        left: 540 - 270,
        top: 660,
        width: 540,
        height: 700,
        borderRadius: 34,
        background: C.bg,
        padding: 48,
        boxSizing: 'border-box',
        fontFamily: FONT,
        transform: `translateY(${(1 - s) * 900}px) rotate(${(1 - s) * 25 - 4}deg)`,
      }}
    >
      <div style={{display: 'flex', justifyContent: 'space-between', alignItems: 'center'}}>
        <div style={{fontSize: 40, fontWeight: 900, color: C.text}}>Отчёт</div>
        <div style={{fontSize: 30, fontWeight: 900, color: '#fff', background: C.expense, borderRadius: 12, padding: '6px 16px'}}>PDF</div>
      </div>
      <div style={{fontSize: 30, fontWeight: 700, color: C.muted, marginTop: 6}}>октябрь 2026</div>
      {[0.9, 0.7, 0.8, 0.55, 0.75, 0.6, 0.85].map((w, i) => (
        <div key={i} style={{display: 'flex', justifyContent: 'space-between', marginTop: 34}}>
          <div style={{height: 20, width: `${w * 60}%`, borderRadius: 10, background: C.line}} />
          <div style={{height: 20, width: '22%', borderRadius: 10, background: i % 3 === 1 ? 'rgba(192,78,53,0.35)' : 'rgba(26,107,60,0.35)'}} />
        </div>
      ))}
    </div>
  );
};

const STUTTER = [
  {t: 'Boosty.', bg: C.cream, fg: C.espresso, r: -4},
  {t: 'Донаты.', bg: C.gold, fg: C.espresso, r: 3},
  {t: 'Реклама.', bg: C.espresso, fg: C.cream, r: -2},
  {t: 'Заказы.', bg: C.expense, fg: C.cream, r: 4},
];

export const S7Montage: React.FC = () => {
  const f = useCurrentFrame();
  const sh = shake(f, [0, L(45), L(46), L(47), L(48), L(48.5), L(49), L(49.5)], 26, 'mont');
  const beats = [
    {bg: C.sage, word: 'Клиенты.', body: <Clients f={f} />},
    {bg: C.terra, word: 'Категории.', body: <Donut f={f - L(45)} />},
    {bg: C.plum, word: 'Виджеты.', body: <Widgets f={f - L(46)} />},
    {bg: C.espresso, word: 'Отчёт в PDF.', body: <Report f={f - L(47)} />},
  ];
  const i = Math.floor(f / B(1));
  return (
    <AbsoluteFill style={{background: C.bg, overflow: 'hidden', transform: `translate(${sh.x}px, ${sh.y}px) rotate(${sh.r}deg)`}}>
      {beats.map((b, k) => {
        const start = L(44 + k) - (k === 0 ? 0 : 6);
        if (f < start || i > k + 1 || f >= L(48)) return null;
        const t = k === 0 ? 1 : eout(f, start, start + 9);
        return (
          <Wipe key={k} kind={k} t={t} color={b.bg}>
            <AbsoluteFill style={{transform: `scale(${1 + (f - start) * 0.002})`}}>
              <div style={{position: 'absolute', top: 330, left: 0, right: 0, display: 'flex', justifyContent: 'center'}}>
                <SlamWord text={b.word} at={start + 4} size={k === 3 ? 140 : 160} color={C.cream} from={1.9} rotate={k % 2 ? 4 : -4} />
              </div>
              {b.body}
            </AbsoluteFill>
          </Wipe>
        );
      })}
      {STUTTER.map((s, k) => {
        const at = L(48 + k * 0.5);
        if (f < at || f >= at + B(0.5)) return null;
        return (
          <AbsoluteFill key={k} style={{background: s.bg, display: 'flex', alignItems: 'center', justifyContent: 'center'}}>
            <SlamWord text={s.t} at={at} size={200} color={s.fg} from={1.6} rotate={s.r * 3} />
          </AbsoluteFill>
        );
      })}
    </AbsoluteFill>
  );
};
