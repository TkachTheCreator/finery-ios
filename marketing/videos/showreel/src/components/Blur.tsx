import React, {useId} from 'react';

// Directional motion blur via SVG filter (stdDeviation x y)
export const MotionBlur: React.FC<{
  x?: number;
  y?: number;
  children: React.ReactNode;
  style?: React.CSSProperties;
}> = ({x = 0, y = 0, children, style}) => {
  const id = 'mb' + useId().replace(/:/g, '');
  const active = Math.abs(x) > 0.3 || Math.abs(y) > 0.3;
  return (
    <>
      {active ? (
        <svg width={0} height={0} style={{position: 'absolute'}}>
          <filter id={id} x="-50%" y="-50%" width="200%" height="200%">
            <feGaussianBlur stdDeviation={`${Math.abs(x)} ${Math.abs(y)}`} />
          </filter>
        </svg>
      ) : null}
      <div style={{...style, filter: active ? `url(#${id})` : undefined}}>{children}</div>
    </>
  );
};
