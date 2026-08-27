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
    <div style={{ flex: 1, minHeight: 0, overflowY: 'auto', border: '1px solid #444', backgroundColor: '#1e1e1e' }}>
      <table style={{ width: '100%', borderCollapse: 'collapse', textAlign: 'left', fontSize: 13, color: '#eee' }}>
        <thead style={{ position: 'sticky', top: 0, backgroundColor: '#2a2a2a', zIndex: 1, borderBottom: '2px solid #555' }}>
          <tr>
            <th style={{ padding: '10px 12px', width: '80px' }}>ID</th>
            <th style={{ padding: '10px 12px', width: '220px' }}>기능형 명칭 (수정 불가)</th>
            <th style={{ padding: '10px 12px' }}>디스플레이용 명칭</th>
            <th style={{ padding: '10px 12px', width: '150px' }}>약어 명칭 (3자)</th>
          </tr>
        </thead>
        <tbody>
          {roles.map((r) => {
            const currentEdit = editMap[r.role_id] || {
              display_name: r.display_name !== r.role_name ? (r.display_name || '') : '',
              short_name: r.short_name !== r.role_name ? (r.short_name || '') : '',
            };

            return (
              <tr key={r.role_id} style={{ borderBottom: '1px solid #333' }}>
                <td style={{ padding: '8px 12px', color: '#888' }}>{r.role_id}</td>
                <td style={{ padding: '8px 12px', color: '#aaa', fontFamily: 'monospace' }}>{r.role_name}</td>
                <td style={{ padding: '6px 12px' }}>
                  <input
                    type="text"
                    value={currentEdit.display_name}
                    placeholder={r.role_name}
                    onChange={(e) => onFieldChange(r.role_id, 'display_name', e.target.value)}
                    style={{
                      width: '100%',
                      padding: '6px 8px',
                      backgroundColor: '#2b2b2b',
                      color: '#fff',
                      border: '1px solid #555',
                      borderRadius: 3,
                      boxSizing: 'border-box'
                    }}
                  />
                </td>
                <td style={{ padding: '6px 12px' }}>
                  <input
                    type="text"
                    maxLength={3}
                    value={currentEdit.short_name}
                    placeholder={r.role_name.slice(0, 3)}
                    onChange={(e) => onFieldChange(r.role_id, 'short_name', e.target.value.toUpperCase())}
                    style={{
                      width: '100%',
                      padding: '6px 8px',
                      backgroundColor: '#2b2b2b',
                      color: '#69c0ff',
                      border: '1px solid #555',
                      borderRadius: 3,
                      textAlign: 'center',
                      fontWeight: 'bold',
                      boxSizing: 'border-box'
                    }}
                  />
                </td>
              </tr>
            );
          })}
          {roles.length === 0 && (
            <tr>
              <td colSpan={4} style={{ padding: 40, textAlign: 'center', color: '#666' }}>
                선택된 호실에 포인트 롤이 없습니다.
              </td>
            </tr>
          )}
        </tbody>
      </table>
    </div>
  );
};