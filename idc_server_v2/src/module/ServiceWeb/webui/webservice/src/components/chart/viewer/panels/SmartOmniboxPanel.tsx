import React from 'react';

/** 드롭다운에 한 번에 보여줄 줄 수. */
const VISIBLE_COUNT = 12;

interface Props {
  input: string;
  suggestions: any[];
  isChartLoading: boolean;
  /** 키보드로 짚고 있는 줄. */
  activeIndex: number;
  onActiveIndexChange: (idx: number) => void;
  onInputChange: (val: string) => void;
  onSubmit: () => void;
  onSelect: (sug: any) => void;
}

export const SmartOmniboxPanel: React.FC<Props> = ({ input, suggestions, isChartLoading, activeIndex, onActiveIndexChange, onInputChange, onSubmit, onSelect }) => {
  // 목록이 떠 있는데 손을 마우스로 옮겨야만 고를 수 있으면 검색창의 의미가 줄어든다.
  // 위아래로 짚고 엔터로 고른다. Esc 는 목록을 닫는 대신 입력을 비운다.
  const handleKeyDown = (e: React.KeyboardEvent<HTMLInputElement>) => {
    const shown = suggestions.slice(0, VISIBLE_COUNT);
    if (e.key === 'ArrowDown' && shown.length > 0) {
      e.preventDefault();
      onActiveIndexChange((activeIndex + 1) % shown.length);
    } else if (e.key === 'ArrowUp' && shown.length > 0) {
      e.preventDefault();
      onActiveIndexChange((activeIndex - 1 + shown.length) % shown.length);
    } else if (e.key === 'Enter') {
      onSubmit();
    } else if (e.key === 'Escape') {
      onInputChange('');
    }
  };

  return (
  <div className="card" style={{ padding: 15, display: 'flex', flexDirection: 'column', gap: 10 }}>
    <h4 style={{ textAlign: 'center', fontSize: 14 }}>스마트 검색</h4>
    <div style={{ position: 'relative' }}>
      <input
        type="text" value={input} onChange={e => onInputChange(e.target.value)}
        onKeyDown={handleKeyDown}
        disabled={isChartLoading} placeholder="예: 제1시설 101호 8월17일 1234"
        className="input"
      />
      {suggestions.length > 0 && (
        <div className="card" style={{ position: 'absolute', top: '110%', left: 0, right: 0, zIndex: 100, padding: 6 }}>
          {suggestions.slice(0, VISIBLE_COUNT).map((sug, i) => (
            <div
              key={i} onClick={() => onSelect(sug)}
              onMouseEnter={() => onActiveIndexChange(i)}
              style={{
                padding: '8px 10px', cursor: 'pointer', borderRadius: 8,
                color: 'var(--primary)', fontSize: 13, fontWeight: 600, textAlign: 'left',
                background: i === activeIndex ? 'var(--primary-bg)' : 'transparent',
              }}
            >
              {sug.label}
            </div>
          ))}
        </div>
      )}
    </div>
    <div style={{ fontSize: 11, color: 'var(--text-secondary)', textAlign: 'center' }}>
      {suggestions.length > 0 ? '↑↓ 로 고르고 엔터' : '엔터키 입력 시 자동 파싱 적용'}
    </div>
  </div>
  );
};
