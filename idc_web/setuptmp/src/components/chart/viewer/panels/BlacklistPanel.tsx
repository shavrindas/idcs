import React from 'react';

interface Props {
  hiddenPosts: any[];
  onRestore: (id: number) => void;
}

export const BlacklistPanel: React.FC<Props> = ({ hiddenPosts, onRestore }) => (
  <div className="card" style={{ flex: 1, display: 'flex', flexDirection: 'column', gap: 10, overflowY: 'auto' }}>
    <h4 style={{ color: 'var(--error)', textAlign: 'center', fontSize: 14 }}>소요기록 Black List</h4>
    <div style={{ fontSize: 12, color: 'var(--text-secondary)', textAlign: 'center', marginBottom: 5 }}>현재 그룹에서 제외된 포스트</div>
    <div style={{ display: 'flex', flexDirection: 'column', gap: 6 }}>
      {hiddenPosts.map((hp: any) => (
        <div key={hp.id} style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', backgroundColor: 'var(--error-bg)', padding: '6px 10px', borderRadius: 8 }}>
          <span style={{ fontSize: 13, color: 'var(--text)' }}>{hp.title}</span>
          <button onClick={() => onRestore(hp.id)} className="btn btn-danger btn-sm" style={{ height: 26, padding: '0 8px' }}>복구</button>
        </div>
      ))}
      {hiddenPosts.length === 0 && <div style={{ textAlign: 'center', color: 'var(--text-secondary)', fontSize: 13, marginTop: 10 }}>제외된 항목이 없습니다.</div>}
    </div>
  </div>
);
