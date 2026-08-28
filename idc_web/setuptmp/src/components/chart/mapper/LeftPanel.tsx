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
        className="card"
        style={{
          padding: '8px 10px',
          marginBottom: 6,
          cursor: 'grab',
          display: 'flex',
          alignItems: 'center',
          gap: 8,
        }}
      >
        <span className="chip">{badgeLabel}</span>
        <span style={{ fontSize: 13 }}>{roleLabel}</span>
      </div>
    );
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
      <select
        value={selectedFacility || ''}
        onChange={(e) => onFacilityChange(Number(e.target.value))}
        className="input"
      >
        <option value="">시설 선택</option>
        {facilities.map((f) => (
          <option key={f.id} value={f.id}>
            {f.name}
          </option>
        ))}
      </select>

      <div style={{ display: 'flex', flex: 1, minHeight: 0, gap: 12 }}>
        {/* 0호실 (공용) 영역 */}
        <div
          style={{
            border: '1px solid var(--border)',
            borderRadius: 12,
            flex: 1,
            minHeight: 0,
            padding: 12,
            overflowY: 'auto',
          }}
        >
          <p className="label" style={{ marginBottom: 10 }}>0호실 (공용)</p>
          {visibleRoom0Roles.map((role) => renderRoleItem(role))}
        </div>

        {/* 개별 호실 영역 */}
        <div
          style={{
            border: '1px solid var(--border)',
            borderRadius: 12,
            flex: 1,
            minHeight: 0,
            padding: 12,
            display: 'flex',
            flexDirection: 'column',
            gap: 10,
          }}
        >
          <select
            value={selectedRoom || ''}
            onChange={(e) => onRoomChange(Number(e.target.value))}
            className="input"
          >
            <option value="">호실 선택</option>
            {rooms.map((r) => (
              <option key={r.id} value={r.id}>
                {r.name}
              </option>
            ))}
          </select>

          <div style={{ flex: 1, minHeight: 0, overflowY: 'auto' }}>
            {visibleTargetRoles.map((role) => renderRoleItem(role))}
          </div>
        </div>
      </div>
    </div>
  );
};
