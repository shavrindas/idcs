import { useState, useEffect } from 'react';
import { apiService } from '../services/apiService';
import { LeftPanel } from '../components/chart/mapper/LeftPanel';
import { RightPanel } from '../components/chart/mapper/RightPanel';
import type { Role, ChartGroup, SessionUser } from '../types';

interface Props {
  user: SessionUser;
}

export const ChartMappingPage: React.FC<Props> = ({ user }) => {
  const [facilities, setFacilities] = useState<any[]>([]);
  const [rooms, setRooms] = useState<any[]>([]);
  const [selectedFacility, setSelectedFacility] = useState<number | null>(null);
  const [selectedRoom, setSelectedRoom] = useState<number | null>(null);

  const [room0Roles, setRoom0Roles] = useState<Role[]>([]);
  const [targetRoomRoles, setTargetRoomRoles] = useState<Role[]>([]);

  const [existingGroups, setExistingGroups] = useState<ChartGroup[]>([]);
  const [selectedGroupId, setSelectedGroupId] = useState<number | 'new'>('new');
  const [groupName, setGroupName] = useState('');
  const [droppedRoles, setDroppedRoles] = useState<Role[]>([]);

  useEffect(() => {
    apiService.getUserFacilities(user.id).then((data) => setFacilities(data.facilities || []));
  }, [user.id]);

  const handleFacilityChange = async (facId: number) => {
    setSelectedFacility(facId);
    setSelectedRoom(null);
    setTargetRoomRoles([]);
    setExistingGroups([]);
    resetGroupForm();

    const roomData = await apiService.getRooms(facId);
    setRooms(roomData.rooms || []);
    const roleData = await apiService.getPointRoles(facId, 0);
    setRoom0Roles(roleData.roles || []);
  };

  const handleRoomChange = async (roomId: number) => {
    setSelectedRoom(roomId);
    resetGroupForm();
    if (selectedFacility) {
      const roleData = await apiService.getPointRoles(selectedFacility, roomId);
      setTargetRoomRoles(roleData.roles || []);
      const groupData = await apiService.getChartGroups(selectedFacility, roomId);
      setExistingGroups(groupData.groups || []);
    }
  };

  const resetGroupForm = () => {
    setSelectedGroupId('new');
    setGroupName('');
    setDroppedRoles([]);
  };

  const handleGroupSelect = (val: string) => {
    if (val === 'new') {
      resetGroupForm();
      return;
    }
    const gId = Number(val);
    setSelectedGroupId(gId);
    const targetGroup = existingGroups.find((g) => g.group_id === gId);
    if (targetGroup) {
      setGroupName(targetGroup.group_name);
      const allAvailableRoles = [...room0Roles, ...targetRoomRoles];
      const validRoleIds = (targetGroup.role_ids || []).filter((id) => id !== null);
      const loadedRoles = validRoleIds
        .map((id) => allAvailableRoles.find((r) => r.role_id === id))
        .filter(Boolean) as Role[];
      setDroppedRoles(loadedRoles);
    }
  };

  const onDragStart = (e: React.DragEvent, role: Role) => {
    e.dataTransfer.setData('application/json', JSON.stringify(role));
  };

  const onDragOver = (e: React.DragEvent) => {
    e.preventDefault();
  };

  // Shared by drag-and-drop and double-click so both paths behave the same.
  const addRole = (role: Role) => {
    setDroppedRoles((prev) => (prev.some((r) => r.role_id === role.role_id) ? prev : [...prev, role]));
  };

  const onDrop = (e: React.DragEvent) => {
    e.preventDefault();
    const roleData = e.dataTransfer.getData('application/json');
    if (roleData) addRole(JSON.parse(roleData));
  };

  const removeRole = (roleId: number) => setDroppedRoles((prev) => prev.filter((r) => r.role_id !== roleId));

  // 오른쪽에서 왼쪽으로 다시 끌어다 놓으면 뺀다 — 넣는 쪽(왼쪽→오른쪽
  // 드래그)만 되고 되돌리는 쪽은 안 돼서, 잘못 넣은 걸 빼려면 더블클릭이나
  // ✕ 를 찾아야 했다. 끌어다 놓는 동작 자체를 그대로 되돌릴 수 있어야 한다.
  const onDropToRemove = (e: React.DragEvent) => {
    e.preventDefault();
    const roleId = e.dataTransfer.getData('text/role-id');
    if (roleId) removeRole(Number(roleId));
  };

  const handleReorderRoles = (sourceIndex: number, targetIndex: number) => {
    if (sourceIndex === targetIndex) return;
    const updated = [...droppedRoles];
    const [movedItem] = updated.splice(sourceIndex, 1);
    updated.splice(targetIndex, 0, movedItem);
    setDroppedRoles(updated);
  };

  const handleSaveGroup = async () => {
    if (!selectedFacility || !selectedRoom) return alert('시설과 호실을 선택하세요.');
    if (!groupName) return alert('그룹 명칭을 입력하세요.');
    if (droppedRoles.length === 0) return alert('포인트 롤을 추가하세요.');
    if (selectedGroupId !== 'new') return alert('수정 기능은 백엔드 구현 후 지원됩니다.');

    try {
      await apiService.createChartGroup({
        facility_id: selectedFacility,
        room_id: selectedRoom,
        group_name: groupName,
        role_ids: droppedRoles.map((r) => r.role_id),
      });
      alert('생성 완료!');
      handleRoomChange(selectedRoom);
    } catch {
      alert('저장 실패');
    }
  };

  const handleDeleteGroup = async () => {
    if (selectedGroupId === 'new') return;
    const target = existingGroups.find((g) => g.group_id === selectedGroupId);
    if (!target || !window.confirm(`"${target.group_name}" 그룹을 삭제하시겠습니까?`)) return;

    try {
      await apiService.deleteChartGroup(selectedGroupId);
      resetGroupForm();
      if (selectedRoom) handleRoomChange(selectedRoom);
    } catch {
      alert('삭제 실패');
    }
  };

  return (
    <div style={{ display: 'flex', flex: 1, minHeight: 0, height: '100%', gap: 12, padding: 24, boxSizing: 'border-box' }}>
      <LeftPanel
        facilities={facilities}
        rooms={rooms}
        selectedFacility={selectedFacility}
        selectedRoom={selectedRoom}
        room0Roles={room0Roles}
        targetRoomRoles={targetRoomRoles}
        droppedRoleIds={droppedRoles.map((r) => r.role_id)}
        onFacilityChange={handleFacilityChange}
        onRoomChange={handleRoomChange}
        onDragStart={onDragStart}
        onAddRole={addRole}
        onDropToRemove={onDropToRemove}
      />
      <RightPanel
        existingGroups={existingGroups}
        selectedGroupId={selectedGroupId}
        groupName={groupName}
        droppedRoles={droppedRoles}
        onGroupSelect={handleGroupSelect}
        onGroupNameChange={setGroupName}
        onDrop={onDrop}
        onDragOver={onDragOver}
        onRemoveRole={removeRole}
        onReorderRoles={handleReorderRoles}
        onSaveGroup={handleSaveGroup}
        onDeleteGroup={handleDeleteGroup}
      />
    </div>
  );
};