import React from 'react';

interface Props {
  showInfo: boolean;
  showGrid: boolean;
  onToggleInfo: () => void;
  onToggleGrid: () => void;
  onSyncTop: () => void;
  onSyncSub: () => void;
}

/**
 * 상태 차트 위의 도구 모음.
 *
 * '시점 맞추기 (TOP 기준)' 은 무엇을 무엇에 맞추는지가 읽히지 않는다. 어느
 * 쪽이 기준이고 어느 쪽이 따라가는지를 말로 적는다.
 */
export const LowerToolBar: React.FC<Props> = ({ showInfo, showGrid, onToggleInfo, onToggleGrid, onSyncTop, onSyncSub }) => (
  <div className="card" style={{ padding: 10, display: 'flex', justifyContent: 'space-between', alignItems: 'center', gap: 12, flexShrink: 0, flexWrap: 'wrap' }}>
    <span className="label">아래 차트 · 켜짐/꺼짐</span>
    <div style={{ display: 'flex', gap: 8, alignItems: 'center', flexWrap: 'wrap' }}>
      <button onClick={onToggleInfo} aria-pressed={showInfo} className={`btn btn-sm btn-toggle${showInfo ? ' on' : ''}`}>값 표시</button>
      <button onClick={onToggleGrid} aria-pressed={showGrid} className={`btn btn-sm btn-toggle${showGrid ? ' on' : ''}`}>눈금선</button>
      <span className="toolbar-sep" />
      <button onClick={onSyncTop} className="btn btn-ghost btn-sm" title="위 차트가 보고 있는 구간으로 아래 차트를 옮깁니다">
        위 차트에 맞추기
      </button>
      <button onClick={onSyncSub} className="btn btn-ghost btn-sm" title="아래 차트가 보고 있는 구간으로 위 차트를 옮깁니다">
        위 차트를 여기에 맞추기
      </button>
    </div>
  </div>
);
