import React, { useState, useEffect } from 'react';
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
  /** 수치 롤을 하나만 허용하는 모드인지. 그때는 묶음 버튼을 내보내지 않는다. */
  singleNumericMode: boolean;
  onGroupChange: (val: number | '') => void;
  onRoleToggle: (id: number) => void;
  onRolesToggle: (ids: number[], checked: boolean) => void;
  onMenuToggle: (id: number | null) => void;
  onColorChange: (id: number, color: string) => void;
  onGuidelineToggle: (id: number) => void;
  onInvertToggle: (id: number) => void;
  isBoolRole: (id: number) => boolean;
}

/**
 * 롤 이름 앞머리로 묶는 분류.
 *
 * 한 호실에 롤이 쉰 개가 넘는데 예전에는 전부 한 줄로 흘려 놓아서, 원하는
 * 항목을 찾으려면 눈으로 훑는 수밖에 없었다. 설비에서 쓰는 분류 그대로 묶는다.
 */
const CATEGORIES: { prefix: string; label: string }[] = [
  { prefix: 'temp_', label: '실제 온도' },
  { prefix: 'deforest_', label: '제상 정보' },
  { prefix: 'emergency_', label: '이상 정보' },
  { prefix: 'inverter_', label: '인버터 정보' },
  { prefix: 'equipment_', label: '장비 정보' },
  { prefix: 'control_', label: '제어 정보' },
];

const categoryOf = (roleName: string) =>
  CATEGORIES.find(c => roleName.startsWith(c.prefix))?.label ?? '기타';

