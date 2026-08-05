import React from 'react';
import type { Role } from '../types';

interface Props {
  facilities: any[];
  rooms: any[];
  selectedFacility: number | null;
  selectedRoom: number | null;
  room0Roles: Role[];
  targetRoomRoles: Role[];
  onFacilityChange: (id: number) => void;
  onRoomChange: (id: number) => void;
  onDragStart: (e: React.DragEvent, role: Role) => void;
}

export const LeftPanel: React.FC<Props> = ({
  facilities, rooms, selectedFacility, selectedRoom,
  room0Roles, targetRoomRoles, onFacilityChange, onRoomChange, onDragStart
}) => {
  return (
    <div style={{ border: '2px solid red', flex: 1, padding: 10, display: 'flex', flexDirection: 'column', gap: 10 }}>
      <select value={selectedFacility || ''} onChange={(e) => onFacilityChange(Number(e.target.value))}>
        <option value="">시설 선택</option>
        {facilities.map(f => <option key={f.id} value={f.id}>{f.name}</option>)}
      </select>

      <div style={{ display: 'flex', flex: 1, gap: 10 }}>
        <div style={{ border: '1px solid #333', flex: 1, padding: 10, overflowY: 'auto' }}>
          <h4>0호실 (공용)</h4>
          {room0Roles.map(role => (
            <div key={role.role_id} draggable onDragStart={(e) => onDragStart(e, role)}
                 style={{ border: '1px solid #999', padding: 8, marginBottom: 5, cursor: 'grab', backgroundColor: '#fff' }}>
              {role.role_name}
            </div>
          ))}
        </div>

        <div style={{ border: '1px solid #333', flex: 1, padding: 10, overflowY: 'auto' }}>
          <select value={selectedRoom || ''} onChange={(e) => onRoomChange(Number(e.target.value))}>
            <option value="">호실 선택</option>
            {rooms.map(r => <option key={r.id} value={r.id}>{r.name}</option>)}
          </select>
          <div style={{ marginTop: 10 }}>
            {targetRoomRoles.map(role => (
              <div key={role.role_id} draggable onDragStart={(e) => onDragStart(e, role)}
                   style={{ border: '1px solid #999', padding: 8, marginBottom: 5, cursor: 'grab', backgroundColor: '#fff' }}>
                {role.role_name}
              </div>
            ))}
          </div>
        </div>
      </div>
    </div>
  );
};