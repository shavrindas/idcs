import React from 'react';
import { useNavigate } from 'react-router-dom';

export const MainPage: React.FC = () => {
  const navigate = useNavigate();

  const btnStyle = { padding: '15px 30px', margin: '10px', fontSize: '16px', cursor: 'pointer', backgroundColor: '#ff9800', color: '#fff', border: 'none', borderRadius: '5px' };

  return (
    <div style={{ display: 'flex', flexDirection: 'column', alignItems: 'center', justifyContent: 'center', height: '100%' }}>
      <h2 style={{ color: '#ff9800' }}>Admin Dashboard (메인 페이지)</h2>
      <h4>나중에 알람 같은거 추가</h4>
    </div>
  );
};