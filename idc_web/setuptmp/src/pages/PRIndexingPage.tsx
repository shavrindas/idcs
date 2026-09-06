import React, { useState, useEffect } from 'react';
import { apiService } from '../services/apiService';
import { IndexingTable } from '../components/indexing/IndexingTable';
import type { Role } from '../types';

export const PRIndexingPage: React.FC = () => {
  const [facilities, setFacilities] = useState<any[]>([]);
  const [rooms, setRooms] = useState<any[]>([]);
  const [roles, setRoles] = useState<Role[]>([]);

  const [selectedFacility, setSelectedFacility] = useState<number | ''>('');
  const [selectedRoom, setSelectedRoom] = useState<number | ''>('');

  // 편집 버퍼 상태
  const [editMap, setEditMap] = useState<{ [roleId: number]: { display_name: string; short_name: string } }>({});
  const [isLoading, setIsLoading] = useState(false);

  // 검색창 상태
  const [searchInput, setSearchInput] = useState('');
  const [suggestions, setSuggestions] = useState<any[]>([]);

  useEffect(() => {
    apiService.getFacilities().then(res => setFacilities(res.facilities || []));
  }, []);

  const handleFacilitySelect = async (facId: number) => {
    setSelectedFacility(facId);
    setSelectedRoom('');
    setRoles([]);
    setEditMap({});
    const res = await apiService.getRooms(facId);
    setRooms(res.rooms || []);
  };

  const handleRoomSelect = async (roomId: number, facId: number = Number(selectedFacility)) => {
    setSelectedRoom(roomId);
    setIsLoading(true);
    try {
      const res = await apiService.getPointRoles(facId, roomId);
      const fetchedRoles: Role[] = res.roles || [];
      setRoles(fetchedRoles);

      const initialEdits: any = {};
      fetchedRoles.forEach(r => {
        initialEdits[r.role_id] = {
          display_name: r.display_name !== r.role_name ? (r.display_name || '') : '',
          short_name: r.short_name !== r.role_name ? (r.short_name || '') : '',
        };
      });
      setEditMap(initialEdits);
    } finally {
      setIsLoading(false);
    }
  };

  // 하향식(시설 -> 호실 -> 포인트롤) 검색어 필터링
  useEffect(() => {
    const q = searchInput.trim().toLowerCase();
    if (!q) { setSuggestions([]); return; }

    const results: any[] = [];
    // 1. 시설 검색
    facilities.forEach(f => {
      if (f.name.toLowerCase().includes(q)) {
        results.push({ type: 'facility', id: f.id, label: `[시설] ${f.name}` });
      }
    });
    // 2. 호실 검색 (시설이 선택되어 있을 때)
    if (selectedFacility) {
      rooms.forEach(r => {
        if (r.name.toLowerCase().includes(q)) {
          results.push({ type: 'room', id: r.id, label: `[호실] ${r.name}` });
        }
      });
    }
    // 3. 포인트롤 검색 (호실이 선택되어 있을 때)
    if (selectedRoom) {
      roles.forEach(r => {
        if (r.role_name.toLowerCase().includes(q) || r.display_name?.toLowerCase().includes(q) || r.short_name?.toLowerCase().includes(q)) {
          results.push({ type: 'role', id: r.role_id, label: `[롤] ${r.display_name || r.role_name}` });
        }
      });
    }
    setSuggestions(results.slice(0, 10));
  }, [searchInput, facilities, rooms, roles, selectedFacility, selectedRoom]);

  const handleApplySuggestion = (sug: any) => {
    if (sug.type === 'facility') handleFacilitySelect(sug.id);
    else if (sug.type === 'room') handleRoomSelect(sug.id);
    setSearchInput('');
    setSuggestions([]);
  };

  const handleSearchSubmit = () => {
    if (suggestions.length > 0) {
      handleApplySuggestion(suggestions[0]);
    }
  };

  const handleFieldChange = (roleId: number, field: 'display_name' | 'short_name', value: string) => {
    setEditMap(prev => ({
      ...prev,
      [roleId]: {
        ...prev[roleId],
        [field]: value
      }
    }));
  };

  // 전체 수정 저장
  const handleSaveAll = async () => {
    if (!selectedFacility || !selectedRoom) return alert('시설과 호실을 먼저 선택하세요.');

    const payload = roles.map(r => ({
      role_id: r.role_id,
      display_name: editMap[r.role_id]?.display_name || '',
      short_name: editMap[r.role_id]?.short_name || ''
    }));

    try {
      await apiService.updatePointRoleIndexing(payload);
      alert('인덱싱 명칭이 성공적으로 저장되었습니다.');
      handleRoomSelect(Number(selectedRoom)); // 새로고침
    } catch (e: any) {
      alert(`저장 실패: ${e.message}`);
    }
  };

  return (
    <div style={{ display: 'flex', flexDirection: 'column', flex: 1, minHeight: 0, gap: 12, padding: 24, boxSizing: 'border-box' }}>

      {/* 상단 컨트롤 바: 선택 + 검색 + 저장 */}
      <div className="card" style={{ display: 'flex', gap: 10, alignItems: 'center', padding: 14 }}>

        {/* 시설 / 호실 선택 드롭다운 */}
        <select
          value={selectedFacility}
          onChange={(e) => handleFacilitySelect(Number(e.target.value))}
          className="input"
          style={{ width: 180 }}
        >
          <option value="">-- 시설 선택 --</option>
          {facilities.map(f => <option key={f.id} value={f.id}>{f.name}</option>)}
        </select>

        <select
          value={selectedRoom}
          onChange={(e) => handleRoomSelect(Number(e.target.value))}
          disabled={!selectedFacility}
          className="input"
          style={{ width: 180 }}
        >
          <option value="">-- 호실 선택 --</option>
          {rooms.map(r => <option key={r.id} value={r.id}>{r.name}</option>)}
        </select>

        {/* 하향식 인덱싱 검색창 */}
        <div style={{ position: 'relative', flex: 1 }}>
          <input
            type="text"
            placeholder="시설 → 호실 → 포인트롤 검색 후 Enter"
            value={searchInput}
            onChange={(e) => setSearchInput(e.target.value)}
            onKeyDown={(e) => { if (e.key === 'Enter') handleSearchSubmit(); }}
            className="input"
          />
          {suggestions.length > 0 && (
            <div
              className="card"
              style={{ position: 'absolute', top: '110%', left: 0, right: 0, zIndex: 10, padding: 6 }}
            >
              {suggestions.map((sug, i) => (
                <div
                  key={i}
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

        {/* 일괄 수정 확인 버튼 */}
        <button
          onClick={handleSaveAll}
          disabled={roles.length === 0 || isLoading}
          className="btn btn-primary"
        >
          수정 확인
        </button>
      </div>

      {/* 메인 인덱싱 테이블 */}
      <IndexingTable roles={roles} editMap={editMap} onFieldChange={handleFieldChange} />
    </div>
  );
};
