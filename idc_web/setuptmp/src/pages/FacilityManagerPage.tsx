import React, { useState, useEffect } from 'react';
import { apiService } from '../services/apiService';

export const FacilityManagerPage: React.FC = () => {
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
    const res = await apiService.getAllFacilitiesAdmin();
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
    await apiService.createFacilityAdmin(newFac);
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
    <div style={{ display: 'flex', flexDirection: 'column', height: '100%', minHeight: 0, gap: 10, padding: 10, boxSizing: 'border-box' }}>
      
      {/* 1. 상단 하향식 검색바 */}
      <div style={{ position: 'relative', backgroundColor: '#222', padding: 8, borderRadius: 4, border: '1px solid #444', flexShrink: 0 }}>
        <input
          type="text" placeholder="시설 -> 호실 검색 후 Enter"
          value={searchInput} onChange={e => setSearchInput(e.target.value)}
          onKeyDown={e => { if (e.key === 'Enter' && suggestions.length > 0) handleApplySuggestion(suggestions[0]); }}
          style={{ width: '100%', padding: 8, backgroundColor: '#333', color: '#fff', border: '1px solid #555', boxSizing: 'border-box' }}
        />
        {suggestions.length > 0 && (
          <div style={{ position: 'absolute', top: '100%', left: 0, right: 0, backgroundColor: '#2b2b2b', border: '1px solid #555', zIndex: 10 }}>
            {suggestions.map((sug, idx) => (
              <div key={idx} onClick={() => handleApplySuggestion(sug)} style={{ padding: '8px 12px', cursor: 'pointer', borderBottom: '1px solid #444', color: '#82b1ff' }}>
                {sug.label}
              </div>
            ))}
          </div>
        )}
      </div>

      {/* 2. 시설/호실/포인트롤 매니저 3단 레이아웃 */}
      <div style={{ display: 'flex', gap: 10, flex: 1, minHeight: 0 }}>
        
        {/* [1열] 시설 관리 패널 (flex: 1) */}
        <div style={{ flex: 1, minWidth: 260, border: '1px solid #4caf50', padding: 10, display: 'flex', flexDirection: 'column', gap: 10, backgroundColor: '#1a241b', minHeight: 0 }}>
          <h4 style={{ margin: 0, color: '#4caf50' }}>시설 관리</h4>
          
          <select value={selectedFacility} onChange={e => handleFacilityChange(Number(e.target.value))} style={{ padding: 8, backgroundColor: '#333', color: '#fff' }}>
            <option value="">-- [시설 선택] --</option>
            {facilities.map(f => (
              <option key={f.id} value={f.id}>
                {f.name} ({f.access_code}) [{f.is_active ? '운영중' : '숨김/만료'}]
              </option>
            ))}
          </select>

          {editFac ? (
            <div style={{ display: 'flex', flexDirection: 'column', gap: 6, borderTop: '1px dashed #555', paddingTop: 8 }}>
              <span style={{ fontSize: 12, color: '#aaa' }}>선택 시설 수정 ({editFac.is_active ? 'Active' : 'Inactive'})</span>
              <input type="text" placeholder="시설 이름" value={editFac.name} onChange={e => setEditFac({ ...editFac, name: e.target.value })} style={{ padding: 6, backgroundColor: '#2b2b2b', color: '#fff', border: '1px solid #555' }} />
              <input type="text" placeholder="접근 코드" value={editFac.access_code} onChange={e => setEditFac({ ...editFac, access_code: e.target.value })} style={{ padding: 6, backgroundColor: '#2b2b2b', color: '#fff', border: '1px solid #555' }} />
              <label style={{ fontSize: 11, color: '#aaa' }}>(계약-숨김) 시작일</label>
              <input type="date" value={editFac.start_date || ''} onChange={e => setEditFac({ ...editFac, start_date: e.target.value })} style={{ padding: 6, backgroundColor: '#2b2b2b', color: '#fff', border: '1px solid #555' }} />
              <label style={{ fontSize: 11, color: '#aaa' }}>(계약-숨김) 종료일</label>
              <input type="date" value={editFac.end_date || ''} onChange={e => setEditFac({ ...editFac, end_date: e.target.value })} style={{ padding: 6, backgroundColor: '#2b2b2b', color: '#fff', border: '1px solid #555' }} />
              <button onClick={handleUpdateFacility} style={{ padding: 6, backgroundColor: '#2196f3', color: '#fff', border: 'none', cursor: 'pointer' }}>시설 갱신</button>
            </div>
          ) : (
            <div style={{ display: 'flex', flexDirection: 'column', gap: 6, borderTop: '1px dashed #555', paddingTop: 8 }}>
              <span style={{ fontSize: 12, color: '#aaa' }}>신규 시설 등록</span>
              <input type="text" placeholder="시설 이름" value={newFac.name} onChange={e => setNewFac({ ...newFac, name: e.target.value })} style={{ padding: 6, backgroundColor: '#2b2b2b', color: '#fff', border: '1px solid #555' }} />
              <input type="text" placeholder="접근 코드" value={newFac.access_code} onChange={e => setNewFac({ ...newFac, access_code: e.target.value })} style={{ padding: 6, backgroundColor: '#2b2b2b', color: '#fff', border: '1px solid #555' }} />
              <input type="date" value={newFac.start_date} onChange={e => setNewFac({ ...newFac, start_date: e.target.value })} style={{ padding: 6, backgroundColor: '#2b2b2b', color: '#fff', border: '1px solid #555' }} />
              <input type="date" value={newFac.end_date} onChange={e => setNewFac({ ...newFac, end_date: e.target.value })} style={{ padding: 6, backgroundColor: '#2b2b2b', color: '#fff', border: '1px solid #555' }} />
              <button onClick={handleCreateFacility} style={{ padding: 6, backgroundColor: '#4caf50', color: '#fff', border: 'none', cursor: 'pointer' }}>시설 생성</button>
            </div>
          )}

          <h5 style={{ margin: '10px 0 0 0', color: '#ccc' }}>소속 유저 ({users.length}명)</h5>
          <div style={{ flex: 1, minHeight: 0, overflowY: 'auto', backgroundColor: '#111', padding: 6, fontSize: 12, border: '1px solid #333' }}>
            {users.map(u => (
              <div key={u.id} style={{ borderBottom: '1px solid #222', padding: '3px 0' }}>
                <strong style={{ color: '#82b1ff' }}>{u.name}</strong> ({u.email})
              </div>
            ))}
          </div>
        </div>

        {/* [2열] 호실 트리 및 관리 (flex: 1.8 로 확장하여 이름 잘림 방지) */}
        <div style={{ flex: 1.8, minWidth: 340, border: '1px solid #2196f3', padding: 10, display: 'flex', flexDirection: 'column', gap: 10, backgroundColor: '#18222c', minHeight: 0 }}>
          <h4 style={{ margin: 0, color: '#2196f3' }}>호실 및 포인트 롤 트리</h4>
          
          <div style={{ display: 'flex', gap: 6, flexShrink: 0 }}>
            <input type="text" placeholder="새 호실 명칭" value={newRoomName} onChange={e => setNewRoomName(e.target.value)} disabled={!selectedFacility} style={{ flex: 1, padding: 6, backgroundColor: '#2b2b2b', color: '#fff', border: '1px solid #555' }} />
            <button onClick={handleCreateRoom} disabled={!selectedFacility} style={{ padding: '6px 12px', backgroundColor: '#2196f3', color: '#fff', border: 'none', cursor: 'pointer', whiteSpace: 'nowrap' }}>호실 추가</button>
          </div>

          <div style={{ flex: 1, minHeight: 0, overflowY: 'auto', border: '1px solid #444', backgroundColor: '#111', padding: 6 }}>
            {rooms.map(r => {
              const isExpanded = expandedRoomIds.includes(r.id);
              const isSelected = selectedRoom?.id === r.id;
              const isCommonRoom = r.name.includes('000호') || r.name.includes('공용');
              const roles = roomRolesMap[r.id] || [];

              return (
                <div key={r.id} style={{ marginBottom: 6, border: isSelected ? '1px solid #2196f3' : '1px solid #333', borderRadius: 4, backgroundColor: '#1e1e1e' }}>
                  <div 
                    onClick={() => { setSelectedRoom({ ...r }); setSelectedRole(null); }}
                    style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', padding: '6px 10px', cursor: 'pointer', backgroundColor: isSelected ? '#2a3b4c' : '#252525' }}
                  >
                    <div style={{ display: 'flex', alignItems: 'center', gap: 8 }}>
                      <span onClick={(e) => toggleRoomExpand(r.id, e)} style={{ cursor: 'pointer', fontSize: 13, userSelect: 'none' }}>
                        {isExpanded ? '▼' : '▶'}
                      </span>
                      <strong>{r.name}</strong>
                      <span style={{ fontSize: 11, color: '#aaa' }}>[{r.status}]</span>
                    </div>
                    <div>
                      {!isCommonRoom && (
                        <button onClick={(e) => { e.stopPropagation(); handleDeleteRoom(r.id); }} style={{ backgroundColor: '#ff4d4f', color: '#fff', border: 'none', padding: '2px 6px', cursor: 'pointer', borderRadius: 3, fontSize: 11 }}>삭제</button>
                      )}
                    </div>
                  </div>

                  {/* 호실 하위 포인트롤 리스트 (접기/펼치기) */}
                  {isExpanded && (
                    <div style={{ padding: '6px 10px 6px 28px', backgroundColor: '#161616', borderTop: '1px solid #333' }}>
                      {roles.map(role => (
                        <div 
                          key={role.role_id}
                          onClick={(e) => { e.stopPropagation(); setSelectedRole({ ...role }); }}
                          style={{
                            display: 'flex', justifyContent: 'space-between', alignItems: 'center',
                            padding: '4px 6px', marginBottom: 3, fontSize: 12, borderRadius: 3, cursor: 'pointer',
                            backgroundColor: selectedRole?.role_id === role.role_id ? '#3a4a5a' : '#222',
                            color: role.is_current ? '#eee' : '#777'
                          }}
                        >
                          <div style={{ display: 'flex', alignItems: 'center', gap: 4, overflow: 'hidden', textOverflow: 'ellipsis', whiteSpace: 'nowrap' }}>
                            <span style={{ backgroundColor: '#333', padding: '1px 4px', borderRadius: 2, fontSize: 10 }}>{role.short_name || 'N/A'}</span>
                            <span style={{ fontWeight: 500 }}>{role.display_name || role.role_name}</span>
                            <span style={{ fontSize: 10, color: '#888' }}>({role.role_name})</span>
                          </div>
                          <div style={{ display: 'flex', gap: 6, alignItems: 'center', flexShrink: 0 }}>
                            <span style={{ fontSize: 10, color: role.is_current ? '#4caf50' : '#f44336' }}>
                              {role.is_current ? 'Active' : 'Expired'}
                            </span>
                            <button onClick={(e) => { e.stopPropagation(); handleDeleteRole(role.role_id, r.id); }} style={{ background: 'transparent', border: 'none', color: '#ff7875', cursor: 'pointer', fontSize: 11 }}>✕</button>
                          </div>
                        </div>
                      ))}
                      {roles.length === 0 && <span style={{ fontSize: 11, color: '#666' }}>등록된 포인트 롤이 없습니다.</span>}
                    </div>
                  )}
                </div>
              );
            })}
          </div>

          {selectedRoom && (
            <div style={{ display: 'flex', gap: 6, alignItems: 'center', borderTop: '1px dashed #555', paddingTop: 8, flexShrink: 0 }}>
              <span style={{ fontSize: 12, color: '#aaa', whiteSpace: 'nowrap' }}>호실 수정:</span>
              <input type="text" value={selectedRoom.name} onChange={e => setSelectedRoom({ ...selectedRoom, name: e.target.value })} style={{ flex: 1, padding: 6, backgroundColor: '#2b2b2b', color: '#fff', border: '1px solid #555' }} />
              <select value={selectedRoom.status} onChange={e => setSelectedRoom({ ...selectedRoom, status: e.target.value })} style={{ padding: 6, backgroundColor: '#333', color: '#fff' }}>
                <option value="OPERATING">OPERATING</option>
                <option value="MAINTENANCE">MAINTENANCE</option>
                <option value="NOT_OPERATING">NOT_OPERATING</option>
              </select>
              <button onClick={handleUpdateRoom} style={{ padding: '6px 10px', backgroundColor: '#4caf50', color: '#fff', border: 'none', cursor: 'pointer', whiteSpace: 'nowrap' }}>저장</button>
            </div>
          )}
        </div>

        {/* [3열] 포인트 롤 등록 및 수정 패널 (flex: 1.2, minHeight: 0 스크롤 안정화) */}
        <div style={{ flex: 1.2, minWidth: 280, border: '1px solid #9c27b0', padding: 10, display: 'flex', flexDirection: 'column', gap: 10, backgroundColor: '#22182c', minHeight: 0 }}>
          <h4 style={{ margin: 0, color: '#ba68c8', flexShrink: 0 }}>
            포인트 롤 관리 {selectedRoom ? `(${selectedRoom.name})` : ''}
          </h4>

          {selectedRole ? (
            <div style={{ display: 'flex', flexDirection: 'column', gap: 6, overflowY: 'auto', flex: 1, minHeight: 0 }}>
              <div style={{ display: 'flex', justifyContent: 'space-between', flexShrink: 0 }}>
                <span style={{ fontSize: 12, color: '#aaa' }}>선택 포인트롤 수정</span>
                <span style={{ fontSize: 11, color: selectedRole.is_current ? '#4caf50' : '#f44336' }}>
                  {selectedRole.is_current ? '운영 중 (Active)' : '만료/숨김 (Inactive)'}
                </span>
              </div>
              <input type="text" value={selectedRole.role_name} disabled style={{ padding: 6, backgroundColor: '#1e1e1e', color: '#888', border: '1px solid #444' }} title="기능명칭은 수정 불가" />
              <input type="text" placeholder="디스플레이 명칭" value={selectedRole.display_name || ''} onChange={e => setSelectedRole({ ...selectedRole, display_name: e.target.value })} style={{ padding: 6, backgroundColor: '#2b2b2b', color: '#fff', border: '1px solid #555' }} />
              <input type="text" maxLength={3} placeholder="약어 명칭 (3자)" value={selectedRole.short_name || ''} onChange={e => setSelectedRole({ ...selectedRole, short_name: e.target.value.toUpperCase() })} style={{ padding: 6, backgroundColor: '#2b2b2b', color: '#69c0ff', border: '1px solid #555' }} />
              <select value={selectedRole.data_type || 'TEMP'} onChange={e => setSelectedRole({ ...selectedRole, data_type: e.target.value })} style={{ padding: 6, backgroundColor: '#333', color: '#fff' }}>
                <option value="TEMP">TEMP</option><option value="GEAR">GEAR</option><option value="BOOL">BOOL</option><option value="STATIC">STATIC</option>
              </select>
              <input type="text" placeholder="목표 수치 (target_value)" value={selectedRole.target_value || ''} onChange={e => setSelectedRole({ ...selectedRole, target_value: e.target.value })} style={{ padding: 6, backgroundColor: '#2b2b2b', color: '#fff', border: '1px solid #555' }} />
                <div style={{ display: 'flex', gap: 6, flexWrap: 'wrap' }}>
                <input 
                    type="text" 
                    placeholder="하한 (low_limit)" 
                    value={selectedRole.target_low_limit || ''} 
                    onChange={e => setSelectedRole({ ...selectedRole, target_low_limit: e.target.value })} 
                    style={{ flex: 1, minWidth: 0, padding: 6, backgroundColor: '#2b2b2b', color: '#fff', border: '1px solid #555', boxSizing: 'border-box' }} 
                />
                <input 
                    type="text" 
                    placeholder="상한 (high_limit)" 
                    value={selectedRole.target_high_limit || ''} 
                    onChange={e => setSelectedRole({ ...selectedRole, target_high_limit: e.target.value })} 
                    style={{ flex: 1, minWidth: 0, padding: 6, backgroundColor: '#2b2b2b', color: '#fff', border: '1px solid #555', boxSizing: 'border-box' }} 
                />
                </div>
              <label style={{ fontSize: 11, color: '#aaa' }}>적용 시작 일시 (valid_from)</label>
              <input type="datetime-local" value={selectedRole.valid_from ? selectedRole.valid_from.slice(0, 16) : ''} onChange={e => setSelectedRole({ ...selectedRole, valid_from: e.target.value })} style={{ padding: 6, backgroundColor: '#2b2b2b', color: '#fff', border: '1px solid #555' }} />
              <label style={{ fontSize: 11, color: '#aaa' }}>적용 종료 일시 (valid_to - 미입력 시 계속 활성화)</label>
              <input type="datetime-local" value={selectedRole.valid_to ? selectedRole.valid_to.slice(0, 16) : ''} onChange={e => setSelectedRole({ ...selectedRole, valid_to: e.target.value })} style={{ padding: 6, backgroundColor: '#2b2b2b', color: '#fff', border: '1px solid #555' }} />
              <div style={{ display: 'flex', gap: 6, marginTop: 4, flexShrink: 0 }}>
                <button onClick={handleUpdateRole} style={{ flex: 1, padding: 8, backgroundColor: '#2196f3', color: '#fff', border: 'none', cursor: 'pointer' }}>롤 정보 수정</button>
                <button onClick={() => setSelectedRole(null)} style={{ padding: 8, backgroundColor: '#555', color: '#fff', border: 'none', cursor: 'pointer' }}>취소</button>
              </div>
            </div>
          ) : (
            <div style={{ display: 'flex', flexDirection: 'column', gap: 6, overflowY: 'auto', flex: 1, minHeight: 0 }}>
              <span style={{ fontSize: 12, color: '#aaa' }}>신규 포인트 롤 추가</span>
              <input type="text" placeholder="기능 명칭 (role_name: 고유 식별)" value={newRole.role_name} onChange={e => setNewRole({ ...newRole, role_name: e.target.value })} disabled={!selectedRoom} style={{ padding: 6, backgroundColor: '#2b2b2b', color: '#fff', border: '1px solid #555' }} />
              <input type="text" placeholder="디스플레이 명칭" value={newRole.display_name} onChange={e => setNewRole({ ...newRole, display_name: e.target.value })} disabled={!selectedRoom} style={{ padding: 6, backgroundColor: '#2b2b2b', color: '#fff', border: '1px solid #555' }} />
              <input type="text" maxLength={3} placeholder="약어 명칭 (3자)" value={newRole.short_name} onChange={e => setNewRole({ ...newRole, short_name: e.target.value.toUpperCase() })} disabled={!selectedRoom} style={{ padding: 6, backgroundColor: '#2b2b2b', color: '#69c0ff', border: '1px solid #555' }} />
              <select value={newRole.data_type} onChange={e => setNewRole({ ...newRole, data_type: e.target.value })} disabled={!selectedRoom} style={{ padding: 6, backgroundColor: '#333', color: '#fff' }}>
                <option value="TEMP">TEMP</option><option value="GEAR">GEAR</option><option value="BOOL">BOOL</option><option value="STATIC">STATIC</option>
              </select>
              <input type="text" placeholder="목표 수치 (target_value)" value={newRole.target_value} onChange={e => setNewRole({ ...newRole, target_value: e.target.value })} disabled={!selectedRoom} style={{ padding: 6, backgroundColor: '#2b2b2b', color: '#fff', border: '1px solid #555' }} />
                <div style={{ display: 'flex', gap: 6, flexWrap: 'wrap' }}>
                <input 
                    type="text" 
                    placeholder="하한 수치" 
                    value={newRole.target_low_limit} 
                    onChange={e => setNewRole({ ...newRole, target_low_limit: e.target.value })} 
                    disabled={!selectedRoom} 
                    style={{ flex: 1, minWidth: 0, padding: 6, backgroundColor: '#2b2b2b', color: '#fff', border: '1px solid #555', boxSizing: 'border-box' }} 
                />
                <input 
                    type="text" 
                    placeholder="상한 수치" 
                    value={newRole.target_high_limit} 
                    onChange={e => setNewRole({ ...newRole, target_high_limit: e.target.value })} 
                    disabled={!selectedRoom} 
                    style={{ flex: 1, minWidth: 0, padding: 6, backgroundColor: '#2b2b2b', color: '#fff', border: '1px solid #555', boxSizing: 'border-box' }} 
                />
                </div>
              <label style={{ fontSize: 11, color: '#aaa' }}>적용 시작 일시 (valid_from)</label>
              <input type="datetime-local" value={newRole.valid_from} onChange={e => setNewRole({ ...newRole, valid_from: e.target.value })} disabled={!selectedRoom} style={{ padding: 6, backgroundColor: '#2b2b2b', color: '#fff', border: '1px solid #555' }} />
              <label style={{ fontSize: 11, color: '#aaa' }}>적용 종료 일시 (valid_to - 미입력 시 계속 활성화)</label>
              <input type="datetime-local" value={newRole.valid_to} onChange={e => setNewRole({ ...newRole, valid_to: e.target.value })} disabled={!selectedRoom} style={{ padding: 6, backgroundColor: '#2b2b2b', color: '#fff', border: '1px solid #555' }} />
              <button onClick={handleCreateRole} disabled={!selectedRoom} style={{ padding: 8, backgroundColor: '#ba68c8', color: '#fff', border: 'none', cursor: selectedRoom ? 'pointer' : 'not-allowed', marginTop: 4, flexShrink: 0 }}>신규 롤 생성</button>
            </div>
          )}
        </div>

      </div>
    </div>
  );
};