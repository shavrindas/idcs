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
  { value: 'auto', label: '여백 자동' },
  { value: 0, label: '여백 없음' },
  { value: 10, label: '여백 ±10' },
  { value: 50, label: '여백 ±50' },
  { value: 100, label: '여백 ±100' },
];

export const TopToolBar: React.FC<Props> = ({ showInfo, showGrid, targetDate, isChartLoading, onCopy, onToggleInfo, onToggleGrid, onOneHourView, onDateChange, yBuffer, onYBufferChange }) => (
  <div className="card" style={{ padding: 10, display: 'flex', justifyContent: 'space-between', alignItems: 'center', flexShrink: 0 }}>
    <span className="label">메인 차트</span>
    <div style={{ display: 'flex', gap: 8, alignItems: 'center' }}>
      <button onClick={onCopy} title="현재 차트 시점 정보 복사" className="btn btn-ghost btn-sm">복사</button>
      <button onClick={onToggleInfo} className={showInfo ? 'btn btn-primary btn-sm' : 'btn btn-ghost btn-sm'}>정보 {showInfo ? 'ON' : 'OFF'}</button>
      <button onClick={onToggleGrid} className={showGrid ? 'btn btn-primary btn-sm' : 'btn btn-ghost btn-sm'}>그리드 {showGrid ? 'ON' : 'OFF'}</button>
      <button onClick={onOneHourView} className="btn btn-outline btn-sm">1시간 뷰</button>
      <select
        value={String(yBuffer)}
        onChange={(e) => onYBufferChange(e.target.value === 'auto' ? 'auto' : Number(e.target.value))}
        title="그래프 위아래 여백"
        className="input"
        style={{ height: 32, width: 110 }}
      >
        {Y_BUFFER_OPTIONS.map(o => <option key={String(o.value)} value={String(o.value)}>{o.label}</option>)}
      </select>
      <input type="datetime-local" value={targetDate} onChange={(e) => onDateChange(e.target.value)} disabled={isChartLoading} className="input" style={{ height: 32, width: 190 }} />
    </div>
  </div>
);
