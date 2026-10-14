import {Easing, interpolate, spring} from 'remotion';
import {noise2D} from '@remotion/noise';
import {FPS} from './theme';

export const clamp = {extrapolateLeft: 'clamp', extrapolateRight: 'clamp'} as const;

// App springs (brief §5): response/damping -> remotion config approximations
export const SPR = {
  micro: {damping: 13, stiffness: 320, mass: 0.6},
  card: {damping: 15, stiffness: 180, mass: 0.8},
  page: {damping: 20, stiffness: 140, mass: 0.9},
  punch: {damping: 9, stiffness: 260, mass: 0.7}, // overshoot for slams
  soft: {damping: 26, stiffness: 90, mass: 1},
};

export const sp = (frame: number, start: number, config = SPR.card, durationInFrames?: number) =>
  spring({frame: frame - start, fps: FPS, config, durationInFrames});

export const lin = (frame: number, a: number, b: number, from = 0, to = 1) =>
  interpolate(frame, [a, b], [from, to], clamp);

export const eio = (frame: number, a: number, b: number, from = 0, to = 1) =>
  interpolate(frame, [a, b], [from, to], {...clamp, easing: Easing.bezier(0.65, 0, 0.35, 1)});

export const eout = (frame: number, a: number, b: number, from = 0, to = 1) =>
  interpolate(frame, [a, b], [from, to], {...clamp, easing: Easing.bezier(0.16, 1, 0.3, 1)});

export const ein = (frame: number, a: number, b: number, from = 0, to = 1) =>
  interpolate(frame, [a, b], [from, to], {...clamp, easing: Easing.bezier(0.7, 0, 0.84, 0)});

// decaying hit envelope (1 at start, -> 0)
export const hit = (frame: number, start: number, len = 14) => {
  const t = frame - start;
  if (t < 0 || t > len) return 0;
  return Math.exp(-t / (len / 4));
};

// camera shake from several hit times
export const shake = (frame: number, hits: number[], amp = 18, seed = 'a') => {
  let e = 0;
  for (const h of hits) e += hit(frame, h, 16);
  return {
    x: noise2D(seed + 'x', frame * 0.35, 0) * amp * e,
    y: noise2D(seed + 'y', 0, frame * 0.35) * amp * e,
    r: noise2D(seed + 'r', frame * 0.3, 1) * amp * 0.05 * e,
  };
};

export const fmt = (n: number) =>
  Math.round(n)
    .toString()
    .replace(/\B(?=(\d{3})+(?!\d))/g, '\u00A0');
