import React from 'react';
import type { Role, ChartGroup } from '../../../types';

interface Props {
  existingGroups: ChartGroup[];
  selectedGroupId: number | 'new';
  groupName: string;
  droppedRoles: Role[];
  onGroupSelect: (val: string) => void;
  onGroupNameChange: (val: string) => void;
  onDrop: (e: React.DragEvent) => void;
  onDragOver: (e: React.DragEvent) => void;
  onRemoveRole: (roleId: number) => void;
  onReorderRoles: (sourceIndex: number, targetIndex: number) => void;
  onSaveGroup: () => void;
}

// 명칭 및 약어 Fallback 헬퍼 함수
const getRoleLabels = (roleInfo?: Role, fallbackId?: number) => {
  const roleName = roleInfo?.role_name || (fallbackId ? `Role ${fallbackId}` : '');
  const roleLabel = roleInfo ? (roleInfo.display_name || roleInfo.role_name) : `Role ${fallbackId}`;
  const badgeLabel = roleInfo ? (roleInfo.short_name || roleInfo.role_name) : `${fallbackId}`;

  return { roleName, roleLabel, badgeLabel };
};

export const RightPanel: React.FC<Props> = ({
  existingGroups,
  selectedGroupId,
  groupName,
  droppedRoles,
  onGroupSelect,
  onGroupNameChange,
  onDrop,
  onDragOver,
  onRemoveRole,
  onReorderRoles,
  onSaveGroup,
}) => {
  // 내부 항목 간 순서 변경 드래그 시작
  const handleItemDragStart = (e: React.DragEvent, index: number) => {
    e.stopPropagation();
    e.dataTransfer.setData('text/reorder-index', String(index));
  };

  // 내부 항목 드롭 시 위치 교환 또는 외부 드롭 처리
  const handleItemDrop = (e: React.DragEvent, targetIndex: number) => {
    e.stopPropagation();
    e.preventDefault();
    const sourceIndexStr = e.dataTransfer.getData('text/reorder-index');

    if (sourceIndexStr !== '') {
      onReorderRoles(Number(sourceIndexStr), targetIndex);
    } else {
      onDrop(e);
    }
  };

  return (
    <div
      className="card"
      style={{
        flex: 1,
        minHeight: 0,
        display: 'flex',
        flexDirection: 'column',
        gap: 12,
      }}
    >
      <div
        style={{
          display: 'flex',
          flexDirection: 'column',
          gap: 10,
        }}
      >
        <select
          value={selectedGroupId}
          onChange={(e) => onGroupSelect(e.target.value)}
          className="input"
        >
          <option value="new">+ 새로운 그룹 추가하기</option>
          {existingGroups.map((g) => (
            <option key={g.group_id} value={g.group_id}>
              [불러오기] {g.group_name}
            </option>
          ))}
        </select>
        <input
          type="text"
          placeholder="새 그룹 명칭 입력"
          value={groupName}
          onChange={(e) => onGroupNameChange(e.target.value)}
          className="input"
        />
      </div>

      <p className="label">드래그 앤 드롭 영역</p>
      <div
        onDrop={onDrop}
        onDragOver={onDragOver}
        style={{
          border: '2px dashed var(--border)',
          borderRadius: 12,
          flex: 1,
          minHeight: 0,
          padding: 12,
          overflowY: 'auto',
          background: 'var(--bg)',
        }}
      >
        {droppedRoles.length === 0 && (
          <p style={{ color: 'var(--text-secondary)', fontSize: 13 }}>여기로 포인트 롤을 드래그하세요.</p>
        )}
        {droppedRoles.map((role, idx) => {
          const { roleLabel, badgeLabel } = getRoleLabels(role, role.role_id);

          return (
            <div
              key={role.role_id}
              draggable
              onDragStart={(e) => handleItemDragStart(e, idx)}
              onDragOver={(e) => e.preventDefault()}
              onDrop={(e) => handleItemDrop(e, idx)}
              className="card"
              style={{
                display: 'flex',
                justifyContent: 'space-between',
                alignItems: 'center',
                padding: '8px 10px',
                marginBottom: 6,
                cursor: 'grab',
              }}
            >
              <div style={{ display: 'flex', alignItems: 'center', gap: 8 }}>
                <span style={{ color: 'var(--text-secondary)' }}>☰</span>
                <span className="chip">{badgeLabel}</span>
                <span style={{ fontSize: 13 }}>{roleLabel}</span>
              </div>

              <span
                onClick={(e) => {
                  e.stopPropagation();
                  onRemoveRole(role.role_id);
                }}
                style={{ cursor: 'pointer', marginLeft: 8, color: 'var(--text-secondary)' }}
              >
                ✕
              </span>
            </div>
          );
        })}
      </div>

      <button onClick={onSaveGroup} className="btn btn-primary" style={{ height: 44 }}>
        {selectedGroupId === 'new' ? '등록하기' : '수정하기 (Backend 연결 요망)'}
      </button>
    </div>
  );
};
