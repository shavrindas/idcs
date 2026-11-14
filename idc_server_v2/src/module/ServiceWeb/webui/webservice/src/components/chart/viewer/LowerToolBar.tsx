import React from 'react';

interface Props {
  showInfo: boolean;
  showGrid: boolean;
  isCollapsed: boolean;
  onToggleInfo: () => void;
  onToggleGrid: () => void;
  onToggleCollapsed: () => void;
  onSyncTop: () => void;
  onSyncSub: () => void;
}

/**
 * 상태 차트 위의 도구 모음.
 *
 * '시점 맞추기 (TOP 기준)' 은 무엇을 무엇에 맞추는지가 읽히지 않는다. 어느
 * 쪽이 기준이고 어느 쪽이 따라가는지를 말로 적는다.
 *
 * 왼쪽 단추는 이 차트 전체를 접고 펴는 손잡이다 — 접히면 나머지 단추들과
 * 차트 본문이 함께 사라져, 위 차트만 보고 싶을 때 화면을 길게 내려 쓸 수
 * 있다.
 */
export const LowerToolBar: React.FC<Props> = ({ showInfo, showGrid, isCollapsed, onToggleInfo, onToggleGrid, onToggleCollapsed, onSyncTop, onSyncSub }) => (
  <div className="card" style={{ padding: 10, display: 'flex', justifyContent: 'space-between', alignItems: 'center', gap: 12, flexShrink: 0, flexWrap: 'wrap' }}>
    <button
      onClick={onToggleCollapsed}
      aria-expanded={!isCollapsed}
      title={isCollapsed ? '상태 차트 펼치기' : '상태 차트 접기'}
      className="btn btn-sm btn-toggle"
      style={{ display: 'inline-flex', alignItems: 'center', gap: 6 }}
    >
      <svg
        width="10" height="10" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="3"
        strokeLinecap="round" strokeLinejoin="round" aria-hidden="true"
        style={{ transform: isCollapsed ? 'rotate(-90deg)' : 'none', transition: 'transform 0.15s' }}
      >
        <path d="M6 9l6 6 6-6" />
      </svg>
      상태 차트
    </button>
    {!isCollapsed && (
      <div style={{ display: 'flex', gap: 8, alignItems: 'center', flexWrap: 'wrap' }}>
        <button onClick={onToggleInfo} aria-pressed={showInfo} className={`btn btn-sm btn-toggle${showInfo ? ' on' : ''}`}>값 표시</button>
        <button onClick={onToggleGrid} aria-pressed={showGrid} className={`btn btn-sm btn-toggle${showGrid ? ' on' : ''}`}>눈금선</button>
        <span className="toolbar-sep" />
        <button onClick={onSyncTop} className="btn btn-ghost btn-sm" title="위 차트가 보고 있는 구간으로 아래 차트를 옮깁니다">
          상단 맞춤
        </button>
        <button onClick={onSyncSub} className="btn btn-ghost btn-sm" title="아래 차트가 보고 있는 구간으로 위 차트를 옮깁니다">
          하단 맞춤
        </button>
      </div>
    )}
  </div>
);
