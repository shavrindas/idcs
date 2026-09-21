// const BASE_URL = 'http://127.0.0.1:8000/api';
// const BASE_URL = 'http://localhost:8000/api';
// const BASE_URL = 'http://192.168.29.159:8000/api';
const BASE_URL = 'http://211.55.127.239/api';




export const apiService = {
  // 인증
  login: async (email: string, password: string, keepLogin: boolean = false) => {
    let res: Response;
    try {
      res = await fetch(`${BASE_URL}/auth/login/general`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ email, password, keep_login: keepLogin }),
        signal: AbortSignal.timeout(8000),
      });
    } catch {
      throw new Error(`서버(${BASE_URL})에 연결할 수 없습니다. 백엔드 주소를 확인해주세요.`);
    }
    if (!res.ok) {
      const err = await res.json().catch(() => ({}));
      throw new Error(err.detail || '로그인에 실패했습니다.');
    }
    return res.json();
  },
  getUserProfile: async (userId: number) => {
    let res: Response;
    try {
      res = await fetch(`${BASE_URL}/auth/${userId}/profile`, { signal: AbortSignal.timeout(8000) });
    } catch {
      throw new Error(`서버(${BASE_URL})에 연결할 수 없습니다. 백엔드 주소를 확인해주세요.`);
    }
    if (!res.ok) throw new Error('사용자 정보를 불러올 수 없습니다.');
    return res.json();
  },

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

  // 호실 비교 (같은 시설의 여러 호실에서 동일 role_name 값 겹쳐보기)
  getComparableRoles: async (facilityId: number) => {
    const res = await fetch(`${BASE_URL}/chart/compare/${facilityId}/available-roles`);
    if (!res.ok) throw new Error('비교 가능한 항목을 불러오지 못했습니다.');
    return res.json();
  },
  getCompareData: async (facilityId: number, roleName: string, scale: string, timeRange: string) => {
    const url = `${BASE_URL}/chart/compare/${facilityId}?role_name=${encodeURIComponent(roleName)}&scale=${scale}&time_range=${timeRange}`;
    const res = await fetch(url);
    if (!res.ok) throw new Error('비교 데이터를 불러오지 못했습니다.');
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
  },




// 시설 매니지먼트 

getAllFacilitiesAdmin: async () => {
  const res = await fetch(`${BASE_URL}/facility-manager/facilities`);
  return res.json();
},
createFacilityAdmin: async (data: any) => {
  const res = await fetch(`${BASE_URL}/facility-manager/facility`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify(data),
  });
  if (!res.ok) throw new Error(await res.text());
  return res.json();
},
updateFacilityAdmin: async (id: number, data: any) => {
  const res = await fetch(`${BASE_URL}/facility-manager/facility/${id}`, {
    method: 'PUT',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify(data),
  });
  return res.json();
},
getFacilityUsersAdmin: async (id: number) => {
  const res = await fetch(`${BASE_URL}/facility-manager/facility/${id}/users`);
  return res.json();
},
createRoomAdmin: async (facId: number, data: any) => {
  const res = await fetch(`${BASE_URL}/facility-manager/facility/${facId}/room`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify(data),
  });
  return res.json();
},
updateRoomAdmin: async (roomId: number, data: any) => {
  const res = await fetch(`${BASE_URL}/facility-manager/room/${roomId}`, {
    method: 'PUT',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify(data),
  });
  return res.json();
},
deleteRoomAdmin: async (roomId: number) => {
  const res = await fetch(`${BASE_URL}/facility-manager/room/${roomId}`, { method: 'DELETE' });
  return res.json();
},


getRolesByRoomAdmin: async (roomId: number) => {
  const res = await fetch(`${BASE_URL}/facility-manager/room/${roomId}/roles`);
  return res.json();
},
createPointRoleAdmin: async (facId: number, roomId: number, data: any) => {
  const res = await fetch(`${BASE_URL}/facility-manager/facility/${facId}/room/${roomId}/role`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify(data),
  });
  if (!res.ok) throw new Error(await res.text());
  return res.json();
},
updatePointRoleAdmin: async (roleId: number, data: any) => {
  const res = await fetch(`${BASE_URL}/facility-manager/role/${roleId}`, {
    method: 'PUT',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify(data),
  });
  if (!res.ok) throw new Error(await res.text());
  return res.json();
},
deletePointRoleAdmin: async (roleId: number) => {
  const res = await fetch(`${BASE_URL}/facility-manager/role/${roleId}`, { method: 'DELETE' });
  return res.json();
},

  getUserFacilities: async (userId: number) => {
    const response = await fetch(`/api/facilities/${userId}`);
    if (!response.ok) {
      throw new Error('사용자 시설 목록을 불러오는데 실패했습니다.');
    }
    return response.json();
  },


};