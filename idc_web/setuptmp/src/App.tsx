import React, { useState, useEffect } from 'react';
import { apiService } from './services/apiService';
import './App.css';

interface Role {
  role_id: number;
  role_name: string;
}

function App() {
  const [facilities, setFacilities] = useState<any[]>([]);
  const [rooms, setRooms] = useState<any[]>([]);
  
  const [selectedFacility, setSelectedFacility] = useState<number | null>(null);
  const [selectedRoom, setSelectedRoom] = useState<number | null>(null);
  
  const [room0Roles, setRoom0Roles] = useState<Role[]>([]);
  const [targetRoomRoles, setTargetRoomRoles] = useState<Role[]>([]);
  
  // 드롭존(그룹 생성) 상태
  const [groupName, setGroupName] = useState('');
  const [dataType, setDataType] = useState('temp');
  const [droppedRoles, setDroppedRoles] = useState<Role[]>([]);

  // 1. 초기 시설 로드
  useEffect(() => {
    apiService.getFacilities().then(data => setFacilities(data.facilities || []));
  }, []);

  // 2. 시설 선택 시 호실 및 0호실 데이터 로드
  const handleFacilityChange = async (facId: number) => {
    setSelectedFacility(facId);
    setSelectedRoom(null);
    setTargetRoomRoles([]);
    
    const roomData = await apiService.getRooms(facId);
    setRooms(roomData.rooms || []);
    
    const roleData = await apiService.getPointRoles(facId, 0); // 0호실 로드
    setRoom0Roles(roleData.roles || []);
  };

  // 3. 대상 호실 선택 시 롤 로드
  const handleRoomChange = async (roomId: number) => {
    setSelectedRoom(roomId);
    if (selectedFacility) {
      const roleData = await apiService.getPointRoles(selectedFacility, roomId);
      setTargetRoomRoles(roleData.roles || []);
    }
  };

  // --- Drag & Drop Handlers ---
  const onDragStart = (e: React.DragEvent, role: Role) => {
    e.dataTransfer.setData("application/json", JSON.stringify(role));
  };

  const onDragOver = (e: React.DragEvent) => {
    e.preventDefault(); // 드롭 허용
  };

  const onDrop = (e: React.DragEvent) => {
    e.preventDefault();
    const roleData = e.dataTransfer.getData("application/json");
    if (roleData) {
      const role: Role = JSON.parse(roleData);
      // 중복 추가 방지
      if (!droppedRoles.find(r => r.role_id === role.role_id)) {
        setDroppedRoles([...droppedRoles, role]);
      }
    }
  };

  const removeDroppedRole = (roleId: number) => {
    setDroppedRoles(droppedRoles.filter(r => r.role_id !== roleId));
  };

  // --- 그룹 저장 ---
  const handleSaveGroup = async () => {
    if (!selectedFacility || !selectedRoom) return alert('시설과 대상 호실을 선택하세요.');
    if (!groupName) return alert('그룹 명칭을 입력하세요.');
    if (droppedRoles.length === 0) return alert('최소 1개의 포인트 롤을 추가하세요.');

    try {
      await apiService.createChartGroup({
        facility_id: selectedFacility,
        room_id: selectedRoom,
        group_name: groupName,
        data_type: dataType,
        role_ids: droppedRoles.map(r => r.role_id)
      });
      alert('그룹이 성공적으로 생성되었습니다!');
      setGroupName('');
      setDroppedRoles([]);
    } catch (e) {
      alert('저장 실패');
    }
  };

  return (
    <div style={{ display: 'flex', flexDirection: 'column', height: '100vh', padding: 10 }}>
      <header style={{ border: '2px solid orange', padding: 10, textAlign: 'center' }}>
        <h2>IDCool 차트 매핑 관리자</h2>
      </header>

      <div style={{ display: 'flex', flex: 1, marginTop: 10, gap: 10 }}>
        {/* 좌측 패널 (소스) */}
        <div style={{ border: '2px solid red', flex: 1, padding: 10, display: 'flex', flexDirection: 'column', gap: 10 }}>
          <select onChange={(e) => handleFacilityChange(Number(e.target.value))}>
            <option value="">시설 선택</option>
            {facilities.map(f => <option key={f.id} value={f.id}>{f.name}</option>)}
          </select>

          <div style={{ display: 'flex', flex: 1, gap: 10 }}>
            {/* 0호실 리스트 */}
            <div style={{ border: '1px solid #333', flex: 1, padding: 10, overflowY: 'auto' }}>
              <h4>0호실 (공용)</h4>
              {room0Roles.map(role => (
                <div key={role.role_id} draggable onDragStart={(e) => onDragStart(e, role)}
                     style={{ border: '1px solid #999', padding: 8, marginBottom: 5, cursor: 'grab', backgroundColor: '#fff' }}>
                  {role.role_name}
                </div>
              ))}
            </div>

            {/* 타겟 호실 리스트 */}
            <div style={{ border: '1px solid #333', flex: 1, padding: 10, overflowY: 'auto' }}>
              <select onChange={(e) => handleRoomChange(Number(e.target.value))}>
                <option value="">호실 선택</option>
                {rooms.map(r => <option key={r.id} value={r.id}>{r.name}</option>)}
              </select>
              <div style={{ marginTop: 10 }}>
                {targetRoomRoles.map(role => (
                  <div key={role.role_id} draggable onDragStart={(e) => onDragStart(e, role)}
                       style={{ border: '1px solid #999', padding: 8, marginBottom: 5, cursor: 'grab', backgroundColor: '#fff' }}>
                    {role.role_name}
                  </div>
                ))}
              </div>
            </div>
          </div>
        </div>

        {/* 우측 패널 (목적지) */}
        <div style={{ border: '2px solid green', flex: 1, padding: 10, display: 'flex', flexDirection: 'column', gap: 10 }}>
          <div style={{ border: '1px solid #333', padding: 10, display: 'flex', flexDirection: 'column', gap: 10 }}>
            <input type="text" placeholder="새 그룹 명칭 입력" value={groupName} onChange={e => setGroupName(e.target.value)} />
            <select value={dataType} onChange={e => setDataType(e.target.value)}>
              <option value="temp">온도 (temp)</option>
              <option value="gear">장비 수치 (gear)</option>
              <option value="static">정적 장비 (static)</option>
              <option value="bool">상태/이상 (bool)</option>
            </select>
          </div>

          <h4>드래그 앤 드롭 영역 (조합할 센서 배치)</h4>
          <div onDrop={onDrop} onDragOver={onDragOver}
               style={{ border: '2px dashed #666', flex: 1, padding: 10, overflowY: 'auto', backgroundColor: '#fafafa' }}>
            {droppedRoles.length === 0 && <p style={{ color: '#999' }}>여기로 포인트 롤을 드래그하세요.</p>}
            {droppedRoles.map(role => (
              <div key={role.role_id} onClick={() => removeDroppedRole(role.role_id)}
                   style={{ border: '1px solid blue', padding: 8, marginBottom: 5, cursor: 'pointer', backgroundColor: '#e6f2ff' }}>
                {role.role_name} ❌
              </div>
            ))}
          </div>

          <button onClick={handleSaveGroup} style={{ padding: 15, fontWeight: 'bold', cursor: 'pointer' }}>
            그룹 등록하기
          </button>
        </div>
      </div>
    </div>
  );
}

export default App;