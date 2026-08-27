import React, { useState } from 'react';
import { useNavigate } from 'react-router-dom';
// import { apiService } from '../services/apiService'; // API 서비스 연동 필요

export const LoginPage: React.FC<{ onLogin: (userData: any) => void }> = ({ onLogin }) => {
  const [email, setEmail] = useState('');
  const [password, setPassword] = useState('');
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
    <div style={{ display: 'flex', flexDirection: 'column', justifyContent: 'center', alignItems: 'center', height: '100vh', gap: 20 }}>
      
      {/* 개발용 계정 주입 버튼 영역 */}
      <div style={{ display: 'flex', gap: 10, padding: 10, border: '1px dashed #ff9800', backgroundColor: '#332b1a', borderRadius: 8 }}>
        <button type="button" onClick={injectAdmin} style={{ padding: '8px 12px', backgroundColor: '#ff9800', color: '#fff', border: 'none', cursor: 'pointer', borderRadius: 4 }}>
          [개발] 관리자 계정 주입
        </button>
        <button type="button" onClick={injectUser} style={{ padding: '8px 12px', backgroundColor: '#2196f3', color: '#fff', border: 'none', cursor: 'pointer', borderRadius: 4 }}>
          [개발] 사용자 계정 주입
        </button>
      </div>

      <form onSubmit={handleLogin} style={{ display: 'flex', flexDirection: 'column', gap: 15, padding: 30, border: '1px solid #555', backgroundColor: '#222', minWidth: 300, borderRadius: 8 }}>
        <h2 style={{ color: '#4caf50', margin: 0, textAlign: 'center' }}>IDCool Web Login</h2>
        <input 
          type="email" 
          placeholder="이메일" 
          value={email} 
          onChange={e => setEmail(e.target.value)} 
          required 
          style={{ padding: 10, backgroundColor: '#333', color: '#fff', border: '1px solid #444', borderRadius: 4 }} 
        />
        <input 
          type="password" 
          placeholder="비밀번호" 
          value={password} 
          onChange={e => setPassword(e.target.value)} 
          required 
          style={{ padding: 10, backgroundColor: '#333', color: '#fff', border: '1px solid #444', borderRadius: 4 }} 
        />
        <button type="submit" style={{ padding: 12, backgroundColor: '#4caf50', color: 'white', border: 'none', cursor: 'pointer', borderRadius: 4, fontWeight: 'bold' }}>
          로그인
        </button>
      </form>
    </div>
  );
};