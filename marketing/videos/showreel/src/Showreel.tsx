import React, {useEffect, useState} from 'react';
import {AbsoluteFill, Audio, Sequence, continueRender, delayRender, staticFile} from 'remotion';
import {B, C} from './theme';
import {S1Hook} from './scenes/S1Hook';
import {S2Pain} from './scenes/S2Pain';
import {S3Brand} from './scenes/S3Brand';
import {S4Quick} from './scenes/S4Quick';
import {S5Numbers} from './scenes/S5Numbers';
import {S6OneScreen} from './scenes/S6OneScreen';
import {S7Montage} from './scenes/S7Montage';
import {S8Outro} from './scenes/S8Outro';

// [component, startBeat, endBeat]
const SCENES: [React.FC, number, number][] = [
  [S1Hook, 0, 8], //  боль: деньги отовсюду -> вопрос
  [S2Pain, 8, 16], // боль: считать руками, 28-е; поворот
  [S3Brand, 16, 20], // DROP: Finery
  [S4Quick, 20, 28], // решение: два тапа + одна фраза
  [S5Numbers, 28, 36], // доход, налог, лимит
  [S6OneScreen, 36, 44], // всё на одном экране
  [S7Montage, 44, 50], // монтаж по долям
  [S8Outro, 50, 58], // CTA
];

const useFonts = () => {
  const [handle] = useState(() => delayRender('fonts'));
  useEffect(() => {
    Promise.all(
      [400, 600, 700, 800, 900].map((w) => document.fonts.load(`${w} 40px Nunito`, 'Ёё ₽ 0123 Finery')),
    ).then(() => document.fonts.ready).then(() => continueRender(handle));
  }, [handle]);
};

export const Showreel: React.FC = () => {
  useFonts();
  return (
    <AbsoluteFill style={{background: C.espresso}}>
      {SCENES.map(([Comp, a, b], i) => (
        <Sequence key={i} from={B(a)} durationInFrames={B(b) - B(a)}>
          <Comp />
        </Sequence>
      ))}
      <Audio src={staticFile('audio/finery_showreel.wav')} />
    </AbsoluteFill>
  );
};
