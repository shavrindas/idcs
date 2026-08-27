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
  createChartGroup: async (data: { facility_id: number; room_id: number; group_name: string; role_ids: number[] }) => {
    const res = await fetch(`${BASE_URL}/chart-mapping/group`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify(data),
    });
    return res.json();
  },

  // getHistoricalData: async (facilityId: number, roomId: number, scale: string, endTime: string, roleIds: number[]) => {
  //   const res = await fetch(`${BASE_URL}/chart/${facilityId}/${roomId}?scale=${scale}&end_time=${endTime}&role_ids=${roleIds.join(',')}`);
  //   return res.json();
  // }


  // 데이터 호출 API 
  // getHistoricalData: async (facilityId: number, roomId: number, groupId: number | '', scale: string, endTime: string, roleIds: number[]) => {
  //   let url = `${BASE_URL}/chart/${facilityId}/${roomId}?scale=${scale}&end_time=${endTime}&role_ids=${roleIds.join(',')}`;
  //   if (groupId !== '') url += `&group_id=${groupId}`; // 그룹 ID가 있을 경우 전달
    
  //   const res = await fetch(url);
  //   return res.json();
  // },

  getHistoricalData: async (facilityId: number, roomId: number, groupId: number | '', scale: string, startTime: string, endTime: string, roleIds: number[]) => {
    let url = `${BASE_URL}/chart/${facilityId}/${roomId}?scale=${scale}&start_time=${startTime}&end_time=${endTime}&role_ids=${roleIds.join(',')}`;
    if (groupId !== '') url += `&group_id=${groupId}`; 
    
    const res = await fetch(url);
    return res.json();
  },

  // 소요기록 블랙리스트 추가/제거 API
  hidePostFromGroup: async (groupId: number, postId: number) => {
    const res = await fetch(`${BASE_URL}/chart-mapping/group/${groupId}/hide-post/${postId}`, { method: 'POST' });
    return res.json();
  },
  showPostInGroup: async (groupId: number, postId: number) => {
    const res = await fetch(`${BASE_URL}/chart-mapping/group/${groupId}/show-post/${postId}`, { method: 'DELETE' });
    return res.json();
  },

  updatePointRoleIndexing: async (updates: { role_id: number; display_name: string; short_name: string }[]) => {
    const res = await fetch(`${BASE_URL}/chart-mapping/roles/indexing`, {
      method: 'PUT',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ updates }),
    });
    if (!res.ok) throw new Error(await res.text());
    return res.json();
  }
};