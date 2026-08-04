const BASE_URL = 'http://127.0.0.1:8000/api';

export const apiService = {
  // 관리자의 시설 목록 (임시로 유저 1번 기준)
  getFacilities: async () => {
    const res = await fetch(`${BASE_URL}/facilities/1`);
    return res.json();
  },
  
  // 특정 시설의 호실 목록
  getRooms: async (facilityId: number) => {
    const res = await fetch(`${BASE_URL}/facilities/rooms/${facilityId}`);
    return res.json();
  },

  // 특정 호실의 원시 포인트 롤 목록
  getPointRoles: async (facilityId: number, roomId: number) => {
    const res = await fetch(`${BASE_URL}/chart-mapping/roles/${facilityId}/${roomId}`);
    return res.json();
  },

  // 차트 그룹 생성
  createChartGroup: async (data: { facility_id: number; room_id: number; group_name: string; data_type: string; role_ids: number[] }) => {
    const res = await fetch(`${BASE_URL}/chart-mapping/group`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify(data),
    });
    return res.json();
  }
};