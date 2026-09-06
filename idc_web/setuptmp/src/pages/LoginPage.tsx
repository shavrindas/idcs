import React, { useState } from 'react';
import { useNavigate } from 'react-router-dom';
import { apiService } from '../services/apiService';
import { Monogram, Wordmark } from '../components/Brand';

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
      const loginRes = await apiService.login(email, password);
      const profile = await apiService.getUserProfile(loginRes.user_id);

      const user = {
        id: loginRes.user_id,
        email,
        name: profile.name,
        role: loginRes.role,
      };

      onLogin(user);

      // 권한별 리다이렉트
      if (user.role === 'ADMIN' || user.role === 'DEVELOPER') {
        navigate('/main');
      } else {
        navigate('/viewer');
      }
    } catch (error: any) {
      alert(error.message || '로그인 실패');
    }
  };

  return (
    <div style={{ display: 'flex', flexDirection: 'column', justifyContent: 'center', alignItems: 'center', flex: 1, gap: 24, padding: 24 }}>

      <div style={{ display: 'flex', flexDirection: 'column', alignItems: 'center', gap: 10, marginBottom: 4 }}>
        <Monogram size={56} />
        <div style={{ marginTop: 4 }}><Wordmark size={22} /></div>
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
