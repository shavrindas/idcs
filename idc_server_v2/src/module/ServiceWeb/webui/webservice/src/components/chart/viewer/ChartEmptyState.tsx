import React from 'react';

/**
 * 차트가 비어 있을 때 그 자리를 대신 채우는 안내.
 *
 * 예전에는 아무것도 고르지 않은 상태에서 화면의 3분의 2가 흰 사각형이었다.
 * 처음 들어온 사람은 그것이 '아직 고르지 않아서' 비어 있는 것인지, '불러오는
 * 중'인지, '고장난 것'인지 알 방법이 없다. 셋은 해야 할 일이 전혀 다르다.
 *
 * 그래서 비어 있는 이유를 말하고, 다음에 누를 곳을 알려 준다.
 */
export type EmptyReason = 'pick-facility' | 'pick-room' | 'no-mapping' | 'no-data';

/** 지금 어디까지 왔는지. 차례를 보여 줘야 다음 할 일이 보인다. */
const STEPS = ['시설 고르기', '호실 고르기', '차트 보기'];

const stepIndexOf = (reason: EmptyReason) => {
  if (reason === 'pick-facility') return 0;
  if (reason === 'pick-room') return 1;
  return 2;
};

const MESSAGES: Record<EmptyReason, { title: string; hint: string }> = {
  'pick-facility': {
    title: '볼 시설을 먼저 고르세요',
    hint: '오른쪽 ‘조회 범위 설정’ 에서 시설을 고르면 호실 목록이 나옵니다.',
  },
  'pick-room': {
    title: '호실을 고르세요',
    hint: '호실을 고르면 그 호실의 맵핑이 자동으로 걸리고 차트가 그려집니다.',
  },
  'no-mapping': {
    title: '이 호실에는 등록된 맵핑이 없습니다',
    hint: '차트로 그릴 항목이 아직 묶여 있지 않습니다. 관리자에게 맵핑 등록을 요청하세요.',
  },
  'no-data': {
    title: '이 구간에는 기록이 없습니다',
    hint: '기준 시각을 옮기거나 ‘지금부터 거슬러’ 에서 다른 구간을 골라 보세요.',
  },
};

export const ChartEmptyState: React.FC<{ reason: EmptyReason; compact?: boolean }> = ({ reason, compact = false }) => {
  const { title, hint } = MESSAGES[reason];

  // 위아래 두 차트가 같이 비면 같은 안내가 두 번 적힌다. 두 번 읽어도 알게 되는
  // 것은 없고, 화면만 길어진다. 아래쪽은 '여기도 비어 있다'만 조용히 알린다.
  if (compact) {
    return (
      <div style={{ flex: 1, display: 'flex', alignItems: 'center', justifyContent: 'center', padding: 20 }}>
        <span style={{ fontSize: 13, color: 'var(--text-secondary)' }}>{title}</span>
      </div>
    );
  }

  const current = stepIndexOf(reason);
  // 맵핑이 없는 것은 고르는 차례의 문제가 아니라 설정의 문제다. 차례를 보여 주면
  // 더 눌러 보면 될 것처럼 읽혀서 오히려 헷갈린다.
  const showSteps = reason !== 'no-mapping';

  return (
    <div
      style={{
        flex: 1, display: 'flex', flexDirection: 'column',
        alignItems: 'center', justifyContent: 'center',
        gap: 14, padding: 24, textAlign: 'center',
      }}
    >
      <svg width="52" height="52" viewBox="0 0 24 24" fill="none" aria-hidden="true"
        stroke="var(--border)" strokeWidth="1.6" strokeLinecap="round" strokeLinejoin="round">
        <path d="M3 3v16a2 2 0 0 0 2 2h16" />
        <path d="M7 15l3.5-4 3 3L20 7" />
      </svg>

      <div>
        <div style={{ fontSize: 15, fontWeight: 700, color: 'var(--text)' }}>{title}</div>
        <div style={{ fontSize: 13, color: 'var(--text-secondary)', marginTop: 6, maxWidth: 380 }}>{hint}</div>
      </div>

      {showSteps && (
        <ol style={{ display: 'flex', gap: 8, listStyle: 'none', margin: 0, padding: 0, flexWrap: 'wrap', justifyContent: 'center' }}>
          {STEPS.map((step, i) => (
            <li
              key={step}
              style={{
                display: 'inline-flex', alignItems: 'center', gap: 6,
                padding: '5px 12px', borderRadius: 999, fontSize: 12, fontWeight: 600,
                // 지난 차례는 옅게, 지금 차례만 또렷하게.
                background: i === current ? 'var(--primary-bg)' : 'transparent',
                color: i === current ? 'var(--primary)' : 'var(--text-secondary)',
                border: `1px solid ${i === current ? 'transparent' : 'var(--border)'}`,
              }}
            >
              <span
                style={{
                  display: 'inline-flex', alignItems: 'center', justifyContent: 'center',
                  width: 18, height: 18, borderRadius: '50%', fontSize: 11,
                  background: i < current ? 'var(--primary)' : i === current ? 'var(--primary)' : 'var(--border)',
                  color: i <= current ? '#fff' : 'var(--text-secondary)',
                }}
              >
                {i < current ? '✓' : i + 1}
              </span>
              {step}
            </li>
          ))}
        </ol>
      )}
    </div>
  );
};
