import React from 'react';

/** 그라디언트 모노그램 — 앱 쪽 AppMonogram과 동일한 브랜드 마크 */
export const Monogram: React.FC<{ size?: number }> = ({ size = 32 }) => (
  <div
    style={{
      width: size, height: size, borderRadius: size * 0.28,
      background: 'linear-gradient(135deg, var(--primary-light, #5c8def), var(--primary-dark, #1e4fbd))',
      color: '#fff',
      display: 'flex', alignItems: 'center', justifyContent: 'center',
      fontWeight: 800, fontSize: size * 0.42, letterSpacing: -1,
      boxShadow: `0 ${size * 0.14}px ${size * 0.32}px -${size * 0.1}px rgba(46,107,239,0.45)`,
      flexShrink: 0,
    }}
  >
    ic
  </div>
);

/** 2색 워드마크 — "ID"(기본 텍스트색) + "Cool"(브랜드 블루) */
export const Wordmark: React.FC<{ size?: number }> = ({ size = 17 }) => (
  <span style={{ fontSize: size, fontWeight: 800, letterSpacing: -0.3 }}>
    ID<span style={{ color: 'var(--primary)' }}>Cool</span>
  </span>
);
