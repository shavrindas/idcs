import React from 'react';

interface Props {
  hiddenPosts: any[];
  onRestore: (id: number) => void;
}

export const BlacklistPanel: React.FC<Props> = ({ hiddenPosts, onRestore }) => (
  <div style={{ flex: 1, border: '2px solid #ff4d4f', padding: 15, display: 'flex', flexDirection: 'column', gap: 10, backgroundColor: '#2a1215', overflowY: 'auto' }}>
    <h4 style={{ margin: 0, color: '#ff4d4f', textAlign: 'center' }}>소요기록 Black List</h4>
    <div style={{ fontSize: 12, color: '#aaa', textAlign: 'center', marginBottom: 5 }}>현재 그룹에서 제외된 포스트</div>
    <div style={{ display: 'flex', flexDirection: 'column', gap: 5 }}>
      {hiddenPosts.map((hp: any) => (
        <div key={hp.id} style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', backgroundColor: '#441d1f', padding: '6px 10px', borderRadius: 4 }}>
          <span style={{ fontSize: 13, color: '#ffccc7' }}>{hp.title}</span>
          <button onClick={() => onRestore(hp.id)} style={{ backgroundColor: 'transparent', border: '1px solid #ff4d4f', color: '#ff4d4f', cursor: 'pointer', borderRadius: 3, fontSize: 11, padding: '2px 6px' }}>복구</button>
        </div>
      ))}
      {hiddenPosts.length === 0 && <div style={{ textAlign: 'center', color: '#555', marginTop: 10 }}>제외된 항목이 없습니다.</div>}
    </div>
  </div>
);