// const BASE_URL = 'http://127.0.0.1:8000/api';
// const BASE_URL = 'http://localhost:8000/api';
const BASE_URL = 'http://192.168.29.159:8000/api';




export const apiService = {
  getFacilities: async () => {
    const res = await fetch(`${BASE_URL}/facilities/1`);
    return res.json();
  },
  getRooms: async (facilityId: number) => {
    const res = await fetch(`${BASE_URL}/facilities/rooms/${facilityId}`);
    return res.json();
  },
  getPointRoles: async (facilityId: number, roomId: number) => {
    const res = await fetch(`${BASE_URL}/chart-mapping/roles/${facilityId}/${roomId}`);
    return res.json();
  },
  getChartGroups: async (facilityId: number, roomId: number) => {
    const res = await fetch(`${BASE_URL}/chart-mapping/groups/${facilityId}/${roomId}`);
    return res.json();
  },
  // data_type 제거
  createChartGroup: async (data: { facility_id: number; room_id: number; group_name: string; role_ids: number[] }) => {
    const res = await fetch(`${BASE_URL}/chart-mapping/group`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify(data),
    });
    return res.json();
  }
};