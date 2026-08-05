import React from 'react';
import { ChartMappingPage } from './pages/ChartMappingPage';
import './App.css';

function App() {
  return (
    <div style={{ display: 'flex', flexDirection: 'column', height: '100vh', padding: 10 }}>
      <header style={{ border: '2px solid orange', padding: 10, textAlign: 'center', marginBottom: 10 }}>
        <h2>IDCool 차트 매핑 관리자</h2>
      </header>
      
      {/* 라우팅 라이브러리(react-router-dom) 도입 전이므로 바로 페이지 렌더링 */}
      <ChartMappingPage />
      
    </div>
  );
}

export default App;