export const MappingActivePanel: React.FC<Props> = ({ groups, allRoles, roleColors, selectedGroupId, selectedRoom, isChartLoading, checkedRoles, activeGuidelines, invertedBools, openMenuRoleId, singleNumericMode, onGroupChange, onRoleToggle, onRolesToggle, onMenuToggle, onColorChange, onGuidelineToggle, onInvertToggle, isBoolRole }) => {
  const currentGroup = groups.find(g => g.group_id === Number(selectedGroupId));
  const groupRoleIds = currentGroup && currentGroup.role_ids ? currentGroup.role_ids.filter(id => id !== null) : [];

  const rolesInGroup = groupRoleIds
    .map(id => allRoles.find(r => r.role_id === id))
    .filter((r): r is Role => Boolean(r));

  // 분류별로 나눈 뒤, 비어 있는 분류는 내보내지 않는다.
  const sections = [...CATEGORIES.map(c => c.label), '기타']
    .map(label => ({ label, roles: rolesInGroup.filter(r => categoryOf(r.role_name) === label) }))
    .filter(sec => sec.roles.length > 0);

  const checkedCount = rolesInGroup.filter(r => checkedRoles.includes(r.role_id)).length;

  // Only one category is open at a time; showing every category at once made the
  // panel grow taller than the chart itself on rooms with dozens of roles.
  const [activeTab, setActiveTab] = useState<string>('');
  const openSection = sections.find(sec => sec.label === activeTab) ?? sections[0];

  useEffect(() => {
    setActiveTab('');
  }, [selectedGroupId]);

  const renderRole = (role: Role) => {
    const roleId = role.role_id;
    const label = role.display_name || role.role_name;
    const short = role.short_name || role.role_name;
    const color = roleColors[roleId] || 'var(--text)';
    const isBool = isBoolRole(roleId);
    const checked = checkedRoles.includes(roleId);

    return (
      <div key={roleId} style={{ position: 'relative', display: 'inline-flex' }}>
        <div
          style={{
            display: 'inline-flex', alignItems: 'center', height: 30, borderRadius: 999,
            border: `1px solid ${checked ? color : 'var(--border)'}`,
            background: checked ? `color-mix(in srgb, ${color} 14%, transparent)` : 'transparent',
            opacity: isChartLoading ? 0.5 : 1, transition: 'background .15s, border-color .15s',
          }}
        >
          <button
            type="button"
            onClick={() => onRoleToggle(roleId)}
            disabled={isChartLoading}
            aria-pressed={checked}
            title={short !== label ? `${label} (${short})` : label}
            style={{
              display: 'inline-flex', alignItems: 'center', gap: 6, height: '100%', padding: '0 4px 0 10px',
              border: 'none', background: 'transparent', cursor: isChartLoading ? 'not-allowed' : 'pointer',
              color: checked ? 'var(--text)' : 'var(--text-secondary)', fontSize: 12.5, fontWeight: checked ? 700 : 500,
              fontFamily: 'inherit', maxWidth: 220,
            }}
          >
            <span style={{ width: 9, height: 9, borderRadius: '50%', flexShrink: 0, background: checked ? color : 'transparent', border: `2px solid ${color}` }} />
            <span style={{ overflow: 'hidden', textOverflow: 'ellipsis', whiteSpace: 'nowrap' }}>{label}</span>
          </button>
          <button
            type="button"
            onClick={() => onMenuToggle(openMenuRoleId === roleId ? null : roleId)}
            aria-label={`${label} 설정`}
            title="색상 · 표시 설정"
            style={{
              height: '100%', padding: '0 9px 0 4px', border: 'none', background: 'transparent',
              cursor: 'pointer', color: 'var(--text-secondary)', fontSize: 13, lineHeight: 1,
            }}
          >
            ⋯
          </button>
        </div>
        {openMenuRoleId === roleId && (
          <div className="card" style={{ position: 'absolute', bottom: 'calc(100% + 8px)', left: 0, zIndex: 1000, padding: 10, minWidth: 170, boxShadow: 'var(--shadow)' }}>
            <div style={{ marginBottom: 10, display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
              <span style={{ fontSize: 12, color: 'var(--text-secondary)' }}>색상 변경:</span>
              <input type="color" value={roleColors[roleId] || '#000000'} onChange={(e) => onColorChange(roleId, e.target.value)} style={{ cursor: 'pointer', border: 'none', background: 'transparent', width: 30, height: 25 }} />
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
  };

  const openIds = openSection ? openSection.roles.map(r => r.role_id) : [];
  const openOn = openIds.filter(id => checkedRoles.includes(id)).length;

  return (
    <div className="card" style={{ flex: 3, minWidth: 0, display: 'flex', flexDirection: 'column', gap: 10 }}>
      <div style={{ display: 'flex', alignItems: 'center', gap: 12, flexWrap: 'wrap' }}>
        <h4 style={{ fontSize: 14, margin: 0 }}>맵핑 그룹</h4>
        <select value={selectedGroupId} onChange={e => onGroupChange(e.target.value ? Number(e.target.value) : '')} disabled={!selectedRoom || groups.length === 0 || isChartLoading} className="input" style={{ width: 200 }}>
          <option value="">-- 맵핑 그룹 선택 --</option>
          {groups.map(g => <option key={g.group_id} value={g.group_id}>{g.group_name}</option>)}
        </select>

        {rolesInGroup.length > 0 && (
          <div style={{ marginLeft: 'auto', display: 'flex', alignItems: 'center', gap: 8 }}>
            <span style={{ fontSize: 12, color: 'var(--text-secondary)' }}>
              {checkedCount} / {rolesInGroup.length} 선택
            </span>
            {/* 수치 롤을 하나만 그리는 모드에서는 묶음 선택이 뜻이 없다. */}
            {!singleNumericMode && (
              <button
                onClick={() => onRolesToggle(rolesInGroup.map(r => r.role_id), checkedCount < rolesInGroup.length)}
                disabled={isChartLoading}
                className="btn btn-ghost btn-sm"
              >
                {checkedCount < rolesInGroup.length ? '모두 선택' : '모두 해제'}
              </button>
            )}
          </div>
        )}
      </div>

      {sections.length > 0 && (
        <div role="tablist" style={{ display: 'flex', gap: 4, flexWrap: 'wrap', borderBottom: '1px solid var(--border)' }}>
          {sections.map(sec => {
            const ids = sec.roles.map(r => r.role_id);
            const on = ids.filter(id => checkedRoles.includes(id)).length;
            const isOpen = sec.label === openSection?.label;
            return (
              <button
                key={sec.label}
                role="tab"
                aria-selected={isOpen}
                onClick={() => setActiveTab(sec.label)}
                style={{
                  display: 'inline-flex', alignItems: 'center', gap: 6, padding: '6px 10px', marginBottom: -1,
                  border: 'none', borderBottom: `2px solid ${isOpen ? 'var(--primary)' : 'transparent'}`,
                  background: 'transparent', cursor: 'pointer', fontFamily: 'inherit',
                  fontSize: 12.5, fontWeight: isOpen ? 700 : 500, color: isOpen ? 'var(--text)' : 'var(--text-secondary)',
                }}
              >
                {sec.label}
                <span style={{
                  fontSize: 11, padding: '1px 6px', borderRadius: 999,
                  background: on > 0 ? 'var(--primary-bg)' : 'transparent',
                  color: on > 0 ? 'var(--primary)' : 'var(--text-secondary)',
                }}>
                  {on}/{ids.length}
                </span>
              </button>
            );
          })}
          {openSection && !singleNumericMode && (
            <button
              onClick={() => onRolesToggle(openIds, openOn < openIds.length)}
              disabled={isChartLoading}
              className="btn btn-ghost btn-sm"
              style={{ marginLeft: 'auto', height: 26, alignSelf: 'center', fontSize: 11 }}
            >
              {openOn < openIds.length ? '이 분류 전체' : '이 분류 해제'}
            </button>
          )}
        </div>
      )}

      {openSection && (
        <div style={{ display: 'flex', flexWrap: 'wrap', gap: 8 }}>
          {openSection.roles.map(renderRole)}
        </div>
      )}
    </div>
  );
};
