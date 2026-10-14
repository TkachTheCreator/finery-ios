import React from 'react';
import {C, FONT} from '../theme';
import {fmt} from '../anim';

// ---------- helpers
const hex = (h: string) => [1, 3, 5].map((i) => parseInt(h.slice(i, i + 2), 16));
export const mix = (a: string, b: string, t: number) => {
  const A = hex(a);
  const Bc = hex(b);
  return `rgb(${A.map((v, i) => Math.round(v * (1 - t) + Bc[i] * t)).join(',')})`;
};
// tile tint: ~38% of the section color over the warm bg (brief §4)
export const tint = (c: string) => mix(C.bg, c, 0.36);

const Rub = ' ₽';

// ---------- status bar (clean: 9:41, full signal, 100%)
export const StatusBar: React.FC<{dark?: boolean}> = ({dark = false}) => {
  const col = dark ? '#fff' : C.text;
  return (
    <div
      style={{
        position: 'absolute',
        top: 0,
        left: 0,
        right: 0,
        height: 54,
        display: 'flex',
        alignItems: 'center',
        justifyContent: 'space-between',
        padding: '6px 30px 0 44px',
        fontFamily: FONT,
        fontWeight: 800,
        fontSize: 17,
        color: col,
        zIndex: 50,
      }}
    >
      <span>9:41</span>
      <div style={{display: 'flex', gap: 6, alignItems: 'center'}}>
        <svg width="19" height="12" viewBox="0 0 19 12">
          {[0, 1, 2, 3].map((i) => (
            <rect key={i} x={i * 5} y={9 - i * 3} width="3.4" height={3 + i * 3} rx="1" fill={col} />
          ))}
        </svg>
        <svg width="17" height="12" viewBox="0 0 17 12">
          <path d="M8.5 11.5 L5.6 8.4 A4.2 4.2 0 0 1 11.4 8.4 Z" fill={col} />
          <path d="M3.3 6.1 A7.4 7.4 0 0 1 13.7 6.1" stroke={col} strokeWidth="1.9" fill="none" strokeLinecap="round" />
          <path d="M1 3.6 A10.8 10.8 0 0 1 16 3.6" stroke={col} strokeWidth="1.9" fill="none" strokeLinecap="round" />
        </svg>
        <div style={{display: 'flex', alignItems: 'center', gap: 1}}>
          <div style={{width: 25, height: 12, borderRadius: 4, border: `1.2px solid ${col}`, opacity: 0.9, padding: 1.5}}>
            <div style={{width: '100%', height: '100%', borderRadius: 2, background: col}} />
          </div>
          <div style={{width: 1.6, height: 4, background: col, borderRadius: 1, opacity: 0.5}} />
        </div>
      </div>
    </div>
  );
};

// ---------- tax ring
export const Ring: React.FC<{
  size: number;
  pct: number; // 0..1 shown
  stroke?: number;
  color?: string;
  track?: string;
  children?: React.ReactNode;
  marker?: number; // e.g. 0.8 limit warning notch
  markerColor?: string;
}> = ({size, pct, stroke = 6, color = C.text, track = 'rgba(26,21,16,0.12)', children, marker, markerColor}) => {
  const r = (size - stroke) / 2;
  const c = 2 * Math.PI * r;
  return (
    <div style={{width: size, height: size, position: 'relative'}}>
      <svg width={size} height={size} style={{transform: 'rotate(-90deg)', position: 'absolute'}}>
        <circle cx={size / 2} cy={size / 2} r={r} stroke={track} strokeWidth={stroke} fill="none" />
        <circle
          cx={size / 2}
          cy={size / 2}
          r={r}
          stroke={color}
          strokeWidth={stroke}
          fill="none"
          strokeLinecap="round"
          strokeDasharray={`${c * Math.max(0.0001, pct)} ${c}`}
        />
        {marker !== undefined ? (
          <line
            x1={size / 2 + (r - stroke * 1.1) * Math.cos(marker * 2 * Math.PI)}
            y1={size / 2 + (r - stroke * 1.1) * Math.sin(marker * 2 * Math.PI)}
            x2={size / 2 + (r + stroke * 1.1) * Math.cos(marker * 2 * Math.PI)}
            y2={size / 2 + (r + stroke * 1.1) * Math.sin(marker * 2 * Math.PI)}
            stroke={markerColor ?? C.expense}
            strokeWidth={stroke * 0.5}
            strokeLinecap="round"
          />
        ) : null}
      </svg>
      <div
        style={{
          position: 'absolute',
          inset: 0,
          display: 'flex',
          flexDirection: 'column',
          alignItems: 'center',
          justifyContent: 'center',
        }}
      >
        {children}
      </div>
    </div>
  );
};

