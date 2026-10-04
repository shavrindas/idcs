import React from 'react';

interface Props {
  datasets: any[];
  roleColors: Record<number, string>;
}

interface SeriesStat {
  roleId: number;
  name: string;
  color: string;
  min: number | null;
  avg: number | null;
  max: number | null;
}

const computeStats = (datasets: any[], roleColors: Record<number, string>): SeriesStat[] => {
  const stats: SeriesStat[] = [];

  for (const ds of datasets) {
    const points: any[] = ds.data || [];
    if (points.length === 0) continue;

    let sum = 0;
    let count = 0;
    let min: number | null = null;
    let max: number | null = null;

    for (const p of points) {
      const mean = typeof p.mean === 'number' ? p.mean : null;
      const pMin = typeof p.min === 'number' ? p.min : mean;
      const pMax = typeof p.max === 'number' ? p.max : mean;

      if (mean != null) { sum += mean; count++; }
      if (pMin != null) min = min == null ? pMin : Math.min(min, pMin);
      if (pMax != null) max = max == null ? pMax : Math.max(max, pMax);
    }

    if (count === 0 && min == null) continue;

    stats.push({
      roleId: ds.role_id,
      name: ds.display_name || ds.role_name || `시리즈 ${ds.role_id}`,
      color: roleColors[ds.role_id] || '#5b6b73',
      min,
      avg: count > 0 ? sum / count : null,
      max,
    });
  }

  return stats;
};

const fmt = (v: number | null) => (v == null ? '-' : v.toFixed(1));

/** 조회된 구간의 시리즈별 최소/평균/최대값 요약. 그래프를 눈으로 훑지 않아도 수치를 바로 확인할 수 있게 한다. */
export const ChartStatsPanel: React.FC<Props> = ({ datasets, roleColors }) => {
  const stats = computeStats(datasets, roleColors);
  if (stats.length === 0) return null;

  return (
    <div className="card" style={{ display: 'flex', flexDirection: 'column', gap: 8 }}>
      <h4 style={{ fontSize: 13, color: 'var(--text-secondary)', margin: 0 }}>구간 요약</h4>
      {stats.map(s => (
        <div key={s.roleId} style={{ display: 'flex', alignItems: 'center', gap: 8, fontSize: 12 }}>
          <span style={{ width: 8, height: 8, borderRadius: '50%', background: s.color, flexShrink: 0 }} />
          <span style={{ flex: 1, fontWeight: 600, overflow: 'hidden', textOverflow: 'ellipsis', whiteSpace: 'nowrap' }}>{s.name}</span>
          <span style={{ color: 'var(--text-secondary)' }}>최소 {fmt(s.min)}</span>
          <span style={{ color: 'var(--text-secondary)' }}>평균 {fmt(s.avg)}</span>
          <span style={{ color: 'var(--text-secondary)' }}>최대 {fmt(s.max)}</span>
        </div>
      ))}
    </div>
  );
};
