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
  <div style={{ border: '2px solid #ffffff', padding: 15, display: 'flex', flexDirection: 'column', gap: 10 }}>
    <h4 style={{ margin: 0, textAlign: 'center', color: '#ff9800' }}>Smart Omnibox (스마트 검색)</h4>
    <div style={{ position: 'relative' }}>
      <input 
        type="text" value={input} onChange={e => onInputChange(e.target.value)}
        onKeyDown={e => { if (e.key === 'Enter') onSubmit(); }}
        disabled={isChartLoading} placeholder="예: 제1시설 101호 8월17일 1234"
        style={{ width: '100%', padding: 8, boxSizing: 'border-box', backgroundColor: '#333', color: '#fff', border: '1px solid #555', outline: 'none' }}
      />
      {suggestions.length > 0 && (
        <div style={{ position: 'absolute', top: '100%', left: 0, right: 0, backgroundColor: '#444', border: '1px solid #666', zIndex: 100 }}>
          {suggestions.slice(0, 12).map((sug, i) => (
            <div 
              key={i} onClick={() => onSelect(sug)}
              style={{ padding: '8px 12px', cursor: 'pointer', borderBottom: '1px solid #555', color: '#82b1ff', fontSize: 13, textAlign: 'left' }}
              onMouseEnter={(e) => (e.currentTarget.style.backgroundColor = '#555')}
              onMouseLeave={(e) => (e.currentTarget.style.backgroundColor = 'transparent')}
            >
              {sug.label}
            </div>
          ))}
        </div>
      )}
    </div>
    <div style={{ fontSize: 11, color: '#aaa', textAlign: 'center' }}>엔터키 입력 시 자동 파싱 적용</div>
  </div>
);