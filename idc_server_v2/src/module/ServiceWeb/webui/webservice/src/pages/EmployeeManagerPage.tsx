import React, { useState, useEffect } from 'react';
import { apiService } from '../services/apiService';
import type { SessionUser } from '../types';

type Employee = {
  id: number;
  name: string;
  email: string;
  user_code?: string;
  role?: string;
  can_control_device?: boolean;
  can_manage_board?: boolean;
  can_manage_alarm?: boolean;
};

const Avatar: React.FC<{ name: string; highlight?: boolean }> = ({ name, highlight }) => (
  <div
    style={{
      width: 38,
      height: 38,
      borderRadius: '50%',
      flexShrink: 0,
      display: 'flex',
      alignItems: 'center',
      justifyContent: 'center',
      fontSize: 14,
      fontWeight: 800,
      background: highlight ? 'var(--primary-bg)' : 'var(--bg)',
      color: highlight ? 'var(--primary)' : 'var(--text-secondary)',
      border: highlight ? '1px solid var(--primary-light)' : '1px solid var(--border)',
    }}
  >
    {name.trim().charAt(0).toUpperCase() || '?'}
  </div>
);

export const EmployeeManagerPage: React.FC<{ user: SessionUser }> = ({ user }) => {
  const [facilities, setFacilities] = useState<any[]>([]);
  const [selectedFacilityId, setSelectedFacilityId] = useState<number | ''>('');

  const [employees, setEmployees] = useState<Employee[]>([]);
  const [userAdminId, setUserAdminId] = useState<number | null>(null);

  const [searchKeyword, setSearchKeyword] = useState('');
  const [newUserCode, setNewUserCode] = useState('');

  const [loadingFacilities, setLoadingFacilities] = useState(true);
  const [loadingEmployees, setLoadingEmployees] = useState(false);

  const isAdmin = user.role === 'ADMIN' || user.role === 'DEVELOPER';

  useEffect(() => {
    loadAccessibleFacilities();
  }, []);

  const loadAccessibleFacilities = async () => {
    setLoadingFacilities(true);
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
    } finally {
      setLoadingFacilities(false);
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
    setLoadingEmployees(true);
    try {
      const res = await apiService.getFacilityEmployeesWeb(facId, user.id);
      setEmployees(res.employees || []);
      setUserAdminId(res.user_admin_id);
    } catch (e: any) {
      alert(e.message || '직원 목록을 불러오지 못했습니다.');
      setEmployees([]);
    } finally {
      setLoadingEmployees(false);
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
      fetchEmployees(Number(selectedFacilityId));
    } catch (e: any) {
      alert(e.message);
    }
  };

  const handleTogglePermission = async (emp: Employee, field: 'can_control_device' | 'can_manage_board' | 'can_manage_alarm') => {
    const next = { ...emp, [field]: !emp[field] };
    // 응답을 기다리지 않고 먼저 반영 — 실패하면 아래서 되돌린다.
    setEmployees(prev => prev.map(e => (e.id === emp.id ? next : e)));
    try {
      await apiService.updateEmployeePermissionsWeb(Number(selectedFacilityId), user.id, emp.id, {
        can_control_device: next.can_control_device ?? false,
        can_manage_board: next.can_manage_board ?? false,
        can_manage_alarm: next.can_manage_alarm ?? false,
      });
    } catch (e: any) {
      alert(e.message || '권한 수정 실패');
      setEmployees(prev => prev.map(ev => (ev.id === emp.id ? emp : ev)));
    }
  };

  // 렌더링용 리스트 가공 (검색 필터링 및 user_admin 상단 고정)
  const filteredEmployees = employees.filter(emp => emp.name.toLowerCase().includes(searchKeyword.toLowerCase()));
  const sortedEmployees = [...filteredEmployees].sort((a, b) => {
    if (a.id === userAdminId) return -1;
    if (b.id === userAdminId) return 1;
    return 0;
  });

  const selectedFacility = facilities.find(f => f.id === selectedFacilityId);

  return (
    <div style={{ padding: 24, maxWidth: 820, margin: '0 auto', display: 'flex', flexDirection: 'column', gap: 16, boxSizing: 'border-box' }}>
      <div style={{ display: 'flex', alignItems: 'center', gap: 12 }}>
        <div
          style={{
            width: 40, height: 40, borderRadius: 12, flexShrink: 0,
            display: 'flex', alignItems: 'center', justifyContent: 'center',
            background: 'var(--primary-bg)', color: 'var(--primary)', fontSize: 18,
          }}
        >
          👥
        </div>
        <div>
          <h1 style={{ fontSize: 22, fontWeight: 800, letterSpacing: -0.3 }}>직원 관리</h1>
          {selectedFacility && (
            <p style={{ fontSize: 13, color: 'var(--text-secondary)', marginTop: 2 }}>{selectedFacility.name}</p>
          )}
        </div>
      </div>

      {isAdmin && (
        <div className="card" style={{ display: 'flex', flexDirection: 'column', gap: 12 }}>
          <div style={{ display: 'flex', flexDirection: 'column', gap: 6 }}>
            <span className="label">시설 선택</span>
            <select
              className="input"
              value={selectedFacilityId}
              onChange={e => handleFacilitySelect(e.target.value ? Number(e.target.value) : '')}
            >
              <option value="">시설을 선택하세요</option>
              {facilities.map(f => (
                <option key={f.id} value={f.id}>{f.name}</option>
              ))}
            </select>
          </div>

          {selectedFacilityId !== '' && (
            <div style={{ display: 'flex', flexDirection: 'column', gap: 6 }}>
              <span className="label">수석 관리자</span>
              <select
                className="input"
                value={userAdminId || ''}
                onChange={e => handleSetUserAdmin(e.target.value ? Number(e.target.value) : null)}
              >
                <option value="">지정 안 함</option>
                {employees.map(emp => (
                  <option key={emp.id} value={emp.id}>{emp.name} (ID: {emp.id})</option>
                ))}
              </select>
            </div>
          )}
        </div>
      )}

      {loadingFacilities ? (
        <p style={{ color: 'var(--text-secondary)', fontSize: 13 }}>불러오는 중…</p>
      ) : selectedFacilityId !== '' && (
        <div className="card" style={{ display: 'flex', flexDirection: 'column', gap: 16 }}>
          <div style={{ display: 'flex', gap: 8, flexWrap: 'wrap' }}>
            <input
              type="text"
              className="input"
              placeholder="직원 이름 검색..."
              value={searchKeyword}
              onChange={e => setSearchKeyword(e.target.value)}
              style={{ flex: '1 1 160px' }}
            />
            <input
              type="text"
              className="input"
              placeholder="신규 직원 코드 입력"
              value={newUserCode}
              onChange={e => setNewUserCode(e.target.value)}
              style={{ flex: '0 1 180px' }}
            />
            <button className="btn btn-primary" onClick={handleInvite} style={{ flexShrink: 0 }}>
              + 직원 추가
            </button>
          </div>

          <div style={{ display: 'flex', flexDirection: 'column', gap: 10 }}>
            <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'baseline' }}>
              <span className="label">시설 직원 ({sortedEmployees.length})</span>
              {sortedEmployees.length > 0 && <span className="label" style={{ paddingRight: 4 }}>해제</span>}
            </div>

            {loadingEmployees ? (
              <p style={{ color: 'var(--text-secondary)', fontSize: 13 }}>불러오는 중…</p>
            ) : sortedEmployees.length === 0 ? (
              <div
                style={{
                  textAlign: 'center', padding: '32px 16px', color: 'var(--text-secondary)', fontSize: 13,
                  border: '1px dashed var(--border)', borderRadius: 12,
                }}
              >
                {searchKeyword ? '검색 결과가 없습니다.' : '등록된 직원이 없습니다.'}
              </div>
            ) : (
              <div style={{ display: 'flex', flexDirection: 'column', gap: 10 }}>
                {sortedEmployees.map(emp => {
                  const isUserAdmin = emp.id === userAdminId;
                  return (
                    <div
                      key={emp.id}
                      style={{
                        display: 'flex', flexDirection: 'column', gap: 10,
                        padding: '14px 16px',
                        borderRadius: 14,
                        background: 'var(--surface)',
                        border: `1px solid ${isUserAdmin ? 'var(--primary-light)' : 'var(--border)'}`,
                        boxShadow: 'var(--shadow)',
                      }}
                    >
                      <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', gap: 10 }}>
                        <div style={{ display: 'flex', alignItems: 'center', gap: 12, minWidth: 0 }}>
                          <Avatar name={emp.name} highlight={isUserAdmin} />
                          <div style={{ minWidth: 0 }}>
                            <div style={{ display: 'flex', alignItems: 'center', gap: 6, flexWrap: 'wrap' }}>
                              <span style={{ fontSize: 15, fontWeight: 700 }}>{emp.name}</span>
                              {isUserAdmin && <span className="chip">★ 수석 관리자</span>}
                            </div>
                            <span style={{ fontSize: 12, color: 'var(--text-secondary)' }}>
                              ID: {emp.id} · {emp.email}
                            </span>
                          </div>
                        </div>

                        {!isUserAdmin && (
                          <button
                            onClick={() => handleRemove(emp.id, emp.name)}
                            className="btn btn-ghost"
                            title="직원 해제"
                            style={{ color: 'var(--error)', padding: '4px 8px', flexShrink: 0 }}
                          >
                            ✕
                          </button>
                        )}
                      </div>

                      <div style={{ display: 'flex', gap: 6, flexWrap: 'wrap', paddingLeft: 50 }}>
                        <button
                          className={`btn btn-toggle btn-sm ${emp.can_control_device ? 'on' : ''}`}
                          onClick={() => handleTogglePermission(emp, 'can_control_device')}
                        >
                          기기 제어
                        </button>
                        <button
                          className={`btn btn-toggle btn-sm ${emp.can_manage_board ? 'on' : ''}`}
                          onClick={() => handleTogglePermission(emp, 'can_manage_board')}
                        >
                          게시판 관리
                        </button>
                        <button
                          className={`btn btn-toggle btn-sm ${emp.can_manage_alarm ? 'on' : ''}`}
                          onClick={() => handleTogglePermission(emp, 'can_manage_alarm')}
                        >
                          알람 관리
                        </button>
                      </div>
                    </div>
                  );
                })}
              </div>
            )}
          </div>
        </div>
      )}
    </div>
  );
};
