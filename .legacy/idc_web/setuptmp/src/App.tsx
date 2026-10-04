import { useState } from 'react';
import { BrowserRouter as Router, Routes, Route, Navigate, NavLink } from 'react-router-dom';
import { ChartMappingPage } from './pages/ChartMappingPage';
import { ChartViewerPage }  from './pages/ChartViewerPage';
import { PRIndexingPage }    from './pages/PRIndexingPage';
import { FacilityManagerPage } from './pages/FacilityManagerPage';
import { RoomComparePage } from './pages/RoomComparePage';
import { LoginPage } from './pages/LoginPage';
import { MainPage } from './pages/MainPage';
import { Monogram, Wordmark } from './components/Brand';

function App() {
  const [user, setUser] = useState<any>(null); // 로그인한 유저 정보 상태

  const handleLogout = () => {
    setUser(null);
  };

  // 관리자 권한 체크용 상수
  const isAdmin = user && (user.role === 'ADMIN' || user.role === 'DEVELOPER');

  const navLinkStyle = ({ isActive }: { isActive: boolean }) =>
    `nav-link${isActive ? ' active' : ''}`;

  return (
    <Router>
      <div style={{ display: 'flex', flexDirection: 'column', height: '100vh', boxSizing: 'border-box' }}>

        {/* 헤더 */}
        <header
          style={{
            display: 'flex',
            justifyContent: 'space-between',
            alignItems: 'center',
            padding: '14px 24px',
            borderBottom: '1px solid var(--border)',
            background: 'var(--surface)',
          }}
        >
          <div style={{ display: 'flex', alignItems: 'center', gap: 10 }}>
            <Monogram size={32} />
            <Wordmark size={17} />
          </div>
          {user && (
            <div style={{ display: 'flex', alignItems: 'center', gap: 14 }}>
              <span style={{ fontSize: 13, color: 'var(--text-secondary)' }}>
                {user.name} <span className="chip" style={{ marginLeft: 6 }}>{user.role}</span>
              </span>
              <button onClick={handleLogout} className="btn btn-ghost btn-sm">로그아웃</button>
            </div>
          )}
        </header>

        {/* 글로벌 네비게이션 바 (로그인한 유저에게만 노출) */}
        {user && (
          <nav
            style={{
              display: 'flex', gap: 6, alignItems: 'center',
              padding: '10px 24px',
              borderBottom: '1px solid var(--border)',
              background: 'var(--surface)',
            }}
          >
            {isAdmin && (
              <>
                <NavLink to="/main" className={navLinkStyle}>메인 대시보드</NavLink>
                <NavLink to="/mapping" className={navLinkStyle}>맵핑 관리자</NavLink>
              </>
            )}

            {/* 유저와 관리자 공통 메뉴 */}
            <NavLink to="/viewer" className={navLinkStyle}>차트 뷰어</NavLink>

            {isAdmin && (
              <>
                <NavLink to="/indexing" className={navLinkStyle}>명칭 인덱싱</NavLink>
                <NavLink to="/facility-manager" className={navLinkStyle}>시설/호실 관리</NavLink>
                <NavLink to="/compare" className={navLinkStyle}>호실 비교</NavLink>
              </>
            )}
          </nav>
        )}

        {/* 본문 영역 */}
        <div style={{ flex: 1, display: 'flex', flexDirection: 'column', overflow: 'auto', background: 'var(--bg)' }}>
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
                    <Route path="/compare" element={<RoomComparePage />} />
                  </>
                )}

                {/* User/Admin 공통 라우트 */}
                <Route path="/viewer" element={<ChartViewerPage />} />

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
