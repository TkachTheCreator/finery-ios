import React from 'react';
import {Composition} from 'remotion';
import {Showreel} from './Showreel';
import {DURATION, FPS} from './theme';

export const RemotionRoot: React.FC = () => (
  <Composition id="FineryShowreel" component={Showreel} durationInFrames={DURATION} fps={FPS} width={1080} height={1920} />
);
