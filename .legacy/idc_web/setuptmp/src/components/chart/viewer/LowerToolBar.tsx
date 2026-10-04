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
  <div className="card" style={{ padding: 10, display: 'flex', justifyContent: 'space-between', alignItems: 'center', flexShrink: 0 }}>
    <span className="label">상태(BOOL) 차트</span>
    <div style={{ display: 'flex', gap: 8 }}>
      <button onClick={onToggleInfo} className={showInfo ? 'btn btn-primary btn-sm' : 'btn btn-ghost btn-sm'}>정보 {showInfo ? 'ON' : 'OFF'}</button>
      <button onClick={onToggleGrid} className={showGrid ? 'btn btn-primary btn-sm' : 'btn btn-ghost btn-sm'}>그리드 {showGrid ? 'ON' : 'OFF'}</button>
      <button onClick={onSyncTop} className="btn btn-outline btn-sm">시점 맞추기 (TOP 기준)</button>
      <button onClick={onSyncSub} className="btn btn-outline btn-sm">시점 맞추기 (BOOL 기준)</button>
    </div>
  </div>
);
