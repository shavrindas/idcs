import React from 'react';
import type { Role, ChartGroup } from '../types';

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
  onSaveGroup: () => void;
}

export const RightPanel: React.FC<Props> = ({
  existingGroups, selectedGroupId, groupName, droppedRoles,
  onGroupSelect, onGroupNameChange, onDrop, onDragOver, onRemoveRole, onSaveGroup
}) => {
  return (
    <div style={{ border: '2px solid green', flex: 1, padding: 10, display: 'flex', flexDirection: 'column', gap: 10 }}>
      <div style={{ border: '1px solid #333', padding: 10, display: 'flex', flexDirection: 'column', gap: 10 }}>
        <select value={selectedGroupId} onChange={e => onGroupSelect(e.target.value)}>
          <option value="new">+ 새로운 그룹 추가하기</option>
          {existingGroups.map(g => (
            <option key={g.group_id} value={g.group_id}>[불러오기] {g.group_name}</option>
          ))}
        </select>
        <input type="text" placeholder="새 그룹 명칭 입력" value={groupName} onChange={e => onGroupNameChange(e.target.value)} />
        {/* DataType 드롭다운 삭제됨 */}
      </div>

      <h4>드래그 앤 드롭 영역</h4>
      <div onDrop={onDrop} onDragOver={onDragOver}
           style={{ border: '2px dashed #666', flex: 1, padding: 10, overflowY: 'auto', backgroundColor: '#fafafa' }}>
        {droppedRoles.length === 0 && <p style={{ color: '#999' }}>여기로 포인트 롤을 드래그하세요.</p>}
        {droppedRoles.map(role => (
          <div key={role.role_id} onClick={() => onRemoveRole(role.role_id)}
               style={{ border: '1px solid blue', padding: 8, marginBottom: 5, cursor: 'pointer', backgroundColor: '#e6f2ff' }}>
            {role.role_name} ❌
          </div>
        ))}
      </div>

      <button onClick={onSaveGroup} style={{ padding: 15, fontWeight: 'bold', cursor: 'pointer' }}>
        {selectedGroupId === 'new' ? '등록하기' : '수정하기 (Backend 연결 요망)'}
      </button>
    </div>
  );
};