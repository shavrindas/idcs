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
  <div style={{ border: '2px solid #9c27b0', padding: 10, display: 'flex', justifyContent: 'space-between', alignItems: 'center', flexShrink: 0, backgroundColor: '#2a2a2a' }}>
    <span style={{ color: '#9c27b0', fontWeight: 'bold' }}>Top Tool Bar</span>
    <div style={{ display: 'flex', gap: 10 }}>
      <button onClick={onCopy} title="현재 차트 시점 정보 복사" style={{ padding: '4px 8px', backgroundColor: '#607d8b', color: 'white', border: 'none', cursor: 'pointer', borderRadius: 4 }}>Copy</button>
      <button onClick={onToggleInfo} style={{ padding: '4px 8px', backgroundColor: showInfo ? '#4caf50' : '#555', color: 'white', border: 'none', cursor: 'pointer' }}>정보 {showInfo ? 'ON' : 'OFF'}</button>
      <button onClick={onToggleGrid} style={{ padding: '4px 8px', backgroundColor: showGrid ? '#2196f3' : '#555', color: 'white', border: 'none', cursor: 'pointer' }}>그리드 {showGrid ? 'ON' : 'OFF'}</button>
      <button onClick={onOneHourView} style={{ padding: '4px 8px', backgroundColor: '#ff9800', color: 'white', border: 'none', cursor: 'pointer' }}>1시간 뷰</button>
      <input type="datetime-local" value={targetDate} onChange={(e) => onDateChange(e.target.value)} disabled={isChartLoading} style={{ padding: 4, backgroundColor: '#333', color: 'white', border: '1px solid #555' }} />
    </div>
  </div>
);