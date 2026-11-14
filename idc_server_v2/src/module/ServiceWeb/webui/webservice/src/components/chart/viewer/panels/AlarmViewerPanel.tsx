import React from 'react';
import type { Role } from '../../../../types';

interface Props {
  selectedAlarmIds: number[];
  alarms: any[];
  allRoles: Role[];
}

const formatAlarmTime = (iso: string) => {
  const d = new Date(iso);
  const pad = (n: number) => n.toString().padStart(2, '0');
  return `${d.getFullYear()}.${pad(d.getMonth() + 1)}.${pad(d.getDate())} ${pad(d.getHours())}:${pad(d.getMinutes())}`;
};

export const AlarmViewerPanel: React.FC<Props> = ({ selectedAlarmIds, alarms, allRoles }) => (
  <div className="card" style={{ flex: 1, display: 'flex', flexDirection: 'column', overflowY: 'auto' }}>
    <h4 style={{ margin: '0 0 10px 0', textAlign: 'center', fontSize: 14 }}>알람 Viewer</h4>
    {selectedAlarmIds.length > 0 ? (
      <div style={{ display: 'flex', flexDirection: 'column', gap: 15 }}>
        {selectedAlarmIds.map(alarmId => {
          const alarm = alarms.find(a => a.alarm_id === alarmId);
          if (!alarm) return null;
          const role = allRoles.find(r => r.role_id === alarm.role_id);
          return (
            <div key={alarmId} style={{ display: 'flex', flexDirection: 'column', borderBottom: '1px solid var(--border)', paddingBottom: 10 }}>
              <h5 style={{ color: 'var(--error)', margin: '0 0 5px 0', fontSize: 13 }}>
                {role?.display_name || role?.role_name || `role #${alarm.role_id}`}
              </h5>
              <p style={{ fontSize: 12, color: 'var(--text-secondary)', margin: 0 }}>{formatAlarmTime(alarm.timestamp)}</p>
            </div>
          );
        })}
      </div>
    ) : (
      <div style={{ flex: 1, display: 'flex', alignItems: 'center', justifyContent: 'center', color: 'var(--text-secondary)', fontSize: 13, textAlign: 'center' }}>
        차트에서 알람 표시선을 클릭하세요.
      </div>
    )}
  </div>
);