// ---------- hero card
export const HeroCard: React.FC<{
  income: number;
  expense: number;
  tax: number;
  style?: React.CSSProperties;
  incomeColor?: string;
}> = ({income, expense, tax, style, incomeColor = C.ivory}) => {
  const profit = income - expense - tax;
  return (
    <div
      style={{
        width: 358,
        height: 162,
        borderRadius: 18,
        background: C.espresso,
        padding: '16px 18px',
        fontFamily: FONT,
        color: C.ivory,
        boxSizing: 'border-box',
        position: 'relative',
        overflow: 'hidden',
        ...style,
      }}
    >
      <div style={{fontSize: 13, fontWeight: 700, opacity: 0.6}}>Доход · октябрь</div>
      <div
        style={{
          fontSize: 44,
          fontWeight: 900,
          letterSpacing: -1.2,
          marginTop: 4,
          color: incomeColor,
          fontVariantNumeric: 'tabular-nums',
        }}
      >
        {fmt(income)}
        {Rub}
      </div>
      <div style={{height: 0.5, background: 'rgba(237,232,222,0.18)', margin: '12px 0 8px'}} />
      <div style={{display: 'flex', justifyContent: 'space-between', fontSize: 10, fontWeight: 700, opacity: 0.55}}>
        <span>расходы</span>
        <span>налог</span>
        <span>прибыль</span>
      </div>
      <div
        style={{
          display: 'flex',
          justifyContent: 'space-between',
          fontSize: 13,
          fontWeight: 800,
          marginTop: 2,
          fontVariantNumeric: 'tabular-nums',
        }}
      >
        <span>
          {fmt(expense)}
          {Rub}
        </span>
        <span>
          {fmt(tax)}
          {Rub}
        </span>
        <span>
          {fmt(profit)}
          {Rub}
        </span>
      </div>
    </div>
  );
};

// ---------- tiles
const Icon: React.FC<{color: string; children: React.ReactNode; size?: number}> = ({color, children, size = 30}) => (
  <div
    style={{
      width: size,
      height: size,
      borderRadius: size * 0.28,
      background: color,
      display: 'flex',
      alignItems: 'center',
      justifyContent: 'center',
    }}
  >
    {children}
  </div>
);

const Shimmer: React.FC<{phase: number}> = ({phase}) =>
  phase >= 0 && phase <= 1 ? (
    <div
      style={{
        position: 'absolute',
        top: '-60%',
        left: `${-40 + phase * 160}%`,
        width: '25%',
        height: '220%',
        transform: 'rotate(22deg)',
        background: 'linear-gradient(90deg, rgba(255,255,255,0), rgba(255,255,255,0.38), rgba(255,255,255,0))',
        pointerEvents: 'none',
      }}
    />
  ) : null;

export const Tile: React.FC<{
  w: number;
  h: number;
  color: string;
  title: string;
  sub?: string;
  icon?: React.ReactNode;
  children?: React.ReactNode;
  shimmer?: number;
  style?: React.CSSProperties;
}> = ({w, h, color, title, sub, icon, children, shimmer = -1, style}) => (
  <div
    style={{
      width: w,
      height: h,
      borderRadius: 18,
      background: tint(color),
      padding: 14,
      boxSizing: 'border-box',
      fontFamily: FONT,
      color: C.text,
      position: 'relative',
      overflow: 'hidden',
      ...style,
    }}
  >
    {icon}
    <div style={{fontSize: 15, fontWeight: 800, marginTop: icon ? 8 : 0}}>{title}</div>
    {sub ? <div style={{fontSize: 11.5, fontWeight: 700, color: C.muted, marginTop: 2}}>{sub}</div> : null}
    {children}
    <Shimmer phase={shimmer} />
  </div>
);

const Plus = () => (
  <svg width="14" height="14" viewBox="0 0 14 14">
    <path d="M7 2v10M2 7h10" stroke="#fff" strokeWidth="2.4" strokeLinecap="round" />
  </svg>
);
const Bulb = () => (
  <svg width="14" height="16" viewBox="0 0 14 16">
    <path d="M7 1a5 5 0 0 0-3 9v2h6v-2a5 5 0 0 0-3-9z M5 14h4" stroke="#fff" strokeWidth="1.8" fill="none" strokeLinecap="round" />
  </svg>
);
const Bars = () => (
  <svg width="16" height="14" viewBox="0 0 16 14">
    {[3, 7, 5, 11].map((hh, i) => (
      <rect key={i} x={i * 4} y={14 - hh} width="2.6" height={hh} rx="1" fill="#fff" />
    ))}
  </svg>
);
const People = () => (
  <svg width="18" height="14" viewBox="0 0 18 14">
    <circle cx="6" cy="4" r="3" fill="#fff" />
    <circle cx="13" cy="4.5" r="2.5" fill="#fff" opacity="0.8" />
    <path d="M0.5 13.5c0-3.5 2.5-5 5.5-5s5.5 1.5 5.5 5z" fill="#fff" />
    <path d="M12 8.6c3 0 5.5 1.4 5.5 4.9H13" fill="#fff" opacity="0.8" />
  </svg>
);

