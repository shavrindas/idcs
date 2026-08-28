import React from 'react';
import type { Role } from '../../types';

interface IndexEditMap {
  [roleId: number]: {
    display_name: string;
    short_name: string;
  };
}

interface Props {
  roles: Role[];
  editMap: IndexEditMap;
  onFieldChange: (roleId: number, field: 'display_name' | 'short_name', value: string) => void;
}

export const IndexingTable: React.FC<Props> = ({ roles, editMap, onFieldChange }) => {
  return (
    <div className="card" style={{ flex: 1, minHeight: 0, overflowY: 'auto', padding: 0 }}>
      <table style={{ width: '100%', borderCollapse: 'collapse', textAlign: 'left', fontSize: 13, color: 'var(--text)' }}>
        <thead style={{ position: 'sticky', top: 0, backgroundColor: 'var(--surface)', zIndex: 1, borderBottom: '1px solid var(--border)' }}>
          <tr>
            <th style={{ padding: '12px 16px', width: '80px', color: 'var(--text-secondary)', fontWeight: 700, fontSize: 12 }}>ID</th>
            <th style={{ padding: '12px 16px', width: '220px', color: 'var(--text-secondary)', fontWeight: 700, fontSize: 12 }}>기능형 명칭 (수정 불가)</th>
            <th style={{ padding: '12px 16px', color: 'var(--text-secondary)', fontWeight: 700, fontSize: 12 }}>디스플레이용 명칭</th>
            <th style={{ padding: '12px 16px', width: '150px', color: 'var(--text-secondary)', fontWeight: 700, fontSize: 12 }}>약어 명칭 (3자)</th>
          </tr>
        </thead>
        <tbody>
          {roles.map((r) => {
            const currentEdit = editMap[r.role_id] || {
              display_name: r.display_name !== r.role_name ? (r.display_name || '') : '',
              short_name: r.short_name !== r.role_name ? (r.short_name || '') : '',
            };

            return (
              <tr key={r.role_id} style={{ borderBottom: '1px solid var(--border)' }}>
                <td style={{ padding: '8px 16px', color: 'var(--text-secondary)' }}>{r.role_id}</td>
                <td style={{ padding: '8px 16px', color: 'var(--text-secondary)', fontFamily: 'ui-monospace, monospace', fontSize: 12 }}>{r.role_name}</td>
                <td style={{ padding: '6px 16px' }}>
                  <input
                    type="text"
                    value={currentEdit.display_name}
                    placeholder={r.role_name}
                    onChange={(e) => onFieldChange(r.role_id, 'display_name', e.target.value)}
                    className="input"
                    style={{ height: 36 }}
                  />
                </td>
                <td style={{ padding: '6px 16px' }}>
                  <input
                    type="text"
                    maxLength={3}
                    value={currentEdit.short_name}
                    placeholder={r.role_name.slice(0, 3)}
                    onChange={(e) => onFieldChange(r.role_id, 'short_name', e.target.value.toUpperCase())}
                    className="input"
                    style={{ height: 36, textAlign: 'center', fontWeight: 700, color: 'var(--primary)' }}
                  />
                </td>
              </tr>
            );
          })}
          {roles.length === 0 && (
            <tr>
              <td colSpan={4} style={{ padding: 48, textAlign: 'center', color: 'var(--text-secondary)', fontSize: 13 }}>
                선택된 호실에 포인트 롤이 없습니다.
              </td>
            </tr>
          )}
        </tbody>
      </table>
    </div>
  );
};
