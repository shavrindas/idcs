import React, { useState } from 'react';
import { useNavigate } from 'react-router-dom';
// import { apiService } from '../services/apiService'; // API 서비스 연동 필요

export const LoginPage: React.FC<{ onLogin: (userData: any) => void }> = ({ onLogin }) => {
  const [email, setEmail] = useState('');
  const [password, setPassword] = useState('');
  const [showDevTools, setShowDevTools] = useState(false);
  const navigate = useNavigate();

  // [개발용] 관리자 계정 주입
  const injectAdmin = () => {
    setEmail('admin1@system.com');
    setPassword('hashed_password');
  };

  // [개발용] 사용자 계정 주입
  const injectUser = () => {
    setEmail('user_a@test.com');
    setPassword('hashed_password');
  };

  const handleLogin = async (e: React.FormEvent) => {
    e.preventDefault();
    try {
      // 실제 API 호출로 대체 (예: await apiService.webLogin(email, password))
      // 테스트용 Mock 데이터:
      const mockResponse = {
        user: {
            id: 1,
            email,
            name: email.includes('admin') ? '관리자' : '일반 유저',
            role: email.includes('admin') ? 'ADMIN' : 'USER'
        }
      };

      onLogin(mockResponse.user);

      // 권한별 리다이렉트
      if (mockResponse.user.role === 'ADMIN' || mockResponse.user.role === 'DEVELOPER') {
        navigate('/main');
      } else {
        navigate('/viewer');
      }
    } catch (error) {
      alert('로그인 실패');
    }
  };

  return (
    <div style={{ display: 'flex', flexDirection: 'column', justifyContent: 'center', alignItems: 'center', flex: 1, gap: 24, padding: 24 }}>

      <div style={{ display: 'flex', flexDirection: 'column', alignItems: 'center', gap: 6, marginBottom: 4 }}>
        <div
          style={{
            width: 56, height: 56, borderRadius: 16,
            background: 'var(--primary)', color: '#fff',
            display: 'flex', alignItems: 'center', justifyContent: 'center',
            fontSize: 26, boxShadow: '0 12px 24px -8px rgba(46,107,239,0.35)',
          }}
        >
          ❄
        </div>
        <h1 style={{ fontSize: 20 }}>IDCool Systems Console</h1>
        <p style={{ color: 'var(--text-secondary)', fontSize: 13 }}>관리자 계정으로 로그인해주세요.</p>
      </div>

      <form onSubmit={handleLogin} className="card" style={{ display: 'flex', flexDirection: 'column', gap: 14, width: 320 }}>
        <input
          type="email"
          placeholder="이메일"
          value={email}
          onChange={e => setEmail(e.target.value)}
          required
          className="input"
        />
        <input
          type="password"
          placeholder="비밀번호"
          value={password}
          onChange={e => setPassword(e.target.value)}
          required
          className="input"
        />
        <button type="submit" className="btn btn-primary" style={{ height: 44 }}>
          로그인
        </button>
      </form>

      {/* 개발용 계정 주입 도구 (기본 접힘) */}
      <div style={{ width: 320 }}>
        <button
          type="button"
          onClick={() => setShowDevTools(v => !v)}
          className="btn btn-ghost btn-sm"
          style={{ width: '100%' }}
        >
          {showDevTools ? '▲' : '▼'} 개발자 도구 (DEBUG 전용)
        </button>
        {showDevTools && (
          <div style={{ display: 'flex', gap: 8, marginTop: 8 }}>
            <button type="button" onClick={injectAdmin} className="btn btn-outline btn-sm" style={{ flex: 1 }}>
              관리자 계정 주입
            </button>
            <button type="button" onClick={injectUser} className="btn btn-outline btn-sm" style={{ flex: 1 }}>
              사용자 계정 주입
            </button>
          </div>
        )}
      </div>
    </div>
  );
};