export type TileId = 'add' | 'tips' | 'tax' | 'dyn' | 'clients';

export const TileView: React.FC<{id: TileId; shimmer?: number; taxValue?: number; style?: React.CSSProperties}> = ({
  id,
  shimmer = -1,
  taxValue = 2398,
  style,
}) => {
  switch (id) {
    case 'add':
      return (
        <Tile
          w={173}
          h={96}
          color="#8A847C"
          title="Добавить"
          sub="операцию"
          shimmer={shimmer}
          style={style}
          icon={
            <Icon color={C.espresso} size={28}>
              <Plus />
            </Icon>
          }
        />
      );
    case 'tips':
      return (
        <Tile
          w={173}
          h={96}
          color={C.golden}
          title="Советы"
          sub="Всё в порядке"
          shimmer={shimmer}
          style={style}
          icon={
            <Icon color={C.golden} size={28}>
              <Bulb />
            </Icon>
          }
        />
      );
    case 'tax':
      return (
        <Tile w={358} h={96} color={C.amber} title="" shimmer={shimmer} style={style}>
          <div style={{display: 'flex', alignItems: 'center', gap: 14, marginTop: -2}}>
            <Ring size={66} pct={0.02} stroke={5}>
              <div style={{fontSize: 14, fontWeight: 900, lineHeight: 1}}>2%</div>
              <div style={{fontSize: 9, fontWeight: 800, color: C.muted}}>НПД</div>
            </Ring>
            <div>
              <div style={{fontSize: 12, fontWeight: 800, color: C.muted}}>Налоги · НПД</div>
              <div style={{fontSize: 24, fontWeight: 900, letterSpacing: -0.5, fontVariantNumeric: 'tabular-nums'}}>
                {fmt(taxValue)}
                {Rub}
              </div>
              <div style={{fontSize: 11, fontWeight: 700, color: C.muted}}>к уплате · до 28 ноября</div>
            </div>
          </div>
        </Tile>
      );
    case 'dyn':
      return (
        <Tile
          w={173}
          h={110}
          color={C.sage}
          title="Динамика"
          sub="за 6 месяцев"
          shimmer={shimmer}
          style={style}
          icon={
            <Icon color={C.sage} size={28}>
              <Bars />
            </Icon>
          }
        />
      );
    case 'clients':
      return (
        <Tile
          w={173}
          h={110}
          color={C.dusty}
          title="Клиенты"
          sub="Активных: 3"
          shimmer={shimmer}
          style={style}
          icon={
            <Icon color={C.dusty} size={28}>
              <People />
            </Icon>
          }
        />
      );
  }
};

// ---------- whole home screen (390 x 844 pt)
export const HomeScreen: React.FC<{
  income: number;
  tax: number;
  expense?: number;
  shimmer?: (id: TileId) => number;
  heroGlow?: number;
}> = ({income, tax, expense = 21050, shimmer}) => (
  <div style={{width: 390, height: 844, background: C.bg, position: 'relative', fontFamily: FONT}}>
    <StatusBar />
    <div style={{position: 'absolute', top: 62, left: 16, right: 16, display: 'flex', justifyContent: 'space-between'}}>
      <div>
        <div style={{fontSize: 24, fontWeight: 900, color: C.text, letterSpacing: -0.4}}>Главная</div>
        <div style={{fontSize: 13, fontWeight: 700, color: C.muted}}>октябрь 2026</div>
      </div>
      <svg width="24" height="24" viewBox="0 0 24 24" style={{marginTop: 6}}>
        <circle cx="12" cy="12" r="3.2" stroke={C.text} strokeWidth="1.8" fill="none" />
        <circle cx="12" cy="12" r="8.5" stroke={C.text} strokeWidth="1.8" fill="none" strokeDasharray="3.3 2.4" />
      </svg>
    </div>
    <div style={{position: 'absolute', top: 120, left: 16}}>
      <HeroCard income={income} expense={expense} tax={tax} />
    </div>
    <div style={{position: 'absolute', top: 294, left: 16, display: 'flex', gap: 12}}>
      <TileView id="add" shimmer={shimmer?.('add')} />
      <TileView id="tips" shimmer={shimmer?.('tips')} />
    </div>
    <div style={{position: 'absolute', top: 402, left: 16}}>
      <TileView id="tax" taxValue={tax} shimmer={shimmer?.('tax')} />
    </div>
    <div style={{position: 'absolute', top: 510, left: 16, display: 'flex', gap: 12}}>
      <TileView id="dyn" shimmer={shimmer?.('dyn')} />
      <TileView id="clients" shimmer={shimmer?.('clients')} />
    </div>
    {/* floating tab bar */}
    <div
      style={{
        position: 'absolute',
        bottom: 26,
        left: 22,
        right: 22,
        height: 62,
        borderRadius: 31,
        background: '#fff',
        border: `0.5px solid ${C.line}`,
        display: 'flex',
        alignItems: 'center',
        justifyContent: 'space-around',
        padding: '0 10px',
      }}
    >
      {[0, 1, 2, 3, 4, 5].map((i) => (
        <div
          key={i}
          style={{
            width: i === 0 ? 46 : 22,
            height: i === 0 ? 40 : 22,
            borderRadius: i === 0 ? 20 : 6,
            background: i === 0 ? C.espresso : 'transparent',
            border: i === 0 ? 'none' : `2px solid ${C.muted}`,
            opacity: i === 0 ? 1 : 0.55,
          }}
        />
      ))}
    </div>
  </div>
);

