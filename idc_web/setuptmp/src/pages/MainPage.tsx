import React from 'react';

export const MainPage: React.FC = () => {
  return (
    <div style={{ display: 'flex', flexDirection: 'column', alignItems: 'center', justifyContent: 'center', flex: 1, gap: 8 }}>
      <div
        style={{
          width: 56, height: 56, borderRadius: 16,
          background: 'var(--primary-bg)', color: 'var(--primary)',
          display: 'flex', alignItems: 'center', justifyContent: 'center',
          fontSize: 26, marginBottom: 8,
        }}
      >
        📊
      </div>
      <h2 style={{ fontSize: 18 }}>관리자 대시보드</h2>
      <p style={{ color: 'var(--text-secondary)', fontSize: 13 }}>알람 등 요약 위젯이 추후 이곳에 추가될 예정입니다.</p>
    </div>
  );
};
