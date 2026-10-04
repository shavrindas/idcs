import React from 'react';
import type { ChartGroup, Role } from '../../../../types';

interface Props {
  groups: ChartGroup[];
  allRoles: Role[];
  roleColors: Record<number, string>;
  selectedGroupId: number | '';
  selectedRoom: number | '';
  isChartLoading: boolean;
  checkedRoles: number[];
  activeGuidelines: number[];
  invertedBools: number[];
  openMenuRoleId: number | null;
  onGroupChange: (val: number | '') => void;
  onRoleToggle: (id: number) => void;
  onMenuToggle: (id: number | null) => void;
  onColorChange: (id: number, color: string) => void;
  onGuidelineToggle: (id: number) => void;
  onInvertToggle: (id: number) => void;
  isBoolRole: (id: number) => boolean;
}

export const MappingActivePanel: React.FC<Props> = ({ groups, allRoles, roleColors, selectedGroupId, selectedRoom, isChartLoading, checkedRoles, activeGuidelines, invertedBools, openMenuRoleId, onGroupChange, onRoleToggle, onMenuToggle, onColorChange, onGuidelineToggle, onInvertToggle, isBoolRole }) => {
  const currentGroup = groups.find(g => g.group_id === Number(selectedGroupId));
  const groupRoleIds = currentGroup && currentGroup.role_ids ? currentGroup.role_ids.filter(id => id !== null) : [];


  return (
    <div className="card" style={{ flex: 3, display: 'flex', flexDirection: 'column', gap: 10 }}>
      <h4 style={{ fontSize: 14 }}>맵핑 그룹 활성화</h4>
      <div style={{ display: 'flex', gap: 15, alignItems: 'center', flexWrap: 'wrap' }}>
        <select value={selectedGroupId} onChange={e => onGroupChange(e.target.value ? Number(e.target.value) : '')} disabled={!selectedRoom || groups.length === 0 || isChartLoading} className="input" style={{ width: 200 }}>
          <option value="">-- 맵핑 그룹 선택 --</option>
          {groups.map(g => <option key={g.group_id} value={g.group_id}>{g.group_name}</option>)}
        </select>

        <div style={{ display: 'flex', flexWrap: 'wrap', gap: 15 }}>
          {selectedGroupId && groupRoleIds.map(roleId => {
            const roleInfo = allRoles.find(r => r.role_id === roleId);
            const roleLabel = roleInfo ? (roleInfo.display_name || roleInfo.role_name) : `Role ${roleId}`;  // 표시용 명칭
            const badgeLabel = roleInfo ? (roleInfo.short_name || roleInfo.role_name) : `${roleId}`;        // 약어용 명칭
            const color = roleColors[roleId] || 'var(--text)';
            const isBool = isBoolRole(roleId);

            return (
              <div key={roleId} style={{ position: 'relative', display: 'flex', alignItems: 'center' }}>
                <label style={{ display: 'flex', alignItems: 'center', cursor: isChartLoading ? 'not-allowed' : 'pointer', color: color, fontWeight: 700, fontSize: 13, opacity: isChartLoading ? 0.5 : 1 }}>
                  <input type="checkbox" checked={checkedRoles.includes(roleId)} onChange={() => onRoleToggle(roleId)} disabled={isChartLoading} style={{ marginRight: 5, accentColor: color }} />
                  <span style={{ display: 'inline-block', width: 12, height: 12, backgroundColor: color, marginRight: 5, borderRadius: 2 }}></span>
                  {/* 약어 배지 표시 */}
                  <span className="chip" style={{ marginRight: 5 }}>
                    {badgeLabel}
                  </span>
                  {roleLabel}
                </label>
                <span onClick={() => onMenuToggle(openMenuRoleId === roleId ? null : roleId)} style={{ marginLeft: 5, cursor: 'pointer', fontSize: 16 }}>⚙️</span>
                {openMenuRoleId === roleId && (
                  <div className="card" style={{ position: 'absolute', bottom: 'calc(100% + 8px)', left: 0, zIndex: 1000, padding: 10, minWidth: 170, boxShadow: 'var(--shadow)' }}>
                    <div style={{ marginBottom: 10, display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
                      <span style={{ fontSize: 12, color: 'var(--text-secondary)' }}>색상 변경:</span>
                      <input type="color" value={color} onChange={(e) => onColorChange(roleId, e.target.value)} style={{ cursor: 'pointer', border: 'none', background: 'transparent', width: 30, height: 25 }} />
                    </div>
                    {!isBool && (
                      <div style={{ display: 'flex', alignItems: 'center' }}>
                        <label style={{ fontSize: 12, color: 'var(--text-secondary)', cursor: 'pointer' }}>
                          <input type="checkbox" checked={activeGuidelines.includes(roleId)} onChange={() => onGuidelineToggle(roleId)} style={{ marginRight: 5 }} /> 가이드라인 표시
                        </label>
                      </div>
                    )}
                    {isBool && (
                      <div style={{ display: 'flex', alignItems: 'center' }}>
                        <label style={{ fontSize: 12, color: 'var(--text-secondary)', cursor: 'pointer' }}>
                          <input type="checkbox" checked={invertedBools.includes(roleId)} onChange={() => onInvertToggle(roleId)} style={{ marginRight: 5 }} /> 상태 반전 (Invert)
                        </label>
                      </div>
                    )}
                  </div>
                )}
              </div>
            );
          })}
        </div>
      </div>
    </div>
  );
};
