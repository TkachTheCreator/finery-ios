import '@fontsource/nunito/400.css';
import '@fontsource/nunito/600.css';
import '@fontsource/nunito/700.css';
import '@fontsource/nunito/800.css';
import '@fontsource/nunito/900.css';

// Palette — from marketing/FINERY_BRAND_BRIEF.md §4 (current app palette)
export const C = {
  bg: '#FAF8F3',
  bg2: '#F0EBE2',
  card: '#FFFFFF',
  line: '#E8E2D9',
  text: '#1A1A1A',
  muted: '#6B6560',
  espresso: '#1A1510',
  espressoDeep: '#120F0A',
  ivory: '#EDE8DE',
  cream: '#F2EADE',
  gold: '#CDA46D',
  expense: '#C04E35',
  success: '#1A6B3C',
  warn: '#9B6B00',
  // section colors
  sage: '#5A7D68',
  dusty: '#4A6E8A',
  amber: '#9B7830',
  terra: '#A05848',
  plum: '#7A5492',
  golden: '#9B8825',
};

export const FONT = "'Nunito', 'SF Pro Rounded', system-ui, sans-serif";

// Timing: 120 BPM @ 60 fps -> 1 beat = 30 frames
export const FPS = 60;
export const BEAT = 30;
export const B = (beats: number) => Math.round(beats * BEAT);
export const DURATION = B(58); // 29 s

// Reels/TikTok safe zone for text (PROMPT_VIDEO_V2 §2.4)
export const SAFE = {top: 270, bottom: 1920 - 380, side: 64};