// ---------- quick input sheet ("Что добавить?")
export const QuickSheet: React.FC<{text: string; caret: boolean; pressDone?: number}> = ({text, caret, pressDone = 0}) => (
  <div
    style={{
      width: 362,
      borderRadius: 26,
      background: '#fff',
      border: `0.5px solid ${C.line}`,
      padding: 18,
      boxSizing: 'border-box',
      fontFamily: FONT,
    }}
  >
    <div style={{display: 'flex', alignItems: 'center', gap: 10}}>
      <div style={{width: 30, height: 30, borderRadius: 9, background: C.plum, display: 'flex', alignItems: 'center', justifyContent: 'center'}}>
        <svg width="14" height="16" viewBox="0 0 14 16">
          <path d="M8 1L2 9h5l-1 6 6-8H7z" fill="#fff" />
        </svg>
      </div>
      <div style={{fontSize: 19, fontWeight: 900, color: C.text}}>Что добавить?</div>
    </div>
    <div style={{fontSize: 12.5, fontWeight: 700, color: C.muted, marginTop: 6}}>Например: «расход 500 такси»</div>
    <div
      style={{
        marginTop: 12,
        height: 48,
        borderRadius: 14,
        background: C.bg,
        border: `1px solid ${C.line}`,
        display: 'flex',
        alignItems: 'center',
        padding: '0 14px',
        fontSize: 20,
        fontWeight: 800,
        color: C.text,
      }}
    >
      {text}
      <span style={{width: 2, height: 24, background: C.text, marginLeft: 2, opacity: caret ? 1 : 0}} />
    </div>
    <div style={{display: 'flex', gap: 10, marginTop: 12}}>
      <div
        style={{
          flex: 1,
          height: 46,
          borderRadius: 14,
          border: `1px solid ${C.line}`,
          display: 'flex',
          alignItems: 'center',
          justifyContent: 'center',
          fontSize: 16,
          fontWeight: 800,
          color: C.espresso,
        }}
      >
        Отмена
      </div>
      <div
        style={{
          flex: 1,
          height: 46,
          borderRadius: 14,
          background: C.espresso,
          display: 'flex',
          alignItems: 'center',
          justifyContent: 'center',
          fontSize: 16,
          fontWeight: 800,
          color: '#fff',
          transform: `scale(${1 - pressDone * 0.06})`,
        }}
      >
        Готово
      </div>
    </div>
  </div>
);

export const Check: React.FC<{size: number; progress: number; color?: string; bg?: string}> = ({
  size,
  progress,
  color = '#fff',
  bg = C.success,
}) => (
  <svg width={size} height={size} viewBox="0 0 40 40">
    <circle cx="20" cy="20" r="20" fill={bg} />
    <path
      d="M11 20.5l6 6 12-13"
      stroke={color}
      strokeWidth="4.2"
      fill="none"
      strokeLinecap="round"
      strokeLinejoin="round"
      strokeDasharray="30"
      strokeDashoffset={30 * (1 - progress)}
    />
  </svg>
);

export const Toast: React.FC<{check: number}> = ({check}) => (
  <div
    style={{
      width: 362,
      borderRadius: 22,
      background: '#fff',
      border: `0.5px solid ${C.line}`,
      padding: '14px 16px',
      boxSizing: 'border-box',
      display: 'flex',
      alignItems: 'center',
      gap: 12,
      fontFamily: FONT,
    }}
  >
    <Check size={38} progress={check} />
    <div>
      <div style={{fontSize: 15.5, fontWeight: 900, color: C.text}}>Записал доход 30 000 ₽</div>
      <div style={{fontSize: 12.5, fontWeight: 700, color: C.muted}}>Реклама · отложи 1 200 ₽ на налог</div>
    </div>
  </div>
);
