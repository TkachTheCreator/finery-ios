import React from 'react';
import {C} from '../theme';

// Neutral phone (no Apple branding). Screen content is authored at 390x844 pt
// and scaled to fit. Front + back faces for 3D flips.
export const PHONE_RATIO = 2.1;

export const Phone: React.FC<{
  width: number;
  rotY?: number;
  rotX?: number;
  rotZ?: number;
  children: React.ReactNode;
  rim?: number; // 0..1 gold rim glow intensity
  back?: React.ReactNode;
  style?: React.CSSProperties;
}> = ({width, rotY = 0, rotX = 0, rotZ = 0, children, rim = 0, back, style}) => {
  const height = width * PHONE_RATIO;
  const bezel = width * 0.035;
  const radius = width * 0.15;
  const innerW = width - bezel * 2;
  const scale = innerW / 390;
  const innerH = height - bezel * 2;
  const face: React.CSSProperties = {
    position: 'absolute',
    inset: 0,
    borderRadius: radius,
    backfaceVisibility: 'hidden',
    WebkitBackfaceVisibility: 'hidden',
    overflow: 'hidden',
  };
  return (
    <div
      style={{
        width,
        height,
        position: 'relative',
        transformStyle: 'preserve-3d',
        transform: `rotateX(${rotX}deg) rotateY(${rotY}deg) rotateZ(${rotZ}deg)`,
        ...style,
      }}
    >
      {/* front */}
      <div
        style={{
          ...face,
          background: '#0D0B08',
          boxShadow: `inset 0 0 0 ${width * 0.006}px rgba(205,164,109,${0.35 + rim * 0.65}), 0 0 ${rim * 80}px rgba(205,164,109,${rim * 0.35})`,
        }}
      >
        <div
          style={{
            position: 'absolute',
            left: bezel,
            top: bezel,
            width: innerW,
            height: innerH,
            borderRadius: radius - bezel,
            overflow: 'hidden',
            background: C.bg,
          }}
        >
          <div style={{width: 390, height: innerH / scale, transform: `scale(${scale})`, transformOrigin: '0 0', position: 'relative'}}>
            {children}
          </div>
          {/* dynamic island */}
          <div
            style={{
              position: 'absolute',
              top: 11 * scale,
              left: '50%',
              width: 120 * scale,
              height: 35 * scale,
              marginLeft: -60 * scale,
              borderRadius: 20 * scale,
              background: '#000',
              zIndex: 60,
            }}
          />
        </div>
      </div>
      {/* back */}
      <div
        style={{
          ...face,
          transform: 'rotateY(180deg)',
          background: '#2B2620',
          boxShadow: `inset 0 0 0 ${width * 0.006}px rgba(205,164,109,${0.4 + rim * 0.6})`,
        }}
      >
        {/* camera bump */}
        <div
          style={{
            position: 'absolute',
            top: width * 0.05,
            left: width * 0.05,
            width: width * 0.4,
            height: width * 0.4,
            borderRadius: width * 0.1,
            background: '#221E19',
            border: `${width * 0.004}px solid rgba(237,232,222,0.12)`,
          }}
        >
          {[
            [0.1, 0.1],
            [0.1, 0.52],
            [0.52, 0.31],
          ].map(([y, x], i) => (
            <div
              key={i}
              style={{
                position: 'absolute',
                top: width * 0.4 * y,
                left: width * 0.4 * x,
                width: width * 0.15,
                height: width * 0.15,
                borderRadius: '50%',
                background: '#0A0907',
                border: `${width * 0.01}px solid #3A342C`,
              }}
            />
          ))}
        </div>
        {back}
      </div>
    </div>
  );
};
