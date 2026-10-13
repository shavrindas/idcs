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

  const renderRole = (role: Role) => {
    const roleId = role.role_id;
    const label = role.display_name || role.role_name;
    const short = role.short_name || role.role_name;
    const color = roleColors[roleId] || 'var(--text)';
    const isBool = isBoolRole(roleId);

    return (
      <div key={roleId} style={{ position: 'relative', display: 'flex', alignItems: 'center' }}>
        <label style={{ display: 'flex', alignItems: 'center', cursor: isChartLoading ? 'not-allowed' : 'pointer', color, fontWeight: 700, fontSize: 13, opacity: isChartLoading ? 0.5 : 1 }}>
          <input type="checkbox" checked={checkedRoles.includes(roleId)} onChange={() => onRoleToggle(roleId)} disabled={isChartLoading} style={{ marginRight: 5, accentColor: color }} />
          <span style={{ display: 'inline-block', width: 12, height: 12, backgroundColor: color, marginRight: 5, borderRadius: 2 }}></span>
          {/* 약어가 이름과 같으면 같은 글자를 두 번 쓰는 셈이라 배지를 생략한다.
              display_name·short_name 을 아직 안 넣은 롤이 대부분이라 예전에는
              'temp_pv temp_pv' 처럼 보였다. */}
          {short !== label && <span className="chip" style={{ marginRight: 5 }}>{short}</span>}
          {label}
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
  };

  return (
    <div className="card" style={{ flex: 3, display: 'flex', flexDirection: 'column', gap: 10 }}>
      <div style={{ display: 'flex', alignItems: 'center', gap: 12, flexWrap: 'wrap' }}>
        <h4 style={{ fontSize: 14, margin: 0 }}>맵핑 그룹 활성화</h4>
        <select value={selectedGroupId} onChange={e => onGroupChange(e.target.value ? Number(e.target.value) : '')} disabled={!selectedRoom || groups.length === 0 || isChartLoading} className="input" style={{ width: 200 }}>
          <option value="">-- 맵핑 그룹 선택 --</option>
          {groups.map(g => <option key={g.group_id} value={g.group_id}>{g.group_name}</option>)}
        </select>

        {rolesInGroup.length > 0 && (
          <>
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
          </>
        )}
      </div>

      {sections.map(sec => {
        const ids = sec.roles.map(r => r.role_id);
        const on = ids.filter(id => checkedRoles.includes(id)).length;

        return (
          <div key={sec.label} style={{ display: 'flex', flexDirection: 'column', gap: 6 }}>
            <div style={{ display: 'flex', alignItems: 'center', gap: 8 }}>
              <span style={{ fontSize: 12, fontWeight: 700, color: 'var(--text-secondary)' }}>{sec.label}</span>
              <span style={{ fontSize: 11, color: 'var(--text-secondary)' }}>{on}/{ids.length}</span>
              {!singleNumericMode && (
                <button
                  onClick={() => onRolesToggle(ids, on < ids.length)}
                  disabled={isChartLoading}
                  className="btn btn-ghost btn-sm"
                  style={{ height: 22, padding: '0 8px', fontSize: 11 }}
                >
                  {on < ids.length ? '전체' : '해제'}
                </button>
              )}
            </div>
            <div style={{ display: 'flex', flexWrap: 'wrap', gap: 15 }}>
              {sec.roles.map(renderRole)}
            </div>
          </div>
        );
      })}
    </div>
  );
};
