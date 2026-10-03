// 경로 : src/module/ServiceWeb/webui/api.js
const BASE_URL = '/api/v1/serviceweb';

export const CHART_SCOPING_CONFIG = {
  DEFAULT: {
    '1m':  { maxRange: 5 * 86400000,   chunkSize: 4 * 3600000,   maxChunks: 5 },
    '5m':  { maxRange: 15 * 86400000,  chunkSize: 1 * 86400000,  maxChunks: 5 },
    '10m': { maxRange: 30 * 86400000,  chunkSize: 3 * 86400000,  maxChunks: 5 },
    '15m': { maxRange: 60 * 86400000,  chunkSize: 5 * 86400000,  maxChunks: 5 },
    '1h':  { maxRange: 180 * 86400000, chunkSize: 10 * 86400000, maxChunks: 5 },
  },
  EXTENT: {
    '1m':  { maxRange: 20 * 86400000,  chunkSize: 1 * 86400000,  maxChunks: 10 },
    '5m':  { maxRange: 60 * 86400000,  chunkSize: 3 * 86400000,  maxChunks: 10 },
    '10m': { maxRange: 120 * 86400000, chunkSize: 5 * 86400000,  maxChunks: 10 },
    '15m': { maxRange: 240 * 86400000, chunkSize: 10 * 86400000, maxChunks: 10 },
    '1h':  { maxRange: 720 * 86400000, chunkSize: 15 * 86400000, maxChunks: 10 },
  }
};

