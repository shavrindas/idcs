import React from 'react';

interface Props {
  showInfo: boolean;
  showGrid: boolean;
  targetDate: string;
  isChartLoading: boolean;
  onCopy: () => void;
  onToggleInfo: () => void;
  onToggleGrid: () => void;
  onOneHourView: () => void;
  onDateChange: (val: string) => void;
  yBuffer: number | 'auto';
  onYBufferChange: (val: number | 'auto') => void;
}

/** y축 위아래 여백 선택지. '자동' 은 구간 폭의 10%. */
const Y_BUFFER_OPTIONS: { value: number | 'auto'; label: string }[] = [
  { value: 'auto', label: '자동' },
  { value: 0, label: '없음' },
  { value: 10, label: '±10' },
  { value: 50, label: '±50' },
  { value: 100, label: '±100' },
];

/**
 * 메인 차트 위의 도구 모음.
 *
 * 단추가 여섯 개 한 줄로 늘어서 있었고, 그중 제일 진한 파랑이 '정보'와
 * '그리드' 였다. 둘 다 켜고 끄는 표시일 뿐인데 화면에서 가장 큰 목소리를
 * 가져가고 있었던 셈이다. 지금은 세 묶음으로 나눈다:
 *
 *   보기 설정(정보·그리드) | 구간(1시간 뷰·여백) | 기준 시각
 *
 * 그리고 실제로 값을 바꾸는 것 — 기준 시각 — 만 또렷하게 둔다.
 */
export const TopToolBar: React.FC<Props> = ({ showInfo, showGrid, targetDate, isChartLoading, onCopy, onToggleInfo, onToggleGrid, onOneHourView, onDateChange, yBuffer, onYBufferChange }) => (
  <div className="card" style={{ padding: 10, display: 'flex', justifyContent: 'space-between', alignItems: 'center', gap: 12, flexShrink: 0, flexWrap: 'wrap' }}>
    <span className="label">메인 차트 · 수치</span>

    <div style={{ display: 'flex', gap: 8, alignItems: 'center', flexWrap: 'wrap' }}>
      {/* 보기 설정 */}
      <button
        onClick={onToggleInfo}
        aria-pressed={showInfo}
        title="차트 위에 값과 이름을 같이 표시합니다"
        className={`btn btn-sm btn-toggle${showInfo ? ' on' : ''}`}
      >
        값 표시
      </button>
      <button
        onClick={onToggleGrid}
        aria-pressed={showGrid}
        title="차트 바탕의 눈금선"
        className={`btn btn-sm btn-toggle${showGrid ? ' on' : ''}`}
      >
        눈금선
      </button>

      <span className="toolbar-sep" />

      {/* 보는 구간 */}
      <button onClick={onOneHourView} className="btn btn-ghost btn-sm" title="지금 보고 있는 가운데를 기준으로 앞뒤 30분만 봅니다">
        1시간만 보기
      </button>
      <div className="field-inline">
        <span className="label">Y축 여백</span>
        <select
          value={String(yBuffer)}
          onChange={(e) => onYBufferChange(e.target.value === 'auto' ? 'auto' : Number(e.target.value))}
          title="그래프 위아래로 남겨 둘 여백"
          className="input"
          style={{ height: 32, width: 84 }}
        >
          {Y_BUFFER_OPTIONS.map(o => <option key={String(o.value)} value={String(o.value)}>{o.label}</option>)}
        </select>
      </div>

      <span className="toolbar-sep" />

      {/* 기준 시각 — 이 줄에서 유일하게 데이터를 바꾸는 칸이라 이름표를 붙인다. */}
      <div className="field-inline">
        <span className="label">기준 시각</span>
        <input
          type="datetime-local"
          value={targetDate}
          onChange={(e) => onDateChange(e.target.value)}
          disabled={isChartLoading}
          className="input"
          style={{ height: 32, width: 190 }}
        />
      </div>
      <button onClick={onCopy} title="지금 보고 있는 시점을 스마트 검색에 붙여 넣을 수 있는 문장으로 복사합니다" className="btn btn-ghost btn-sm">
        <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round" aria-hidden="true">
          <rect x="9" y="9" width="12" height="12" rx="2" />
          <path d="M5 15H4a2 2 0 0 1-2-2V4a2 2 0 0 1 2-2h9a2 2 0 0 1 2 2v1" />
        </svg>
        시점 복사
      </button>
    </div>
  </div>
);
