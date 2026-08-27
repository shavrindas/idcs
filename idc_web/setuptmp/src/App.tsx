import React, { useState } from 'react';
import { BrowserRouter as Router, Routes, Route, Navigate, Link } from 'react-router-dom';
import { ChartMappingPage } from './pages/ChartMappingPage';
import { ChartViewerPage }  from './pages/ChartViewerPage';
import { PRIndexingPage }    from './pages/PRIndexingPage';
import { FacilityManagerPage } from './pages/FacilityManagerPage';
import { LoginPage } from './pages/LoginPage';
import { MainPage } from './pages/MainPage';
import './App.css';

function App() {
  const [user, setUser] = useState<any>(null); // 로그인한 유저 정보 상태

  const handleLogout = () => {
    setUser(null);
  };

  // 관리자 권한 체크용 상수
  const isAdmin = user && (user.role === 'ADMIN' || user.role === 'DEVELOPER');

  return (
    <Router>
      <div style={{ display: 'flex', flexDirection: 'column', height: '100vh', padding: 10, backgroundColor: '#121212', color: '#ffffff', boxSizing: 'border-box' }}>
        
        {/* 헤더 */}
        <header style={{ border: '2px solid #e91e63', padding: 10, display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: 10 }}>
          <h2 style={{ margin: 0, color: '#e91e63' }}>IDCool Systems Console</h2>
          {user && (
            <div>
              <span style={{ marginRight: 15 }}>{user.name} ({user.role})</span>
              <button onClick={handleLogout} style={{ padding: '5px 10px', cursor: 'pointer' }}>로그아웃</button>
            </div>
          )}
        </header>

        {/* 글로벌 네비게이션 바 (로그인한 유저에게만 노출) */}
        {user && (
          <nav style={{ border: '2px solid #ff9800', padding: 15, marginBottom: 10, display: 'flex', gap: 20, alignItems: 'center' }}>
            <strong style={{ color: '#ff9800' }}>NAV</strong>
            
            {isAdmin && (
              <>
                <Link to="/main" style={{ color: '#ffffff', textDecoration: 'none' }}>[메인 대시보드]</Link>
                <Link to="/mapping" style={{ color: '#ffffff', textDecoration: 'none' }}>[맵핑 관리자]</Link>
              </>
            )}

            {/* 유저와 관리자 공통 메뉴 */}
            <Link to="/viewer" style={{ color: '#ffffff', textDecoration: 'none', fontWeight: !isAdmin ? 'bold' : 'normal' }}>[차트 뷰어]</Link>
            
            {isAdmin && (
              <>
                <Link to="/indexing" style={{ color: '#ffffff', textDecoration: 'none' }}>[명칭 인덱싱]</Link>
                <Link to="/facility-manager" style={{ color: '#ffffff', textDecoration: 'none' }}>[시설/호실 관리]</Link>
              </>
            )}
          </nav>
        )}

        {/* 본문 영역 */}
        <div style={{ flex: 1, display: 'flex', flexDirection: 'column', overflow: 'hidden' }}>
          <Routes>
            {/* 비로그인 상태일 때 접근 가능한 Route */}
            <Route path="/login" element={<LoginPage onLogin={setUser} />} />
            
            {/* 로그인 상태 체크 */}
            {!user ? (
              <Route path="*" element={<Navigate to="/login" />} />
            ) : (
              <>
                {/* Admin/Developer 전용 라우트 */}
                {isAdmin && (
                  <>
                    <Route path="/main" element={<MainPage />} />
                    <Route path="/mapping" element={<ChartMappingPage />} />
                    <Route path="/indexing" element={<PRIndexingPage />} />
                    <Route path="/facility-manager" element={<FacilityManagerPage />} />
                  </>
                )}
                
                {/* User/Admin 공통 라우트 */}
                <Route path="/viewer" element={<ChartViewerPage user={user} />} />
                
                {/* 기본 리다이렉트 (관리자는 메인, 유저는 뷰어로) */}
                <Route path="*" element={
                  <Navigate to={isAdmin ? "/main" : "/viewer"} />
                } />
              </>
            )}
          </Routes>
        </div>
      </div>
    </Router>
  );
}

export default App;