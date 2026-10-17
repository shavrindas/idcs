import React from 'react';

/** 브랜드 마크 — 앱의 런처 아이콘과 같은 그림을 쓴다.
 *
 * 전에는 'ic' 두 글자를 그라디언트 사각형에 얹은 자리표시자였다. 앱이 실제
 * 로고로 바뀐 뒤로는 같은 제품인데 앱과 웹의 표식이 서로 달랐다. */
export const Monogram: React.FC<{ size?: number }> = ({ size = 32 }) => (
  <img
    src="/webui/logo.png"
    alt=""
    width={size}
    height={size}
    style={{
      borderRadius: '50%',
      display: 'block',
      flexShrink: 0,
      boxShadow: `0 ${size * 0.12}px ${size * 0.3}px -${size * 0.1}px rgba(46,107,239,0.4)`,
    }}
  />
);

/** 2색 워드마크 — "ID"(기본 텍스트색) + "Cool"(브랜드 블루) */
export const Wordmark: React.FC<{ size?: number }> = ({ size = 17 }) => (
  <span style={{ fontSize: size, fontWeight: 800, letterSpacing: -0.3 }}>
    ID<span style={{ color: 'var(--primary)' }}>Cool</span>
  </span>
);
