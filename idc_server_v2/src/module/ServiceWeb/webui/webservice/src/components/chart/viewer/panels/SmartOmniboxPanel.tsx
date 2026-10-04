import React from 'react';

interface Props {
  input: string;
  suggestions: any[];
  isChartLoading: boolean;
  onInputChange: (val: string) => void;
  onSubmit: () => void;
  onSelect: (sug: any) => void;
}

export const SmartOmniboxPanel: React.FC<Props> = ({ input, suggestions, isChartLoading, onInputChange, onSubmit, onSelect }) => (
  <div className="card" style={{ padding: 15, display: 'flex', flexDirection: 'column', gap: 10 }}>
    <h4 style={{ textAlign: 'center', fontSize: 14 }}>스마트 검색</h4>
    <div style={{ position: 'relative' }}>
      <input
        type="text" value={input} onChange={e => onInputChange(e.target.value)}
        onKeyDown={e => { if (e.key === 'Enter') onSubmit(); }}
        disabled={isChartLoading} placeholder="예: 제1시설 101호 8월17일 1234"
        className="input"
      />
      {suggestions.length > 0 && (
        <div className="card" style={{ position: 'absolute', top: '110%', left: 0, right: 0, zIndex: 100, padding: 6 }}>
          {suggestions.slice(0, 12).map((sug, i) => (
            <div
              key={i} onClick={() => onSelect(sug)}
              style={{ padding: '8px 10px', cursor: 'pointer', borderRadius: 8, color: 'var(--primary)', fontSize: 13, fontWeight: 600, textAlign: 'left' }}
              onMouseEnter={(e) => (e.currentTarget.style.background = 'var(--primary-bg)')}
              onMouseLeave={(e) => (e.currentTarget.style.background = 'transparent')}
            >
              {sug.label}
            </div>
          ))}
        </div>
      )}
    </div>
    <div style={{ fontSize: 11, color: 'var(--text-secondary)', textAlign: 'center' }}>엔터키 입력 시 자동 파싱 적용</div>
  </div>
);
