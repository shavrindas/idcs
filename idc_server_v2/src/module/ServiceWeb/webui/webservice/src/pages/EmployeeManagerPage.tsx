import React, { useState, useEffect } from 'react';
import { apiService } from '../services/apiService';
import type { SessionUser } from '../types';

export const EmployeeManagerPage: React.FC<{ user: SessionUser }> = ({ user }) => {
  const [facilities, setFacilities] = useState<any[]>([]);
  const [selectedFacilityId, setSelectedFacilityId] = useState<number | ''>('');
  
  const [employees, setEmployees] = useState<any[]>([]);
  const [userAdminId, setUserAdminId] = useState<number | null>(null);
  
  const [searchKeyword, setSearchKeyword] = useState('');
  const [newUserCode, setNewUserCode] = useState('');

  const isAdmin = user.role === 'ADMIN' || user.role === 'DEVELOPER';

  useEffect(() => {
    loadAccessibleFacilities();
  }, []);

  const loadAccessibleFacilities = async () => {
    try {
      // API에서 내가 속한(또는 조회 가능한) 시설 목록을 가져옵니다.
      const res = await apiService.getUserFacilities(user.id);
      setFacilities(res.facilities || []);
      
      // user_admin이라면 본인 시설을 바로 선택하도록 처리
      if (!isAdmin && res.facilities?.length > 0) {
        handleFacilitySelect(res.facilities[0].id);
      }
    } catch (e) {
      console.error(e);
    }
  };

  const handleFacilitySelect = async (facId: number | '') => {
    setSelectedFacilityId(facId);
    setSearchKeyword('');
    if (facId) {
      await fetchEmployees(facId);
    } else {
      setEmployees([]);
      setUserAdminId(null);
    }
  };

  const fetchEmployees = async (facId: number) => {
    try {
      const res = await apiService.getFacilityEmployeesWeb(facId, user.id);
      setEmployees(res.employees || []);
      setUserAdminId(res.user_admin_id);
    } catch (e: any) {
      alert(e.message || '직원 목록을 불러오지 못했습니다.');
      setEmployees([]);
    }
  };

  const handleInvite = async () => {
    if (!selectedFacilityId || !newUserCode.trim()) return;
    try {
      await apiService.inviteEmployeeWeb(Number(selectedFacilityId), user.id, newUserCode.trim());
      alert('직원이 추가되었습니다.');
      setNewUserCode('');
      fetchEmployees(Number(selectedFacilityId));
    } catch (e: any) {
      alert(e.message);
    }
  };

  const handleRemove = async (targetUserId: number, targetName: string) => {
    if (!window.confirm(`'${targetName}' 직원을 정말 해제하시겠습니까?`)) return;
    try {
      await apiService.removeEmployeeWeb(Number(selectedFacilityId), targetUserId, user.id);
      fetchEmployees(Number(selectedFacilityId));
    } catch (e: any) {
      alert(e.message);
    }
  };

  const handleSetUserAdmin = async (targetAdminId: number | null) => {
    try {
      await apiService.setUserAdminWeb(Number(selectedFacilityId), user.id, targetAdminId);
      alert('시설 관리자(user_admin)가 변경되었습니다.');
      fetchEmployees(Number(selectedFacilityId));
    } catch (e: any) {
      alert(e.message);
    }
  };

  // 렌더링용 리스트 가공 (검색 필터링 및 user_admin 상단 고정)
  const filteredEmployees = employees.filter(emp => emp.name.toLowerCase().includes(searchKeyword.toLowerCase()));
  const sortedEmployees = [...filteredEmployees].sort((a, b) => {
    if (a.id === userAdminId) return -1;
    if (b.id === userAdminId) return 1;
    return 0;
  });

  return (
    <div style={{ padding: 24, maxWidth: 800, margin: '0 auto', display: 'flex', flexDirection: 'column', gap: 20 }}>
      <h2 style={{ fontSize: 22, fontWeight: 800 }}>직원 관리</h2>

      {/* 노란 박스 (Admin 전용 영역) */}
      {isAdmin && (
        <div style={{ border: '2px solid #F59E0B', borderRadius: 8, padding: 16, display: 'flex', flexDirection: 'column', gap: 16 }}>
          <div style={{ display: 'flex', alignItems: 'center', gap: 12 }}>
            <span style={{ fontWeight: 700, color: '#F59E0B' }}>Admin 용</span>
            <select 
              className="input" 
              value={selectedFacilityId} 
              onChange={e => handleFacilitySelect(e.target.value ? Number(e.target.value) : '')}
            >
              <option value="">-- 드랍다운 [시설 선택] --</option>
              {facilities.map(f => (
                <option key={f.id} value={f.id}>{f.name}</option>
              ))}
            </select>
          </div>

          {selectedFacilityId !== '' && (
            <div style={{ display: 'flex', alignItems: 'center', gap: 12, background: '#FEF3C7', padding: 12, borderRadius: 6 }}>
              <div style={{ border: '1px solid #000', padding: '6px 12px', background: '#fff', fontSize: 13, fontWeight: 600 }}>
                항목 [user_admin]<br/>시설 관리자
              </div>
              <select 
                className="input" 
                value={userAdminId || ''} 
                onChange={e => handleSetUserAdmin(e.target.value ? Number(e.target.value) : null)}
                style={{ flex: 1 }}
              >
                <option value="">-- [지정안함 (Null)] --</option>
                {employees.map(emp => (
                  <option key={emp.id} value={emp.id}>{emp.name} (ID: {emp.id})</option>
                ))}
              </select>
            </div>
          )}
        </div>
      )}

      {/* 파란 박스 (공통 영역) */}
      {selectedFacilityId !== '' && (
        <div style={{ border: '2px solid #3B82F6', borderRadius: 8, padding: 16, display: 'flex', flexDirection: 'column', gap: 16 }}>
          <span style={{ fontWeight: 700, color: '#3B82F6' }}>user_admin 용 (공통 영역)</span>
          
          <div style={{ display: 'flex', gap: 8 }}>
            <input 
              type="text" 
              className="input" 
              placeholder="직원 이름 검색..." 
              value={searchKeyword}
              onChange={e => setSearchKeyword(e.target.value)}
              style={{ flex: 1 }}
            />
            <input 
              type="text" 
              className="input" 
              placeholder="신규 직원 코드 입력" 
              value={newUserCode}
              onChange={e => setNewUserCode(e.target.value)}
              style={{ width: 180 }}
            />
            <button className="btn btn-primary" onClick={handleInvite}>직원 추가</button>
          </div>

          <div style={{ borderTop: '1px solid #3B82F6', paddingTop: 16 }}>
            <div style={{ display: 'flex', justifyContent: 'space-between', paddingBottom: 8, color: 'var(--text-secondary)', fontSize: 13 }}>
              <span>시설 직원 리스트</span>
              <span>직원 해제</span>
            </div>

            <div style={{ display: 'flex', flexDirection: 'column', gap: 8 }}>
              {sortedEmployees.map(emp => {
                const isUserAdmin = emp.id === userAdminId;
                return (
                  <div key={emp.id} style={{ 
                    display: 'flex', justifyContent: 'space-between', alignItems: 'center', 
                    border: isUserAdmin ? '2px solid #10B981' : '1px solid var(--border)', 
                    padding: '10px 16px', borderRadius: 8,
                    background: isUserAdmin ? '#ECFDF5' : 'var(--surface)'
                  }}>
                    <div style={{ display: 'flex', alignItems: 'center', gap: 12 }}>
                      <span style={{ fontWeight: 700, width: 120 }}>
                        {isUserAdmin ? '고정 항목 [user_admin]' : '직원 항목 [user]'}
                      </span>
                      <span style={{ color: 'var(--error)', fontWeight: 600, fontSize: 13 }}>ID: {emp.id}</span>
                      <span style={{ fontSize: 15 }}>{emp.name}</span>
                      <span style={{ fontSize: 12, color: 'var(--text-secondary)' }}>({emp.email})</span>
                    </div>
                    
                    {!isUserAdmin && (
                      <button 
                        onClick={() => handleRemove(emp.id, emp.name)} 
                        className="btn btn-ghost"
                        style={{ color: 'var(--error)', padding: '4px 8px' }}
                      >
                        ✕
                      </button>
                    )}
                  </div>
                );
              })}
              {sortedEmployees.length === 0 && (
                <div style={{ textAlign: 'center', padding: 20, color: 'var(--text-secondary)' }}>
                  직원이 없습니다.
                </div>
              )}
            </div>
          </div>
        </div>
      )}
    </div>
  );
};