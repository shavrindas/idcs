import React from 'react';
import type { Role } from '../../../types';


interface Props {
  facilities: any[];
  rooms: any[];
  selectedFacility: number | null;
  selectedRoom: number | null;
  room0Roles: Role[];
  targetRoomRoles: Role[];
  droppedRoleIds: number[];
  onFacilityChange: (id: number) => void;
  onRoomChange: (id: number) => void;
  onDragStart: (e: React.DragEvent, role: Role) => void;
}

export const LeftPanel: React.FC<Props> = ({
  facilities,
  rooms,
  selectedFacility,
  selectedRoom,
  room0Roles,
  targetRoomRoles,
  droppedRoleIds,
  onFacilityChange,
  onRoomChange,
  onDragStart,
}) => {
  // 이미 오른쪽 패널에 추가된 항목은 목록에서 제외
  const visibleRoom0Roles = room0Roles.filter(
    (role) => !droppedRoleIds.includes(role.role_id)
  );
  const visibleTargetRoles = targetRoomRoles.filter(
    (role) => !droppedRoleIds.includes(role.role_id)
  );

  return (
    <div
      style={{
        border: '2px solid red',
        flex: 1,
        minHeight: 0,
        padding: 10,
        display: 'flex',
        flexDirection: 'column',
        gap: 10,
      }}
    >
      <select
        value={selectedFacility || ''}
        onChange={(e) => onFacilityChange(Number(e.target.value))}
      >
        <option value="">시설 선택</option>
        {facilities.map((f) => (
          <option key={f.id} value={f.id}>
            {f.name}
          </option>
        ))}
      </select>

      <div style={{ display: 'flex', flex: 1, minHeight: 0, gap: 10 }}>
        {/* 0호실 (공용) 영역 */}
        <div
          style={{
            border: '1px solid #333',
            flex: 1,
            minHeight: 0,
            padding: 10,
            overflowY: 'auto',
          }}
        >
          <h4>0호실 (공용)</h4>
          {visibleRoom0Roles.map((role) => (
            <div
              key={role.role_id}
              draggable
              onDragStart={(e) => onDragStart(e, role)}
              style={{
                border: '1px solid #999',
                padding: 8,
                marginBottom: 5,
                cursor: 'grab',
                backgroundColor: '#ff8a80',
              }}
            >
              {role.role_name}
            </div>
          ))}
        </div>

        {/* 개별 호실 영역 */}
        <div
          style={{
            border: '1px solid #333',
            flex: 1,
            minHeight: 0,
            padding: 10,
            display: 'flex',
            flexDirection: 'column',
            gap: 10,
          }}
        >
          <select
            value={selectedRoom || ''}
            onChange={(e) => onRoomChange(Number(e.target.value))}
          >
            <option value="">호실 선택</option>
            {rooms.map((r) => (
              <option key={r.id} value={r.id}>
                {r.name}
              </option>
            ))}
          </select>

          <div style={{ flex: 1, minHeight: 0, overflowY: 'auto' }}>
            {visibleTargetRoles.map((role) => (
              <div
                key={role.role_id}
                draggable
                onDragStart={(e) => onDragStart(e, role)}
                style={{
                  border: '1px solid #999',
                  padding: 8,
                  marginBottom: 5,
                  cursor: 'grab',
                  backgroundColor: '#ff8a80',
                }}
              >
                {role.role_name}
              </div>
            ))}
          </div>
        </div>
      </div>
    </div>
  );
};