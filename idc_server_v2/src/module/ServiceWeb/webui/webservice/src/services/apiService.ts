// const BASE_URL = 'http://127.0.0.1:8000/api';
// const BASE_URL = 'http://localhost:8000/api';
// const BASE_URL = 'http://192.168.29.159:8000/api';
// const BASE_URL = 'http://211.55.127.239/api';
// const BASE_URL = 'http://192.168.29.159:8900/api/v1/serviceweb';
// const BASE_URL = 'http://127.0.0.1:8900/api';

const BASE_URL = '/api/v1/serviceweb';

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
    const res = await fetch(`${BASE_URL}/auth/${userId}/profile`, { signal: AbortSignal.timeout(8000) });
    if (!res.ok) throw new Error('사용자 정보를 불러올 수 없습니다.');
    return res.json();
  },
  /**
   * 로그인한 사용자가 속한 시설만 돌려준다.
   *
   * 예전에는 사용자 id 가 1로 박혀 있어서, 누가 로그인하든 1번 계정의 시설
   * 목록(지금 9곳)이 떴다. 다른 회사 창고가 그대로 보였다는 뜻이다.
   *
   * 시설 전체가 필요한 곳은 시설 관리 화면뿐이고, 그건 getAllFacilitiesAdmin 이다.
   */
  getUserFacilities: async (userId: number) => {
    const res = await fetch(`${BASE_URL}/facilities/${userId}`);
    return res.json();
  },
  getFacilityAlarms: async (facilityId: number) => {
    const res = await fetch(`${BASE_URL}/alarms/facility/${facilityId}`);
    if (!res.ok) throw new Error('알람을 불러오지 못했습니다.');
    const json = await res.json();
    return Array.isArray(json) ? json : (json.alarms ?? []);
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
  getHistoricalData: async (facilityId: number, roomId: number, groupId: number | '', scale: string, startTime: string, endTime: string, roleIds: number[]) => {
    let url = `${BASE_URL}/chart/${facilityId}/${roomId}?scale=${scale}&start_time=${encodeURIComponent(startTime)}&end_time=${encodeURIComponent(endTime)}&role_ids=${roleIds.join(',')}`;
    if (groupId !== '') url += `&group_id=${groupId}`;
    const res = await fetch(url);
    return res.json();
  },
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
  getAllFacilitiesAdmin: async (userId: number) => (await fetch(`${BASE_URL}/facility-manager/facilities?user_id=${userId}`)).json(),
  createFacilityAdmin: async (userId: number, data: any) => {
    const res = await fetch(`${BASE_URL}/facility-manager/facility?user_id=${userId}`, {
      method: 'POST', headers: { 'Content-Type': 'application/json' }, body: JSON.stringify(data),
    });
    if (!res.ok) throw new Error(await res.text());
    return res.json();
  },
  updateFacilityAdmin: async (id: number, data: any) => (await fetch(`${BASE_URL}/facility-manager/facility/${id}`, {
    method: 'PUT', headers: { 'Content-Type': 'application/json' }, body: JSON.stringify(data),
  })).json(),
  getFacilityUsersAdmin: async (id: number) => (await fetch(`${BASE_URL}/facility-manager/facility/${id}/users`)).json(),
  createRoomAdmin: async (facId: number, data: any) => (await fetch(`${BASE_URL}/facility-manager/facility/${facId}/room`, {
    method: 'POST', headers: { 'Content-Type': 'application/json' }, body: JSON.stringify(data),
  })).json(),
  updateRoomAdmin: async (roomId: number, data: any) => (await fetch(`${BASE_URL}/facility-manager/room/${roomId}`, {
    method: 'PUT', headers: { 'Content-Type': 'application/json' }, body: JSON.stringify(data),
  })).json(),
  deleteRoomAdmin: async (roomId: number) => (await fetch(`${BASE_URL}/facility-manager/room/${roomId}`, { method: 'DELETE' })).json(),
  getRolesByRoomAdmin: async (roomId: number) => (await fetch(`${BASE_URL}/facility-manager/room/${roomId}/roles`)).json(),
  createPointRoleAdmin: async (facId: number, roomId: number, data: any) => {
    const res = await fetch(`${BASE_URL}/facility-manager/facility/${facId}/room/${roomId}/role`, {
      method: 'POST', headers: { 'Content-Type': 'application/json' }, body: JSON.stringify(data),
    });
    if (!res.ok) throw new Error(await res.text());
    return res.json();
  },
  updatePointRoleAdmin: async (roleId: number, data: any) => {
    const res = await fetch(`${BASE_URL}/facility-manager/role/${roleId}`, {
      method: 'PUT', headers: { 'Content-Type': 'application/json' }, body: JSON.stringify(data),
    });
    if (!res.ok) throw new Error(await res.text());
    return res.json();
  },
  deletePointRoleAdmin: async (roleId: number) => (await fetch(`${BASE_URL}/facility-manager/role/${roleId}`, { method: 'DELETE' })).json(),

  // M2M 엣지 노드 관리 API
  getNodeFacilities: async (userId: number) => (await fetch(`${BASE_URL}/admin/nodes/facilities?user_id=${userId}`)).json(),
  getNodes: async (userId: number) => (await fetch(`${BASE_URL}/admin/nodes?user_id=${userId}`)).json(),
  createNode: async (data: { facility_id: number; node_code: string; node_name: string }) => {
    const res = await fetch(`${BASE_URL}/admin/nodes`, {
      method: 'POST', headers: { 'Content-Type': 'application/json' }, body: JSON.stringify(data),
    });
    const json = await res.json();
    if (!res.ok) throw new Error(json.detail || '노드 생성 실패');
    return json;
  },
  updateNode: async (nodeId: number, data: { node_name?: string; facility_id?: number }) => {
    const res = await fetch(`${BASE_URL}/admin/nodes/${nodeId}`, {
      method: 'PATCH', headers: { 'Content-Type': 'application/json' }, body: JSON.stringify(data),
    });
    if (!res.ok) throw new Error('노드 수정 실패');
    return res.json();
  },
  rotateNodeKey: async (nodeId: number) => {
    const res = await fetch(`${BASE_URL}/admin/nodes/${nodeId}/rotate-key`, { method: 'POST' });
    const json = await res.json();
    if (!res.ok) throw new Error(json.detail || '키 재발급 실패');
    return json;
  },
  deleteNode: async (nodeId: number) => {
    const res = await fetch(`${BASE_URL}/admin/nodes/${nodeId}`, { method: 'DELETE' });
    if (!res.ok) throw new Error('노드 삭제 실패');
    return res.json();
  },
  getDebugConfig: async () => {
    try {
      const res = await fetch(`${BASE_URL}/auth/debug-config`);
      if (!res.ok) return { enabled: false };
      return res.json();
    } catch {
      return { enabled: false };
    }
  },
};