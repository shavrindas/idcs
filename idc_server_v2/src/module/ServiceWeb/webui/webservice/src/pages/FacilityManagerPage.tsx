import React, { useState, useEffect } from 'react';
import { apiService } from '../services/apiService';
import type { SessionUser } from '../types';

export const FacilityManagerPage: React.FC<{ user: SessionUser }> = ({ user }) => {
  const [facilities, setFacilities] = useState<any[]>([]);
  const [rooms, setRooms] = useState<any[]>([]);
  const [users, setUsers] = useState<any[]>([]);
  const [selectedFacility, setSelectedFacility] = useState<number | ''>('');

  // 호실별 접기/펼치기 상태 및 역할 캐시
  const [expandedRoomIds, setExpandedRoomIds] = useState<number[]>([]);
  const [roomRolesMap, setRoomRolesMap] = useState<Record<number, any[]>>({});

  // 선택 및 수정 상태
  const [selectedRoom, setSelectedRoom] = useState<any | null>(null);
  const [selectedRole, setSelectedRole] = useState<any | null>(null);
  const [editFac, setEditFac] = useState<any>(null);

  // 생성 폼 상태
  const [newFac, setNewFac] = useState({ name: '', access_code: '', start_date: '', end_date: '' });
  const [newRoomName, setNewRoomName] = useState('');
  const [newRole, setNewRole] = useState({
    role_name: '', display_name: '', short_name: '', data_type: 'TEMP',
    target_value: '', target_low_limit: '', target_high_limit: '', valid_from: '', valid_to: ''
  });

  // 검색창
  const [searchInput, setSearchInput] = useState('');
  const [suggestions, setSuggestions] = useState<any[]>([]);

  const loadFacilities = async () => {
    const res = await apiService.getAllFacilitiesAdmin(user.id);
    setFacilities(res.facilities || []);
  };

  const loadRoomsAndUsers = async (facId: number) => {
    const rRes = await apiService.getRooms(facId);
    setRooms(rRes.rooms || []);
    const uRes = await apiService.getFacilityUsersAdmin(facId);
    setUsers(uRes.users || []);
  };

  const loadRolesForRoom = async (roomId: number) => {
    const res = await apiService.getRolesByRoomAdmin(roomId);
    setRoomRolesMap(prev => ({ ...prev, [roomId]: res.roles || [] }));
  };

  useEffect(() => { loadFacilities(); }, []);

  const handleFacilityChange = (facId: number) => {
    setSelectedFacility(facId);
    setSelectedRoom(null);
    setSelectedRole(null);
    setExpandedRoomIds([]);
    setRoomRolesMap({});
    const target = facilities.find(f => f.id === facId);
    setEditFac(target ? { ...target, start_date: target.start_date || '', end_date: target.end_date || '' } : null);
    if (facId) loadRoomsAndUsers(facId);
    else { setRooms([]); setUsers([]); }
  };

  const toggleRoomExpand = (roomId: number, e: React.MouseEvent) => {
    e.stopPropagation();
    if (expandedRoomIds.includes(roomId)) {
      setExpandedRoomIds(prev => prev.filter(id => id !== roomId));
    } else {
      setExpandedRoomIds(prev => [...prev, roomId]);
      if (!roomRolesMap[roomId]) loadRolesForRoom(roomId);
    }
  };

  // 하향식 검색
  useEffect(() => {
    const q = searchInput.trim().toLowerCase();
    if (!q) { setSuggestions([]); return; }
    const res: any[] = [];
    facilities.forEach(f => {
      if (f.name.toLowerCase().includes(q)) res.push({ type: 'facility', id: f.id, label: `[시설] ${f.name}` });
    });
    if (selectedFacility) {
      rooms.forEach(r => {
        if (r.name.toLowerCase().includes(q)) res.push({ type: 'room', id: r.id, raw: r, label: `[호실] ${r.name}` });
      });
    }
    setSuggestions(res.slice(0, 10));
  }, [searchInput, facilities, rooms, selectedFacility]);

  const handleApplySuggestion = (sug: any) => {
    if (sug.type === 'facility') handleFacilityChange(sug.id);
    else if (sug.type === 'room') {
      setSelectedRoom(sug.raw);
      setSelectedRole(null);
      if (!expandedRoomIds.includes(sug.id)) {
        setExpandedRoomIds(prev => [...prev, sug.id]);
        loadRolesForRoom(sug.id);
      }
    }
    setSearchInput('');
    setSuggestions([]);
  };

  // 핸들러들
  const handleCreateFacility = async () => {
    if (!newFac.name || !newFac.access_code) return alert('시설명과 접근 코드는 필수입니다.');
    await apiService.createFacilityAdmin(user.id, newFac);
    alert('시설이 추가되었습니다.');
    setNewFac({ name: '', access_code: '', start_date: '', end_date: '' });
    loadFacilities();
  };

  const handleUpdateFacility = async () => {
    if (!editFac) return;
    await apiService.updateFacilityAdmin(editFac.id, editFac);
    alert('시설 정보가 수정되었습니다.');
    loadFacilities();
  };

  const handleCreateRoom = async () => {
    if (!selectedFacility || !newRoomName) return alert('호실명을 입력하세요.');
    await apiService.createRoomAdmin(Number(selectedFacility), { name: newRoomName });
    setNewRoomName('');
    loadRoomsAndUsers(Number(selectedFacility));
  };

  const handleUpdateRoom = async () => {
    if (!selectedRoom) return;
    await apiService.updateRoomAdmin(selectedRoom.id, selectedRoom);
    alert('호실 정보 수정 완료');
    loadRoomsAndUsers(Number(selectedFacility));
  };

  const handleDeleteRoom = async (roomId: number) => {
    try {
      if (!window.confirm('정말 삭제하시겠습니까?')) return;
      await apiService.deleteRoomAdmin(roomId);
      if (selectedRoom?.id === roomId) setSelectedRoom(null);
      loadRoomsAndUsers(Number(selectedFacility));
    } catch (e: any) {
      alert(e.message || '삭제 실패');
    }
  };

  const handleCreateRole = async () => {
    if (!selectedFacility || !selectedRoom || !newRole.role_name) return alert('기능 명칭을 입력하세요.');
    try {
      await apiService.createPointRoleAdmin(Number(selectedFacility), selectedRoom.id, newRole);
      alert('포인트 롤이 생성되었습니다.');
      setNewRole({
        role_name: '', display_name: '', short_name: '', data_type: 'TEMP',
        target_value: '', target_low_limit: '', target_high_limit: '', valid_from: '', valid_to: ''
      });
      loadRolesForRoom(selectedRoom.id);
    } catch (e: any) {
      alert(e.message || '생성 실패');
    }
  };

  const handleUpdateRole = async () => {
    if (!selectedRole) return;
    try {
      await apiService.updatePointRoleAdmin(selectedRole.role_id, selectedRole);
      alert('포인트 롤이 수정되었습니다.');
      loadRolesForRoom(selectedRole.room_id);
    } catch (e: any) {
      alert(e.message || '수정 실패');
    }
  };

  const handleDeleteRole = async (roleId: number, roomId: number) => {
    if (!window.confirm('포인트 롤을 삭제하시겠습니까?')) return;
    await apiService.deletePointRoleAdmin(roleId);
    if (selectedRole?.role_id === roleId) setSelectedRole(null);
    loadRolesForRoom(roomId);
  };

  return (
    <div style={{ display: 'flex', flexDirection: 'column', height: '100%', minHeight: 0, gap: 12, padding: 24, boxSizing: 'border-box' }}>

      <h1 style={{ fontSize: 24, fontWeight: 800, letterSpacing: -0.3, flexShrink: 0 }}>시설 / 호실 관리</h1>

      {/* 1. 상단 하향식 검색바 */}
      <div className="card" style={{ position: 'relative', padding: 8, flexShrink: 0 }}>
        <input
          type="text" placeholder="시설 → 호실 검색 후 Enter"
          value={searchInput} onChange={e => setSearchInput(e.target.value)}
          onKeyDown={e => { if (e.key === 'Enter' && suggestions.length > 0) handleApplySuggestion(suggestions[0]); }}
          className="input"
        />
        {suggestions.length > 0 && (
          <div className="card" style={{ position: 'absolute', top: 'calc(100% + 4px)', left: 8, right: 8, zIndex: 10, padding: 6 }}>
            {suggestions.map((sug, idx) => (
              <div
                key={idx}
                onClick={() => handleApplySuggestion(sug)}
                style={{ padding: '8px 10px', cursor: 'pointer', borderRadius: 8, color: 'var(--primary)', fontSize: 13, fontWeight: 600 }}
                onMouseEnter={(e) => (e.currentTarget.style.background = 'var(--primary-bg)')}
                onMouseLeave={(e) => (e.currentTarget.style.background = 'transparent')}
              >
                {sug.label}
              </div>
            ))}
          </div>
        )}
      </div>

      {/* 2. 시설/호실/포인트롤 매니저 3단 레이아웃 */}
      {/* 세 패널의 최소 너비 합이 창 너비보다 커지면 전체 페이지 대신 이 영역만 가로 스크롤되도록 함 */}
      <div style={{ display: 'flex', gap: 12, flex: 1, minHeight: 0, overflowX: 'auto' }}>

        {/* [1열] 시설 관리 패널 */}
        <div className="card" style={{ flex: 1, minWidth: 260, display: 'flex', flexDirection: 'column', gap: 10, minHeight: 0 }}>
          <h4 style={{ fontSize: 16, fontWeight: 800 }}>시설 관리</h4>

          <select value={selectedFacility} onChange={e => handleFacilityChange(Number(e.target.value))} className="input">
            <option value="">-- [시설 선택] --</option>
            {facilities.map(f => (
              <option key={f.id} value={f.id}>
                {f.name} ({f.access_code}) [{f.is_active ? '운영중' : '숨김/만료'}]
              </option>
            ))}
          </select>

          {editFac ? (
            <div style={{ display: 'flex', flexDirection: 'column', gap: 6, borderTop: '1px solid var(--border)', paddingTop: 10 }}>
              <span className="label">선택 시설 수정 ({editFac.is_active ? 'Active' : 'Inactive'})</span>
              <input type="text" placeholder="시설 이름" value={editFac.name} onChange={e => setEditFac({ ...editFac, name: e.target.value })} className="input" style={{ height: 36 }} />
              <input type="text" placeholder="접근 코드" value={editFac.access_code} onChange={e => setEditFac({ ...editFac, access_code: e.target.value })} className="input" style={{ height: 36 }} />
              <label style={{ fontSize: 11, color: 'var(--text-secondary)' }}>(계약-숨김) 시작일</label>
              <input type="date" value={editFac.start_date || ''} onChange={e => setEditFac({ ...editFac, start_date: e.target.value })} className="input" style={{ height: 36 }} />
              <label style={{ fontSize: 11, color: 'var(--text-secondary)' }}>(계약-숨김) 종료일</label>
              <input type="date" value={editFac.end_date || ''} onChange={e => setEditFac({ ...editFac, end_date: e.target.value })} className="input" style={{ height: 36 }} />
              <button onClick={handleUpdateFacility} className="btn btn-primary" style={{ marginTop: 2 }}>시설 갱신</button>
            </div>
          ) : (
            <div style={{ display: 'flex', flexDirection: 'column', gap: 6, borderTop: '1px solid var(--border)', paddingTop: 10 }}>
              <span className="label">신규 시설 등록</span>
              <input type="text" placeholder="시설 이름" value={newFac.name} onChange={e => setNewFac({ ...newFac, name: e.target.value })} className="input" style={{ height: 36 }} />
              <input type="text" placeholder="접근 코드" value={newFac.access_code} onChange={e => setNewFac({ ...newFac, access_code: e.target.value })} className="input" style={{ height: 36 }} />
              <input type="date" value={newFac.start_date} onChange={e => setNewFac({ ...newFac, start_date: e.target.value })} className="input" style={{ height: 36 }} />
              <input type="date" value={newFac.end_date} onChange={e => setNewFac({ ...newFac, end_date: e.target.value })} className="input" style={{ height: 36 }} />
              <button onClick={handleCreateFacility} className="btn btn-primary" style={{ marginTop: 2 }}>시설 생성</button>
            </div>
          )}

          <h5 style={{ margin: '6px 0 0 0', fontSize: 12, fontWeight: 700, color: 'var(--text-secondary)' }}>소속 유저 ({users.length}명)</h5>
          <div style={{ flex: 1, minHeight: 0, overflowY: 'auto', background: 'var(--bg)', borderRadius: 10, padding: 8, fontSize: 12, border: '1px solid var(--border)' }}>
            {users.map(u => (
              <div key={u.id} style={{ borderBottom: '1px solid var(--border)', padding: '4px 0' }}>
                <strong style={{ color: 'var(--primary)' }}>{u.name}</strong> ({u.email})
              </div>
            ))}
          </div>
        </div>

        {/* [2열] 호실 트리 및 관리 */}
        <div className="card" style={{ flex: 1.8, minWidth: 340, display: 'flex', flexDirection: 'column', gap: 10, minHeight: 0 }}>
          <h4 style={{ fontSize: 16, fontWeight: 800 }}>호실 및 포인트 롤 트리</h4>

          <div style={{ display: 'flex', gap: 6, flexShrink: 0 }}>
            <input type="text" placeholder="새 호실 명칭" value={newRoomName} onChange={e => setNewRoomName(e.target.value)} disabled={!selectedFacility} className="input" style={{ flex: 1, height: 36 }} />
            <button onClick={handleCreateRoom} disabled={!selectedFacility} className="btn btn-primary btn-sm" style={{ whiteSpace: 'nowrap' }}>호실 추가</button>
          </div>

          <div style={{ flex: 1, minHeight: 0, overflowY: 'auto', border: '1px solid var(--border)', borderRadius: 10, background: 'var(--bg)', padding: 8 }}>
            {rooms.map(r => {
              const isExpanded = expandedRoomIds.includes(r.id);
              const isSelected = selectedRoom?.id === r.id;
              const isCommonRoom = r.name.includes('000호') || r.name.includes('공용');
              const roles = roomRolesMap[r.id] || [];

              return (
                <div key={r.id} className="card" style={{ marginBottom: 6, padding: 0, borderColor: isSelected ? 'var(--primary)' : 'var(--border)', overflow: 'hidden' }}>
                  <div
                    onClick={() => { setSelectedRoom({ ...r }); setSelectedRole(null); }}
                    style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', padding: '8px 12px', cursor: 'pointer', background: isSelected ? 'var(--primary-bg)' : 'transparent' }}
                  >
                    <div style={{ display: 'flex', alignItems: 'center', gap: 8 }}>
                      <span onClick={(e) => toggleRoomExpand(r.id, e)} style={{ cursor: 'pointer', fontSize: 13, userSelect: 'none', color: 'var(--text-secondary)' }}>
                        {isExpanded ? '▼' : '▶'}
                      </span>
                      <strong style={{ fontSize: 13 }}>{r.name}</strong>
                      <span style={{ fontSize: 11, color: 'var(--text-secondary)' }}>[{r.status}]</span>
                    </div>
                    <div>
                      {!isCommonRoom && (
                        <button onClick={(e) => { e.stopPropagation(); handleDeleteRoom(r.id); }} className="btn btn-danger btn-sm" style={{ height: 26, padding: '0 8px' }}>삭제</button>
                      )}
                    </div>
                  </div>

                  {/* 호실 하위 포인트롤 리스트 (접기/펼치기) */}
                  {isExpanded && (
                    <div style={{ padding: '8px 12px 8px 30px', borderTop: '1px solid var(--border)' }}>
                      {roles.map(role => (
                        <div
                          key={role.role_id}
                          onClick={(e) => { e.stopPropagation(); setSelectedRole({ ...role }); }}
                          style={{
                            display: 'flex', justifyContent: 'space-between', alignItems: 'center',
                            padding: '5px 8px', marginBottom: 3, fontSize: 12, borderRadius: 8, cursor: 'pointer',
                            backgroundColor: selectedRole?.role_id === role.role_id ? 'var(--primary-bg)' : 'transparent',
                            color: role.is_current ? 'var(--text)' : 'var(--text-secondary)'
                          }}
                        >
                          <div style={{ display: 'flex', alignItems: 'center', gap: 6, overflow: 'hidden', textOverflow: 'ellipsis', whiteSpace: 'nowrap' }}>
                            <span className="chip" style={{ fontSize: 10, padding: '1px 6px', background: 'var(--surface)' }}>{role.short_name || 'N/A'}</span>
                            <span style={{ fontWeight: 600 }}>{role.display_name || role.role_name}</span>
                            <span style={{ fontSize: 10, color: 'var(--text-secondary)' }}>({role.role_name})</span>
                          </div>
                          <div style={{ display: 'flex', gap: 6, alignItems: 'center', flexShrink: 0 }}>
                            <span style={{ fontSize: 10, fontWeight: 700, color: role.is_current ? '#2fae66' : 'var(--error)' }}>
                              {role.is_current ? 'Active' : 'Expired'}
                            </span>
                            <button onClick={(e) => { e.stopPropagation(); handleDeleteRole(role.role_id, r.id); }} style={{ background: 'transparent', border: 'none', color: 'var(--error)', cursor: 'pointer', fontSize: 12 }}>✕</button>
                          </div>
                        </div>
                      ))}
                      {roles.length === 0 && <span style={{ fontSize: 11, color: 'var(--text-secondary)' }}>등록된 포인트 롤이 없습니다.</span>}
                    </div>
                  )}
                </div>
              );
            })}
          </div>

          {selectedRoom && (
            <div style={{ display: 'flex', gap: 6, alignItems: 'center', borderTop: '1px solid var(--border)', paddingTop: 10, flexShrink: 0 }}>
              <span style={{ fontSize: 12, color: 'var(--text-secondary)', whiteSpace: 'nowrap' }}>호실 수정:</span>
              <input type="text" value={selectedRoom.name} onChange={e => setSelectedRoom({ ...selectedRoom, name: e.target.value })} className="input" style={{ flex: 1, height: 36 }} />
              <select value={selectedRoom.status} onChange={e => setSelectedRoom({ ...selectedRoom, status: e.target.value })} className="input" style={{ height: 36, width: 160 }}>
                <option value="OPERATING">OPERATING</option>
                <option value="MAINTENANCE">MAINTENANCE</option>
                <option value="NOT_OPERATING">NOT_OPERATING</option>
              </select>
              <button onClick={handleUpdateRoom} className="btn btn-primary btn-sm" style={{ whiteSpace: 'nowrap' }}>저장</button>
            </div>
          )}
        </div>

        {/* [3열] 포인트 롤 등록 및 수정 패널 */}
        <div className="card" style={{ flex: 1.2, minWidth: 280, display: 'flex', flexDirection: 'column', gap: 10, minHeight: 0 }}>
          <h4 style={{ fontSize: 16, fontWeight: 800, flexShrink: 0 }}>
            포인트 롤 관리 {selectedRoom ? `(${selectedRoom.name})` : ''}
          </h4>

          {selectedRole ? (
            <div style={{ display: 'flex', flexDirection: 'column', gap: 6, overflowY: 'auto', flex: 1, minHeight: 0 }}>
              <div style={{ display: 'flex', justifyContent: 'space-between', flexShrink: 0 }}>
                <span className="label">선택 포인트롤 수정</span>
                <span style={{ fontSize: 11, fontWeight: 700, color: selectedRole.is_current ? '#2fae66' : 'var(--error)' }}>
                  {selectedRole.is_current ? '운영 중 (Active)' : '만료/숨김 (Inactive)'}
                </span>
              </div>
              <input type="text" value={selectedRole.role_name} disabled className="input" style={{ height: 36 }} title="기능명칭은 수정 불가" />
              <input type="text" placeholder="디스플레이 명칭" value={selectedRole.display_name || ''} onChange={e => setSelectedRole({ ...selectedRole, display_name: e.target.value })} className="input" style={{ height: 36 }} />
              <input type="text" maxLength={3} placeholder="약어 명칭 (3자)" value={selectedRole.short_name || ''} onChange={e => setSelectedRole({ ...selectedRole, short_name: e.target.value.toUpperCase() })} className="input" style={{ height: 36, color: 'var(--primary)', fontWeight: 700 }} />
              <select value={selectedRole.data_type || 'TEMP'} onChange={e => setSelectedRole({ ...selectedRole, data_type: e.target.value })} className="input" style={{ height: 36 }}>
                <option value="TEMP">TEMP</option><option value="GEAR">GEAR</option><option value="BOOL">BOOL</option><option value="STATIC">STATIC</option>
              </select>
              <input type="text" placeholder="목표 수치 (target_value)" value={selectedRole.target_value || ''} onChange={e => setSelectedRole({ ...selectedRole, target_value: e.target.value })} className="input" style={{ height: 36 }} />
              <div style={{ display: 'flex', gap: 6, flexWrap: 'wrap' }}>
                <input
                    type="text"
                    placeholder="하한 (low_limit)"
                    value={selectedRole.target_low_limit || ''}
                    onChange={e => setSelectedRole({ ...selectedRole, target_low_limit: e.target.value })}
                    className="input"
                    style={{ flex: 1, minWidth: 0, height: 36 }}
                />
                <input
                    type="text"
                    placeholder="상한 (high_limit)"
                    value={selectedRole.target_high_limit || ''}
                    onChange={e => setSelectedRole({ ...selectedRole, target_high_limit: e.target.value })}
                    className="input"
                    style={{ flex: 1, minWidth: 0, height: 36 }}
                />
              </div>
              <label style={{ fontSize: 11, color: 'var(--text-secondary)' }}>적용 시작 일시 (valid_from)</label>
              <input type="datetime-local" value={selectedRole.valid_from ? selectedRole.valid_from.slice(0, 16) : ''} onChange={e => setSelectedRole({ ...selectedRole, valid_from: e.target.value })} className="input" style={{ height: 36 }} />
              <label style={{ fontSize: 11, color: 'var(--text-secondary)' }}>적용 종료 일시 (valid_to - 미입력 시 계속 활성화)</label>
              <input type="datetime-local" value={selectedRole.valid_to ? selectedRole.valid_to.slice(0, 16) : ''} onChange={e => setSelectedRole({ ...selectedRole, valid_to: e.target.value })} className="input" style={{ height: 36 }} />
              <div style={{ display: 'flex', gap: 6, marginTop: 4, flexShrink: 0 }}>
                <button onClick={handleUpdateRole} className="btn btn-primary" style={{ flex: 1 }}>롤 정보 수정</button>
                <button onClick={() => setSelectedRole(null)} className="btn btn-ghost">취소</button>
              </div>
            </div>
          ) : (
            <div style={{ display: 'flex', flexDirection: 'column', gap: 6, overflowY: 'auto', flex: 1, minHeight: 0 }}>
              <span className="label">신규 포인트 롤 추가</span>
              <input type="text" placeholder="기능 명칭 (role_name: 고유 식별)" value={newRole.role_name} onChange={e => setNewRole({ ...newRole, role_name: e.target.value })} disabled={!selectedRoom} className="input" style={{ height: 36 }} />
              <input type="text" placeholder="디스플레이 명칭" value={newRole.display_name} onChange={e => setNewRole({ ...newRole, display_name: e.target.value })} disabled={!selectedRoom} className="input" style={{ height: 36 }} />
              <input type="text" maxLength={3} placeholder="약어 명칭 (3자)" value={newRole.short_name} onChange={e => setNewRole({ ...newRole, short_name: e.target.value.toUpperCase() })} disabled={!selectedRoom} className="input" style={{ height: 36, color: 'var(--primary)', fontWeight: 700 }} />
              <select value={newRole.data_type} onChange={e => setNewRole({ ...newRole, data_type: e.target.value })} disabled={!selectedRoom} className="input" style={{ height: 36 }}>
                <option value="TEMP">TEMP</option><option value="GEAR">GEAR</option><option value="BOOL">BOOL</option><option value="STATIC">STATIC</option>
              </select>
              <input type="text" placeholder="목표 수치 (target_value)" value={newRole.target_value} onChange={e => setNewRole({ ...newRole, target_value: e.target.value })} disabled={!selectedRoom} className="input" style={{ height: 36 }} />
              <div style={{ display: 'flex', gap: 6, flexWrap: 'wrap' }}>
                <input
                    type="text"
                    placeholder="하한 수치"
                    value={newRole.target_low_limit}
                    onChange={e => setNewRole({ ...newRole, target_low_limit: e.target.value })}
                    disabled={!selectedRoom}
                    className="input"
                    style={{ flex: 1, minWidth: 0, height: 36 }}
                />
                <input
                    type="text"
                    placeholder="상한 수치"
                    value={newRole.target_high_limit}
                    onChange={e => setNewRole({ ...newRole, target_high_limit: e.target.value })}
                    disabled={!selectedRoom}
                    className="input"
                    style={{ flex: 1, minWidth: 0, height: 36 }}
                />
              </div>
              <label style={{ fontSize: 11, color: 'var(--text-secondary)' }}>적용 시작 일시 (valid_from)</label>
              <input type="datetime-local" value={newRole.valid_from} onChange={e => setNewRole({ ...newRole, valid_from: e.target.value })} disabled={!selectedRoom} className="input" style={{ height: 36 }} />
              <label style={{ fontSize: 11, color: 'var(--text-secondary)' }}>적용 종료 일시 (valid_to - 미입력 시 계속 활성화)</label>
              <input type="datetime-local" value={newRole.valid_to} onChange={e => setNewRole({ ...newRole, valid_to: e.target.value })} disabled={!selectedRoom} className="input" style={{ height: 36 }} />
              <button onClick={handleCreateRole} disabled={!selectedRoom} className="btn btn-primary" style={{ marginTop: 4, flexShrink: 0 }}>신규 롤 생성</button>
            </div>
          )}
        </div>

      </div>
    </div>
  );
};
