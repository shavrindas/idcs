import React from 'react';
import { Monogram } from '../components/Brand';

export const MainPage: React.FC = () => {
  return (
    <div style={{ display: 'flex', flexDirection: 'column', alignItems: 'center', justifyContent: 'center', flex: 1, gap: 10 }}>
      <div style={{ marginBottom: 4 }}><Monogram size={52} /></div>
      <h2 style={{ fontSize: 22, fontWeight: 800, letterSpacing: -0.3 }}>관리자 대시보드</h2>
      <p style={{ color: 'var(--text-secondary)', fontSize: 13 }}>알람 등 요약 위젯이 추후 이곳에 추가될 예정입니다.</p>
    </div>
  );
};
