import React, { useEffect, useState } from 'react';
import { MainChartViewer } from '../components/chart/viewer/EChartsViewer';
import { apiService } from '../services/apiService';

import type { SessionUser } from '../types';

interface Props {
  user: SessionUser;
}

const COLOR_PALETTE = ['#2e6bef', '#d64545', '#1f8f5f', '#b6791f', '#1e4fbd', '#0c8599', '#9a60b4', '#ea7ccc'];

const SCALE_OPTIONS = [
  { value: '1m', label: '1분 단위' },
  { value: '5m', label: '5분 단위' },
  { value: '10m', label: '10분 단위' },
  { value: '30m', label: '30분 단위' },
  { value: '1h', label: '1시간 단위' },
];

const RANGE_OPTIONS = [
  { value: '1h', label: '최근 1시간' },
  { value: '12h', label: '최근 12시간' },
  { value: '1d', label: '최근 1일' },
  { value: '7d', label: '최근 7일' },
  { value: '15d', label: '최근 15일' },
];

export const RoomComparePage: React.FC<Props> = ({ user }) => {
  const [facilities, setFacilities] = useState<any[]>([]);
  const [selectedFacility, setSelectedFacility] = useState<number | ''>('');

  const [roles, setRoles] = useState<{ role_name: string; display_name: string; room_count: number }[]>([]);
  const [selectedRole, setSelectedRole] = useState<string>('');

  const [scale, setScale] = useState('1m');
  const [timeRange, setTimeRange] = useState('1d');

  const [datasets, setDatasets] = useState<any[]>([]);
  const [roleColors, setRoleColors] = useState<Record<number, string>>({});
  const [isLoading, setIsLoading] = useState(false);
  const [errorMsg, setErrorMsg] = useState('');

  useEffect(() => {
    apiService.getUserFacilities(user.id).then(res => setFacilities(res.facilities || []));
  }, [user.id]);

  useEffect(() => {
    setSelectedRole('');
    setRoles([]);
    setDatasets([]);
    if (selectedFacility === '') return;
    apiService.getComparableRoles(Number(selectedFacility))
      .then(res => setRoles(res.data?.roles || []))
      .catch(err => setErrorMsg(err.message));
  }, [selectedFacility]);

  const handleCompare = async () => {
    if (selectedFacility === '' || !selectedRole) return;
    setIsLoading(true);
    setErrorMsg('');
    try {
      const res = await apiService.getCompareData(Number(selectedFacility), selectedRole, scale, timeRange);
      const rawDatasets = res.data?.datasets || [];
      // MainChartViewer는 role_id를 시리즈 색상 키로 쓰므로, 색상표를 여기서 구성해서 넘긴다.
      const colors: Record<number, string> = {};
      rawDatasets.forEach((ds: any, idx: number) => { colors[ds.role_id] = COLOR_PALETTE[idx % COLOR_PALETTE.length]; });
      // 같은 role_name이 반복되므로, 시리즈 이름에는 role_name 대신 호실 이름이 나오도록 display_name을 덮어씌운다.
      const labeled = rawDatasets.map((ds: any) => ({ ...ds, display_name: ds.room_name }));
      setDatasets(labeled);
      setRoleColors(colors);
      if (rawDatasets.length === 0) setErrorMsg(res.message || '조회된 데이터가 없습니다.');
    } catch (err: any) {
      setErrorMsg(err.message || '조회에 실패했습니다.');
    } finally {
      setIsLoading(false);
    }
  };

  return (
    <div style={{ display: 'flex', flexDirection: 'column', flex: 1, gap: 12, padding: 24, boxSizing: 'border-box', minHeight: 0 }}>
      <h1 style={{ fontSize: 24, fontWeight: 800, letterSpacing: -0.3, flexShrink: 0 }}>호실 비교</h1>
      <p style={{ fontSize: 13, color: 'var(--text-secondary)', margin: 0, flexShrink: 0 }}>
        같은 시설 안의 여러 호실에서 같은 종류의 값을 한 그래프에 겹쳐서, 어느 호실이 이상하게 동작하는지 한눈에 비교합니다.
      </p>

      <div className="card" style={{ display: 'flex', gap: 10, alignItems: 'flex-end', flexWrap: 'wrap', flexShrink: 0 }}>
        <div style={{ display: 'flex', flexDirection: 'column', gap: 4, minWidth: 180 }}>
          <span className="label">시설</span>
          <select className="input" value={selectedFacility} onChange={e => setSelectedFacility(e.target.value ? Number(e.target.value) : '')}>
            <option value="">-- 시설 선택 --</option>
            {facilities.map(f => <option key={f.id} value={f.id}>{f.name}</option>)}
          </select>
        </div>

        <div style={{ display: 'flex', flexDirection: 'column', gap: 4, minWidth: 220 }}>
          <span className="label">비교할 항목</span>
          <select className="input" value={selectedRole} onChange={e => setSelectedRole(e.target.value)} disabled={roles.length === 0}>
            <option value="">-- 항목 선택 --</option>
            {roles.map(r => <option key={r.role_name} value={r.role_name}>{r.display_name} ({r.room_count}개 호실)</option>)}
          </select>
        </div>

        <div style={{ display: 'flex', flexDirection: 'column', gap: 4, minWidth: 130 }}>
          <span className="label">해상도</span>
          <select className="input" value={scale} onChange={e => setScale(e.target.value)}>
            {SCALE_OPTIONS.map(o => <option key={o.value} value={o.value}>{o.label}</option>)}
          </select>
        </div>

        <div style={{ display: 'flex', flexDirection: 'column', gap: 4, minWidth: 130 }}>
          <span className="label">조회 기간</span>
          <select className="input" value={timeRange} onChange={e => setTimeRange(e.target.value)}>
            {RANGE_OPTIONS.map(o => <option key={o.value} value={o.value}>{o.label}</option>)}
          </select>
        </div>

        <button className="btn btn-primary" style={{ height: 42 }} onClick={handleCompare} disabled={!selectedFacility || !selectedRole || isLoading}>
          비교하기
        </button>
      </div>

      {errorMsg && (
        <div className="card" style={{ borderColor: 'var(--error)', color: 'var(--error)', fontSize: 13, flexShrink: 0 }}>{errorMsg}</div>
      )}

      <div className="card" style={{ flex: 1, minHeight: 400, padding: 12 }}>
        {datasets.length === 0 && !isLoading ? (
          <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'center', height: '100%', color: 'var(--text-secondary)', fontSize: 13 }}>
            시설과 비교할 항목을 선택하고 "비교하기"를 눌러주세요.
          </div>
        ) : (
          <MainChartViewer datasets={datasets} roleColors={roleColors} isLoading={isLoading} showInfo showGrid />
        )}
      </div>
    </div>
  );
};