export const apiService = {
  login: async (email, password, keepLogin = false) => {
    const res = await fetch(`${BASE_URL}/auth/login/general`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ email, password, keep_login: keepLogin }),
    });
    if (!res.ok) {
      const err = await res.json().catch(() => ({}));
      throw new Error(err.detail || '로그인에 실패했습니다.');
    }
    return res.json();
  },
  getUserProfile: async (userId) => {
    const res = await fetch(`${BASE_URL}/auth/${userId}/profile`);
    if (!res.ok) throw new Error('사용자 정보를 불러올 수 없습니다.');
    return res.json();
  },
  getFacilities: async (userId = 1) => {
    const res = await fetch(`${BASE_URL}/facilities/${userId}`);
    return res.json();
  },
  getRooms: async (facilityId) => {
    const res = await fetch(`${BASE_URL}/facilities/rooms/${facilityId}`);
    return res.json();
  },
  getPointRoles: async (facilityId, roomId) => {
    const res = await fetch(`${BASE_URL}/chart-mapping/roles/${facilityId}/${roomId}`);
    return res.json();
  },
  getChartGroups: async (facilityId, roomId) => {
    const res = await fetch(`${BASE_URL}/chart-mapping/groups/${facilityId}/${roomId}`);
    return res.json();
  },
  createChartGroup: async (data) => {
    const res = await fetch(`${BASE_URL}/chart-mapping/group`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify(data),
    });
    if (!res.ok) throw new Error(await res.text());
    return res.json();
  },
  getHistoricalData: async (facilityId, roomId, groupId, scale, startTime, endTime, roleIds) => {
    let url = `${BASE_URL}/chart/${facilityId}/${roomId}?scale=${scale}&start_time=${encodeURIComponent(startTime)}&end_time=${encodeURIComponent(endTime)}&role_ids=${roleIds.join(',')}`;
    if (groupId !== '') url += `&group_id=${groupId}`;
    const res = await fetch(url);
    return res.json();
  },
  getComparableRoles: async (facilityId) => {
    const res = await fetch(`${BASE_URL}/chart/compare/${facilityId}/available-roles`);
    if (!res.ok) throw new Error('비교 가능한 항목을 불러오지 못했습니다.');
    return res.json();
  },
  getCompareData: async (facilityId, roleName, scale, timeRange) => {
    const url = `${BASE_URL}/chart/compare/${facilityId}?role_name=${encodeURIComponent(roleName)}&scale=${scale}&time_range=${timeRange}`;
    const res = await fetch(url);
    if (!res.ok) throw new Error('비교 데이터를 불러오지 못했습니다.');
    return res.json();
  },
  hidePostFromGroup: async (groupId, postId) => {
    const res = await fetch(`${BASE_URL}/chart-mapping/group/${groupId}/hide-post/${postId}`, { method: 'POST' });
    return res.json();
  },
  showPostInGroup: async (groupId, postId) => {
    const res = await fetch(`${BASE_URL}/chart-mapping/group/${groupId}/show-post/${postId}`, { method: 'DELETE' });
    return res.json();
  },
  updatePointRoleIndexing: async (updates) => {
    const res = await fetch(`${BASE_URL}/chart-mapping/roles/indexing`, {
      method: 'PUT',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ updates }),
    });
    if (!res.ok) throw new Error(await res.text());
    return res.json();
  },

  // 시설/호실/롤 어드민
  getAllFacilitiesAdmin: async () => (await fetch(`${BASE_URL}/facility-manager/facilities`)).json(),
  createFacilityAdmin: async (data) => {
    const res = await fetch(`${BASE_URL}/facility-manager/facility`, {
      method: 'POST', headers: { 'Content-Type': 'application/json' }, body: JSON.stringify(data),
    });
    if (!res.ok) throw new Error(await res.text());
    return res.json();
  },
  updateFacilityAdmin: async (id, data) => (await fetch(`${BASE_URL}/facility-manager/facility/${id}`, {
    method: 'PUT', headers: { 'Content-Type': 'application/json' }, body: JSON.stringify(data),
  })).json(),
  getFacilityUsersAdmin: async (id) => (await fetch(`${BASE_URL}/facility-manager/facility/${id}/users`)).json(),
  createRoomAdmin: async (facId, data) => (await fetch(`${BASE_URL}/facility-manager/facility/${facId}/room`, {
    method: 'POST', headers: { 'Content-Type': 'application/json' }, body: JSON.stringify(data),
  })).json(),
  updateRoomAdmin: async (roomId, data) => (await fetch(`${BASE_URL}/facility-manager/room/${roomId}`, {
    method: 'PUT', headers: { 'Content-Type': 'application/json' }, body: JSON.stringify(data),
  })).json(),
  deleteRoomAdmin: async (roomId) => (await fetch(`${BASE_URL}/facility-manager/room/${roomId}`, { method: 'DELETE' })).json(),
  getRolesByRoomAdmin: async (roomId) => (await fetch(`${BASE_URL}/facility-manager/room/${roomId}/roles`)).json(),
  createPointRoleAdmin: async (facId, roomId, data) => {
    const res = await fetch(`${BASE_URL}/facility-manager/facility/${facId}/room/${roomId}/role`, {
      method: 'POST', headers: { 'Content-Type': 'application/json' }, body: JSON.stringify(data),
    });
    if (!res.ok) throw new Error(await res.text());
    return res.json();
  },
  updatePointRoleAdmin: async (roleId, data) => {
    const res = await fetch(`${BASE_URL}/facility-manager/role/${roleId}`, {
      method: 'PUT', headers: { 'Content-Type': 'application/json' }, body: JSON.stringify(data),
    });
    if (!res.ok) throw new Error(await res.text());
    return res.json();
  },
  deletePointRoleAdmin: async (roleId) => (await fetch(`${BASE_URL}/facility-manager/role/${roleId}`, { method: 'DELETE' })).json(),

  // M2M 엣지 노드 어드민 (기존 ServiceWeb/webui/index.html 기능 통합)
  getNodeFacilities: async () => (await fetch(`${BASE_URL}/admin/nodes/facilities`)).json(),
  getNodes: async () => (await fetch(`${BASE_URL}/admin/nodes`)).json(),
  createNode: async (data) => {
    const res = await fetch(`${BASE_URL}/admin/nodes`, {
      method: 'POST', headers: { 'Content-Type': 'application/json' }, body: JSON.stringify(data),
    });
    const json = await res.json();
    if (!res.ok) throw new Error(json.detail || '노드 생성 실패');
    return json;
  },
  updateNode: async (nodeId, data) => (await fetch(`${BASE_URL}/admin/nodes/${nodeId}`, {
    method: 'PATCH', headers: { 'Content-Type': 'application/json' }, body: JSON.stringify(data),
  })).json(),
  rotateNodeKey: async (nodeId) => (await fetch(`${BASE_URL}/admin/nodes/${nodeId}/rotate-key`, { method: 'POST' })).json(),
  deleteNode: async (nodeId) => (await fetch(`${BASE_URL}/admin/nodes/${nodeId}`, { method: 'DELETE' })).json(),
};