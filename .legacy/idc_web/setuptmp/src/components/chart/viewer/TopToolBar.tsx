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
}

export const TopToolBar: React.FC<Props> = ({ showInfo, showGrid, targetDate, isChartLoading, onCopy, onToggleInfo, onToggleGrid, onOneHourView, onDateChange }) => (
  <div className="card" style={{ padding: 10, display: 'flex', justifyContent: 'space-between', alignItems: 'center', flexShrink: 0 }}>
    <span className="label">메인 차트</span>
    <div style={{ display: 'flex', gap: 8, alignItems: 'center' }}>
      <button onClick={onCopy} title="현재 차트 시점 정보 복사" className="btn btn-ghost btn-sm">복사</button>
      <button onClick={onToggleInfo} className={showInfo ? 'btn btn-primary btn-sm' : 'btn btn-ghost btn-sm'}>정보 {showInfo ? 'ON' : 'OFF'}</button>
      <button onClick={onToggleGrid} className={showGrid ? 'btn btn-primary btn-sm' : 'btn btn-ghost btn-sm'}>그리드 {showGrid ? 'ON' : 'OFF'}</button>
      <button onClick={onOneHourView} className="btn btn-outline btn-sm">1시간 뷰</button>
      <input type="datetime-local" value={targetDate} onChange={(e) => onDateChange(e.target.value)} disabled={isChartLoading} className="input" style={{ height: 32, width: 190 }} />
    </div>
  </div>
);
