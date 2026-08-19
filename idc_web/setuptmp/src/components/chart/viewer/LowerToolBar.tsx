import React from 'react';

interface Props {
  showInfo: boolean;
  showGrid: boolean;
  onToggleInfo: () => void;
  onToggleGrid: () => void;
  onSyncTop: () => void;
  onSyncSub: () => void;
}

export const LowerToolBar: React.FC<Props> = ({ showInfo, showGrid, onToggleInfo, onToggleGrid, onSyncTop, onSyncSub }) => (
  <div style={{ border: '2px solid #9c27b0', padding: 10, display: 'flex', justifyContent: 'space-between', alignItems: 'center', flexShrink: 0, backgroundColor: '#2a2a2a' }}>
    <span style={{ color: '#9c27b0', fontWeight: 'bold' }}>Lower Tool Bar</span>
    <div style={{ display: 'flex', gap: 10 }}>
      <button onClick={onToggleInfo} style={{ padding: '4px 8px', backgroundColor: showInfo ? '#4caf50' : '#555', color: 'white', border: 'none', cursor: 'pointer' }}>정보 {showInfo ? 'ON' : 'OFF'}</button>
      <button onClick={onToggleGrid} style={{ padding: '4px 8px', backgroundColor: showGrid ? '#2196f3' : '#555', color: 'white', border: 'none', cursor: 'pointer' }}>그리드 {showGrid ? 'ON' : 'OFF'}</button>
      <button onClick={onSyncTop} style={{ padding: '4px 8px', backgroundColor: '#9c27b0', color: 'white', border: 'none', cursor: 'pointer' }}>시점 맞추기 (TOP 기준)</button>
      <button onClick={onSyncSub} style={{ padding: '4px 8px', backgroundColor: '#9c27b0', color: 'white', border: 'none', cursor: 'pointer' }}>시점 맞추기 (BOOL 기준)</button>
    </div>
  </div>
);