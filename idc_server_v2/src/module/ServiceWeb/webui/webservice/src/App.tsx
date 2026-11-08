import { useState, useEffect } from 'react';
import { loadSession, saveSession } from './services/session';
import type { SessionUser } from './types';
import { HashRouter as Router, Routes, Route, Navigate, NavLink } from 'react-router-dom';
import { ChartMappingPage } from './pages/ChartMappingPage';
import { ChartViewerPage }  from './pages/ChartViewerPage';
import { PRIndexingPage }    from './pages/PRIndexingPage';
import { FacilityManagerPage } from './pages/FacilityManagerPage';
import { RoomComparePage } from './pages/RoomComparePage';
import { LoginPage } from './pages/LoginPage';
import { MainPage } from './pages/MainPage';
import { OverviewPage } from './pages/OverviewPage';
import { Monogram, Wordmark } from './components/Brand';
import { ThemeProvider, ThemeToggle } from './services/theme';
import { EmployeeManagerPage } from './pages/EmployeeManagerPage';
import { apiService } from './services/apiService';

function App() {
  const [user, setUser] = useState<SessionUser | null>(loadSession);
  const [isUserAdminAnywhere, setIsUserAdminAnywhere] = useState(false);

  const handleLogin = (next: SessionUser) => {
    saveSession(next);
    setUser(next);
  };

  const handleLogout = () => {
    saveSession(null);
    setUser(null);
  };

  const isAdmin = user && (user.role === 'ADMIN' || user.role === 'DEVELOPER');

  useEffect(() => {
    if (user && !isAdmin) {
      apiService.getUserFacilities(user.id).then(res => {
        const isManager = res.facilities?.some((f: any) => f.user_admin_id === user.id);
        setIsUserAdminAnywhere(isManager || false);
      }).catch(console.error);
    }
  }, [user, isAdmin]);

  const showEmployeeMenu = isAdmin || isUserAdminAnywhere;
  const navLinkStyle = ({ isActive }: { isActive: boolean }) =>
    `nav-link${isActive ? ' active' : ''}`;

  return (
    <ThemeProvider>
      <Router>
        <div style={{ display: 'flex', flexDirection: 'column', height: '100vh', boxSizing: 'border-box' }}>

          {/* 헤더 (과거 디자인 그대로 복원) */}
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

            <div style={{ display: 'flex', alignItems: 'center', gap: 14 }}>
              {user && (
                <span style={{ fontSize: 13, color: 'var(--text-secondary)' }}>
                  {user.name} <span className="chip" style={{ marginLeft: 6 }}>{user.role}</span>
                </span>
              )}
              <ThemeToggle />
              {user && (
                <button onClick={handleLogout} className="btn btn-ghost btn-sm">
                  로그아웃
                </button>
              )}
            </div>
          </header>

          {/* 글로벌 네비게이션 바 */}
          {user && (
            <nav
              style={{
                display: 'flex', gap: 6, alignItems: 'center',
                padding: '10px 24px',
                borderBottom: '1px solid var(--border)',
                background: 'var(--surface)',
              }}
            >
              <NavLink to="/overview" className={navLinkStyle}>전체 현황</NavLink>

              {isAdmin && (
                <>
                  <NavLink to="/main" className={navLinkStyle}>메인 대시보드</NavLink>
                  <NavLink to="/mapping" className={navLinkStyle}>맵핑 관리자</NavLink>
                </>
              )}

              <NavLink to="/viewer" className={navLinkStyle}>차트 뷰어</NavLink>
              {showEmployeeMenu && (
                <NavLink to="/employees" className={navLinkStyle}>직원 관리</NavLink>
              )}

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
              <Route path="/login" element={<LoginPage onLogin={handleLogin} />} />

              {!user ? (
                <Route path="*" element={<Navigate to="/login" />} />
              ) : (
                <>
                  {isAdmin && (
                    <>
                      <Route path="/main" element={<MainPage user={user} />} />
                      <Route path="/mapping" element={<ChartMappingPage user={user} />} />
                      <Route path="/indexing" element={<PRIndexingPage user={user} />} />
                      <Route path="/facility-manager" element={<FacilityManagerPage user={user} />} />
                      <Route path="/compare" element={<RoomComparePage user={user} />} />
                    </>
                  )}

                  <Route path="/overview" element={<OverviewPage user={user} />} />
                  <Route path="/viewer" element={<ChartViewerPage user={user} />} />
                  {showEmployeeMenu && (
                    <Route path="/employees" element={<EmployeeManagerPage user={user} />} />
                  )}

                  <Route path="*" element={
                    <Navigate to={isAdmin ? "/main" : "/overview"} />
                  } />
                </>
              )}
            </Routes>
          </div>
        </div>
      </Router>
    </ThemeProvider>
  );
}

export default App;