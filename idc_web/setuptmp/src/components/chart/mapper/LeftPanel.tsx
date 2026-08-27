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

const getRoleLabels = (roleInfo?: Role, fallbackId?: number) => {
  const roleName = roleInfo?.role_name || (fallbackId ? `Role ${fallbackId}` : '');
  const roleLabel = roleInfo ? (roleInfo.display_name || roleInfo.role_name) : `Role ${fallbackId}`;
  const badgeLabel = roleInfo ? (roleInfo.short_name || roleInfo.role_name) : `${fallbackId}`;

  return { roleName, roleLabel, badgeLabel };
};


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


  const visibleRoom0Roles = room0Roles.filter(
    (role) => !droppedRoleIds.includes(role.role_id)
  );
  const visibleTargetRoles = targetRoomRoles.filter(
    (role) => !droppedRoleIds.includes(role.role_id)
  );
  const renderRoleItem = (role: Role) => {
    const { roleLabel, badgeLabel } = getRoleLabels(role, role.role_id);
return (
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
          display: 'flex',
          alignItems: 'center',
          gap: 6,
        }}
      >
        {/* 약어 배지 영역 */}
        <span
          style={{
            fontSize: '11px',
            backgroundColor: '#333',
            color: '#fff',
            padding: '2px 4px',
            borderRadius: '4px',
          }}
        >
          {badgeLabel}
        </span>
        {/* 풀네임(디스플레이명) 영역 */}
        <span>{roleLabel}</span>
      </div>
    );
  };
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
              {renderRoleItem(role)}
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
                {renderRoleItem(role)}
              </div>
            ))}
          </div>
        </div>
      </div>
    </div>
  );
};