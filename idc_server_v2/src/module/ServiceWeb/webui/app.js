// 경로 : src/module/ServiceWeb/webui/app.js
import React, { useState, useEffect, useRef, useCallback } from 'https://esm.sh/react@18.3.1';
import { createRoot } from 'https://esm.sh/react-dom@18.3.1/client?deps=react@18.3.1';
import htm from 'https://esm.sh/htm@3.1.1';
import { apiService, CHART_SCOPING_CONFIG } from './api.js';

const html = htm.bind(React.createElement);
const echarts = window.echarts;
const SYNC_GROUP_NAME = 'idcool-chart-group';
if (echarts) echarts.connect(SYNC_GROUP_NAME);

// ===================== Brand 컴포넌트 =====================
const Monogram = ({ size = 32 }) => html`
  <div style=${{
    width: size, height: size, borderRadius: size * 0.28,
    background: 'linear-gradient(135deg, var(--primary-light, #5c8def), var(--primary-dark, #1e4fbd))',
    color: '#fff', display: 'flex', alignItems: 'center', justifyContent: 'center',
    fontWeight: 800, fontSize: size * 0.42, letterSpacing: -1,
    boxShadow: `0 ${size * 0.14}px ${size * 0.32}px -${size * 0.1}px rgba(46,107,239,0.45)`, flexShrink: 0,
  }}>ic</div>
`;

const Wordmark = ({ size = 17 }) => html`
  <span style=${{ fontSize: size, fontWeight: 800, letterSpacing: -0.3 }}>
    ID<span style=${{ color: 'var(--primary)' }}>Cool</span>
  </span>
`;

// ===================== ECharts 래퍼 컴포넌트 =====================
const EChartBox = ({ option, isLoading, chartRef, onClick }) => {
  const containerRef = useRef(null);
  const instanceRef = useRef(null);

  useEffect(() => {
    if (!containerRef.current || !echarts) return;
    const inst = echarts.init(containerRef.current);
    inst.group = SYNC_GROUP_NAME;
    instanceRef.current = inst;
    if (chartRef) chartRef.current = inst;

    const ro = new ResizeObserver(() => inst.resize());
    ro.observe(containerRef.current);
    return () => { ro.disconnect(); inst.dispose(); };
  }, []);

  useEffect(() => {
    const inst = instanceRef.current;
    if (!inst) return;
    inst.off('click');
    if (onClick) inst.on('click', onClick);
  }, [onClick]);

  useEffect(() => {
    const inst = instanceRef.current;
    if (!inst || !option) return;
    inst.setOption(option, true);
  }, [option]);

  useEffect(() => {
    const inst = instanceRef.current;
    if (!inst) return;
    if (isLoading) inst.showLoading();
    else inst.hideLoading();
  }, [isLoading]);

  return html`<div ref=${containerRef} style=${{ width: '100%', height: '100%' }} />`;
};

const formatShortTime = (ts) => {
  const d = new Date(ts);
  return `${String(d.getMonth() + 1).padStart(2, '0')}/${String(d.getDate()).padStart(2, '0')} ${String(d.getHours()).padStart(2, '0')}:${String(d.getMinutes()).padStart(2, '0')}`;
};

const generatePostSegments = (validPosts) => {
  if (!validPosts || validPosts.length === 0) return [];
  const points = new Set();
  validPosts.forEach(p => { points.add(p.st); points.add(p.et); });
  const sorted = Array.from(points).sort((a, b) => a - b);
  const segments = [];
  for (let i = 0; i < sorted.length - 1; i++) {
    const segSt = sorted[i], segEt = sorted[i + 1];
    if (segSt === segEt) continue;
    const activePosts = validPosts.filter(p => p.st <= segSt && p.et >= segEt);
    if (activePosts.length > 0) segments.push({ st: segSt, et: segEt, activePosts });
  }
  return segments;
};

const MainChartViewer = ({ datasets = [], roleColors = {}, showInfo = true, showGrid = true, chartRef, activeGuidelines = [], isLoading = false, posts = [], alarms = [], onChartClick, loadedRange }) => {
  const buildOption = () => {
    const seriesData = datasets.map(ds => {
      const color = roleColors[ds.role_id];
      const item = {
        name: ds.display_name || ds.role_name,
        type: 'line', showSymbol: false, itemStyle: { color },
        data: (ds.data || []).map(pt => [new Date(pt.timestamp).getTime(), pt.mean])
      };
      if (activeGuidelines.includes(ds.role_id)) {
        const markLineData = [];
        if (ds.target_value != null) markLineData.push({ yAxis: Number(ds.target_value), name: 'Target', lineStyle: { type: 'solid', color, width: 2 } });
        if (ds.target_low_limit != null) markLineData.push({ yAxis: Number(ds.target_low_limit), name: 'Low', lineStyle: { type: 'dashed', color, width: 1.5 } });
        if (ds.target_high_limit != null) markLineData.push({ yAxis: Number(ds.target_high_limit), name: 'High', lineStyle: { type: 'dashed', color, width: 1.5 } });
        if (markLineData.length > 0) {
          item.markLine = { data: markLineData, symbol: 'none', label: { show: true, position: 'start', formatter: '{b}: {c}', color, fontSize: 11 } };
        }
      }
      return item;
    });

    const validPosts = posts.filter(p => p.start_date && p.end_date).map(p => {
      const st = new Date(p.start_date).getTime();
      let et = new Date(p.end_date).getTime();
      if (st === et) et += 3600000;
      return { ...p, st, et };
    });

    const postAreas = generatePostSegments(validPosts).map(seg => [
      { xAxis: seg.st, postIds: seg.activePosts.map(p => p.id), itemStyle: { color: 'rgba(214, 69, 69, 0.06)' }, label: { show: true, position: 'insideTop', formatter: seg.activePosts.map(p => p.title).join('\n'), color: '#d64545', fontWeight: 'bold', fontSize: 12 } },
      { xAxis: seg.et }
    ]);

    const globalLines = [];
    validPosts.forEach(p => {
      globalLines.push({ xAxis: p.st, label: { show: true, position: 'end', formatter: formatShortTime(p.st), color: '#d64545', fontSize: 10 }, lineStyle: { type: 'solid', color: '#d64545', width: 2 } });
      globalLines.push({ xAxis: p.et, label: { show: true, position: 'end', formatter: formatShortTime(p.et), color: '#d64545', fontSize: 10 }, lineStyle: { type: 'solid', color: '#d64545', width: 2 } });
    });
    alarms.forEach(a => {
      const time = new Date(a.timestamp).getTime();
      globalLines.push({ xAxis: time, label: { show: true, position: 'end', formatter: formatShortTime(time), color: '#0891b2', fontSize: 10 }, lineStyle: { type: 'dashed', color: '#0891b2', width: 2 } });
      globalLines.push({ xAxis: time, label: { show: true, position: 'start', formatter: a.alarm_name, color: '#0891b2', fontSize: 10 }, lineStyle: { type: 'dashed', color: '#0891b2', width: 2 } });
    });

    seriesData.push({ name: 'GlobalAnnotations', type: 'line', data: [], markArea: { silent: false, data: postAreas }, markLine: { silent: false, symbol: ['none', 'none'], z: 10, data: globalLines } });

    return {
      tooltip: { show: showInfo, trigger: 'axis', axisPointer: { type: 'cross' } },
      axisPointer: { link: [{ xAxisIndex: 'all' }] },
      grid: { left: 60, right: 50, top: 40, bottom: 25 },
      xAxis: { type: 'time', min: loadedRange?.start, max: loadedRange?.end, splitLine: { show: showGrid, lineStyle: { color: '#e5e7eb' } } },
      yAxis: { type: 'value', name: '수치 (Main)', splitLine: { show: showGrid, lineStyle: { color: '#e5e7eb' } }, scale: true },
      dataZoom: [{ type: 'inside', filterMode: 'empty' }],
      series: seriesData
    };
  };

  const handleClick = useCallback((params) => {
    if (params.seriesName === 'GlobalAnnotations' && params.data?.postIds && onChartClick) {
      onChartClick('post', params.data.postIds);
    }
  }, [onChartClick]);

  return html`<${EChartBox} chartRef=${chartRef} option=${buildOption()} isLoading=${isLoading} onClick=${handleClick} />`;
};

const SubChartViewer = ({ datasets = [], roleColors = {}, showInfo = true, showGrid = true, chartRef, isLoading = false, posts = [], alarms = [], loadedRange, invertedBools = [] }) => {
  const buildOption = () => {
    const seriesData = [];
    const boolCategories = datasets.map(ds => ds.display_name || ds.role_name);
    datasets.forEach((ds, index) => {
      const isInverted = invertedBools.includes(ds.role_id);
      const mappedData = (ds.data || [])
        .filter(pt => {
          const isTrue = pt.status === true || pt.status === 1 || String(pt.status) === 'true' || pt.mean === 1;
          return isInverted ? !isTrue : isTrue;
        })
        .map(pt => [new Date(pt.timestamp).getTime(), index]);
      seriesData.push({ name: ds.display_name || ds.role_name, type: 'scatter', symbol: 'rect', symbolSize: [6, 20], itemStyle: { color: roleColors[ds.role_id] }, data: mappedData });
    });

    return {
      tooltip: { show: showInfo, trigger: 'axis', axisPointer: { type: 'cross' } },
      grid: { left: 60, right: 50, top: 10, bottom: 25 },
      xAxis: { type: 'time', min: loadedRange?.start, max: loadedRange?.end, splitLine: { show: showGrid, lineStyle: { color: '#e5e7eb' } } },
      yAxis: { type: 'category', name: '상태 (Sub)', data: boolCategories.length > 0 ? boolCategories : ['데이터 없음'], splitLine: { show: showGrid, lineStyle: { color: '#e5e7eb', type: 'dashed' } } },
      dataZoom: [{ type: 'inside', filterMode: 'empty' }, { type: 'slider', bottom: 0, height: 20, filterMode: 'empty' }],
      series: seriesData
    };
  };

  return html`<${EChartBox} chartRef=${chartRef} option=${buildOption()} isLoading=${isLoading} />`;
};

// ===================== 1. LoginPage =====================
const LoginPage = ({ onLogin }) => {
  const [email, setEmail] = useState('');
  const [password, setPassword] = useState('');
  const [showDevTools, setShowDevTools] = useState(false);

  const handleLogin = async (e) => {
    e.preventDefault();
    try {
      const loginRes = await apiService.login(email, password);
      const profile = await apiService.getUserProfile(loginRes.user_id);
      onLogin({ id: loginRes.user_id, email, name: profile.name, role: loginRes.role });
    } catch (err) {
      alert(err.message || '로그인 실패');
    }
  };

  return html`
    <div style=${{ display: 'flex', flexDirection: 'column', justifyContent: 'center', alignItems: 'center', flex: 1, gap: 24, padding: 24 }}>
      <div style=${{ display: 'flex', flexDirection: 'column', alignItems: 'center', gap: 10 }}>
        <${Monogram} size=${56} />
        <div style=${{ marginTop: 4 }}><${Wordmark} size=${22} /></div>
        <p style=${{ color: 'var(--text-secondary)', fontSize: 13 }}>관리자 계정으로 로그인해주세요.</p>
      </div>
      <form onSubmit=${handleLogin} className="card" style=${{ display: 'flex', flexDirection: 'column', gap: 14, width: 320 }}>
        <input type="email" placeholder="이메일" value=${email} onChange=${e => setEmail(e.target.value)} required className="input" />
        <input type="password" placeholder="비밀번호" value=${password} onChange=${e => setPassword(e.target.value)} required className="input" />
        <button type="submit" className="btn btn-primary" style=${{ height: 44 }}>로그인</button>
      </form>
      <div style=${{ width: 320 }}>
        <button type="button" onClick=${() => setShowDevTools(v => !v)} className="btn btn-ghost btn-sm" style=${{ width: '100%' }}>
          ${showDevTools ? '▲' : '▼'} 개발자 도구 (DEBUG 전용)
        </button>
        ${showDevTools && html`
          <div style=${{ display: 'flex', gap: 8, marginTop: 8 }}>
            <button type="button" onClick=${() => { setEmail('admin1@system.com'); setPassword('hashed_password'); }} className="btn btn-outline btn-sm" style=${{ flex: 1 }}>관리자 계정 주입</button>
            <button type="button" onClick=${() => { setEmail('user_a@test.com'); setPassword('hashed_password'); }} className="btn btn-outline btn-sm" style=${{ flex: 1 }}>사용자 계정 주입</button>
          </div>
        `}
      </div>
    </div>
  `;
};

// ===================== 2. MainPage & M2M Node 관리 페이지 통합 =====================
const MainAndNodePage = () => {
  const [facilities, setFacilities] = useState([]);
  const [nodes, setNodes] = useState([]);
  const [facId, setFacId] = useState('');
  const [nodeCode, setNodeCode] = useState('');
  const [nodeName, setNodeName] = useState('');
  const [issuedKey, setIssuedKey] = useState(null);

  const loadData = async () => {
    try {
      const [fRes, nRes] = await Promise.all([apiService.getNodeFacilities(), apiService.getNodes()]);
      const facList = fRes.data || [];
      setFacilities(facList);
      if (!facId && facList.length > 0) setFacId(facList[0].id);
      setNodes(nRes.data || []);
    } catch (e) { console.error(e); }
  };

  useEffect(() => {
    loadData();
    const timer = setInterval(loadData, 3000);
    return () => clearInterval(timer);
  }, []);

  const handleCreate = async () => {
    if (!facId || !nodeCode.trim() || !nodeName.trim()) return alert('모든 필드를 입력하세요.');
    try {
      const res = await apiService.createNode({ facility_id: Number(facId), node_code: nodeCode.trim(), node_name: nodeName.trim() });
      setIssuedKey(res.api_key);
      setNodeCode(''); setNodeName('');
      loadData();
    } catch (e) { alert(e.message); }
  };

  const handleEdit = async (node) => {
    const newName = prompt('변경할 노드 명칭을 입력하세요:', node.node_name);
    if (!newName || !newName.trim() || newName === node.node_name) return;
    await apiService.updateNode(node.id, { node_name: newName.trim() });
    loadData();
  };

  const handleRotate = async (nodeId) => {
    if (!confirm('키를 재발급하면 기존 키로 연결된 통신은 즉시 차단됩니다. 진행하시겠습니까?')) return;
    const res = await apiService.rotateNodeKey(nodeId);
    if (res.new_api_key) setIssuedKey(res.new_api_key);
  };

  const handleDelete = async (nodeId) => {
    if (!confirm('정말 이 노드를 삭제하시겠습니까?')) return;
    await apiService.deleteNode(nodeId);
    loadData();
  };

  return html`
    <div style=${{ display: 'flex', flexDirection: 'column', gap: 16, padding: 24 }}>
      <div style=${{ display: 'flex', alignItems: 'center', gap: 12 }}>
        <${Monogram} size=${40} />
        <div>
          <h2 style=${{ fontSize: 20, fontWeight: 800 }}>관리자 대시보드 & M2M 엣지 노드 컨트롤러</h2>
          <p style=${{ color: 'var(--text-secondary)', fontSize: 13 }}>시설별 FServer 엣지 노드 API Key 발급 및 실시간 연결 상태를 관리합니다.</p>
        </div>
      </div>

      <div style=${{ display: 'grid', gridTemplateColumns: '340px 1fr', gap: 16 }}>
        <div className="card" style=${{ display: 'flex', flexDirection: 'column', gap: 10 }}>
          <h4 style=${{ color: 'var(--primary)' }}>새 엣지 노드 발급</h4>
          <span className="label">소속 시설 선택</span>
          <select className="input" value=${facId} onChange=${e => setFacId(e.target.value)}>
            ${facilities.map(f => html`<option key=${f.id} value=${f.id}>${f.name}</option>`)}
          </select>
          <span className="label">노드 식별 코드 (Unique)</span>
          <input className="input" placeholder="예: NODE_FACILITY_D" value=${nodeCode} onChange=${e => setNodeCode(e.target.value)} />
          <span className="label">노드 명칭</span>
          <input className="input" placeholder="예: 제1시설 공조제어 노드" value=${nodeName} onChange=${e => setNodeName(e.target.value)} />
          <button className="btn btn-primary" onClick=${handleCreate} style=${{ marginTop: 6 }}>API Key 발급 및 노드 등록</button>
        </div>

        <div className="card" style=${{ display: 'flex', flexDirection: 'column', gap: 12 }}>
          <div style=${{ display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
            <h4>등록된 시스템 노드 현황</h4>
            <button className="btn btn-outline btn-sm" onClick=${loadData}>새로고침</button>
          </div>
          <table style=${{ width: '100%', borderCollapse: 'collapse', fontSize: 13 }}>
            <thead>
              <tr style=${{ borderBottom: '1px solid var(--border)', color: 'var(--text-secondary)', textAlign: 'left' }}>
                <th style=${{ padding: 10 }}>ID</th>
                <th style=${{ padding: 10 }}>소속 시설명</th>
                <th style=${{ padding: 10 }}>노드 코드</th>
                <th style=${{ padding: 10 }}>명칭</th>
                <th style=${{ padding: 10 }}>상태</th>
                <th style=${{ padding: 10 }}>최근 신호</th>
                <th style=${{ padding: 10 }}>관리</th>
              </tr>
            </thead>
            <tbody>
              ${nodes.map(n => html`
                <tr key=${n.id} style=${{ borderBottom: '1px solid var(--border)' }}>
                  <td style=${{ padding: 10 }}>${n.id}</td>
                  <td style=${{ padding: 10 }}><strong>${n.facility_name}</strong></td>
                  <td style=${{ padding: 10 }}><code>${n.node_code}</code></td>
                  <td style=${{ padding: 10 }}>${n.node_name}</td>
                  <td style=${{ padding: 10 }}>
                    <span className=${n.status === 'ONLINE' ? 'badge-online' : 'badge-offline'}>${n.status}</span>
                  </td>
                  <td style=${{ padding: 10, color: 'var(--text-secondary)', fontSize: 12 }}>
                    ${n.last_heartbeat_at ? new Date(n.last_heartbeat_at).toLocaleTimeString() : '-'}
                  </td>
                  <td style=${{ padding: 10, display: 'flex', gap: 6 }}>
                    <button className="btn btn-outline btn-sm" onClick=${() => handleEdit(n)}>수정</button>
                    <button className="btn btn-ghost btn-sm" onClick=${() => handleRotate(n.id)}>재발급</button>
                    <button className="btn btn-danger btn-sm" onClick=${() => handleDelete(n.id)}>삭제</button>
                  </td>
                </tr>
              `)}
            </tbody>
          </table>
        </div>
      </div>

      ${issuedKey && html`
        <div style=${{ position: 'fixed', inset: 0, background: 'rgba(0,0,0,0.6)', display: 'flex', alignItems: 'center', justifyContent: 'center', zIndex: 1000 }}>
          <div className="card" style=${{ width: 440, display: 'flex', flexDirection: 'column', gap: 12 }}>
            <h3 style=${{ color: 'var(--primary)' }}>API Key 발급 완료</h3>
            <p style=${{ fontSize: 13, color: 'var(--text-secondary)' }}>발급된 원문 API Key는 지금 단 한 번만 표시됩니다. 엣지 노드의 .env 파일에 복사해 두세요.</p>
            <div style=${{ padding: 12, background: 'var(--bg)', border: '1px dashed var(--primary)', borderRadius: 8, fontFamily: 'monospace', wordBreak: 'break-all', color: 'var(--primary)' }}>
              ${issuedKey}
            </div>
            <button className="btn btn-primary" onClick=${() => { navigator.clipboard.writeText(issuedKey); setIssuedKey(null); alert('복사되었습니다.'); }}>복사 후 창 닫기</button>
          </div>
        </div>
      `}
    </div>
  `;
};

// ===================== 3. ChartMappingPage =====================
const ChartMappingPage = () => {
  const [facilities, setFacilities] = useState([]);
  const [rooms, setRooms] = useState([]);
  const [selectedFacility, setSelectedFacility] = useState(null);
  const [selectedRoom, setSelectedRoom] = useState(null);
  const [room0Roles, setRoom0Roles] = useState([]);
  const [targetRoomRoles, setTargetRoomRoles] = useState([]);
  const [existingGroups, setExistingGroups] = useState([]);
  const [selectedGroupId, setSelectedGroupId] = useState('new');
  const [groupName, setGroupName] = useState('');
  const [droppedRoles, setDroppedRoles] = useState([]);

  useEffect(() => { apiService.getFacilities().then(d => setFacilities(d.facilities || [])); }, []);

  const handleFacilityChange = async (facId) => {
    setSelectedFacility(facId); setSelectedRoom(null); setTargetRoomRoles([]); setExistingGroups([]);
    setSelectedGroupId('new'); setGroupName(''); setDroppedRoles([]);
    const roomData = await apiService.getRooms(facId);
    setRooms(roomData.rooms || []);
    const role0Data = await apiService.getPointRoles(facId, 0);
    setRoom0Roles(role0Data.roles || []);
  };

  const handleRoomChange = async (roomId) => {
    setSelectedRoom(roomId); setSelectedGroupId('new'); setGroupName(''); setDroppedRoles([]);
    if (selectedFacility) {
      const [roleData, groupData] = await Promise.all([
        apiService.getPointRoles(selectedFacility, roomId),
        apiService.getChartGroups(selectedFacility, roomId)
      ]);
      setTargetRoomRoles(roleData.roles || []);
      setExistingGroups(groupData.groups || []);
    }
  };

  const handleGroupSelect = (val) => {
    if (val === 'new') { setSelectedGroupId('new'); setGroupName(''); setDroppedRoles([]); return; }
    const gId = Number(val);
    setSelectedGroupId(gId);
    const targetGroup = existingGroups.find(g => g.group_id === gId);
    if (targetGroup) {
      setGroupName(targetGroup.group_name);
      const all = [...room0Roles, ...targetRoomRoles];
      const loaded = (targetGroup.role_ids || []).filter(id => id != null).map(id => all.find(r => r.role_id === id)).filter(Boolean);
      setDroppedRoles(loaded);
    }
  };

  const handleSaveGroup = async () => {
    if (!selectedFacility || !selectedRoom) return alert('시설과 호실을 선택하세요.');
    if (!groupName) return alert('그룹 명칭을 입력하세요.');
    if (droppedRoles.length === 0) return alert('포인트 롤을 추가하세요.');
    try {
      await apiService.createChartGroup({
        facility_id: selectedFacility, room_id: selectedRoom,
        group_name: groupName, role_ids: droppedRoles.map(r => r.role_id)
      });
      alert('생성 완료!');
      handleRoomChange(selectedRoom);
    } catch { alert('저장 실패'); }
  };

  const droppedIds = droppedRoles.map(r => r.role_id);

  return html`
    <div style=${{ display: 'flex', flex: 1, minHeight: 0, height: '100%', gap: 12, padding: 24 }}>
      <div className="card" style=${{ flex: 1, display: 'flex', flexDirection: 'column', gap: 12 }}>
        <select value=${selectedFacility || ''} onChange=${e => handleFacilityChange(Number(e.target.value))} className="input">
          <option value="">시설 선택</option>
          ${facilities.map(f => html`<option key=${f.id} value=${f.id}>${f.name}</option>`)}
        </select>
        <div style=${{ display: 'flex', flex: 1, minHeight: 0, gap: 12 }}>
          <div style=${{ border: '1px solid var(--border)', borderRadius: 12, flex: 1, padding: 12, overflowY: 'auto' }}>
            <p className="label" style=${{ marginBottom: 10 }}>0호실 (공용)</p>
            ${room0Roles.filter(r => !droppedIds.includes(r.role_id)).map(role => html`
              <div key=${role.role_id} draggable onDragStart=${e => e.dataTransfer.setData('application/json', JSON.stringify(role))} className="card" style=${{ padding: '8px 10px', marginBottom: 6, cursor: 'grab', display: 'flex', alignItems: 'center', gap: 8 }}>
                <span className="chip">${role.short_name || role.role_name}</span>
                <span style=${{ fontSize: 13 }}>${role.display_name || role.role_name}</span>
              </div>
            `)}
          </div>
          <div style=${{ border: '1px solid var(--border)', borderRadius: 12, flex: 1, padding: 12, display: 'flex', flexDirection: 'column', gap: 10 }}>
            <select value=${selectedRoom || ''} onChange=${e => handleRoomChange(Number(e.target.value))} className="input">
              <option value="">호실 선택</option>
              ${rooms.map(r => html`<option key=${r.id} value=${r.id}>${r.name}</option>`)}
            </select>
            <div style=${{ flex: 1, overflowY: 'auto' }}>
              ${targetRoomRoles.filter(r => !droppedIds.includes(r.role_id)).map(role => html`
                <div key=${role.role_id} draggable onDragStart=${e => e.dataTransfer.setData('application/json', JSON.stringify(role))} className="card" style=${{ padding: '8px 10px', marginBottom: 6, cursor: 'grab', display: 'flex', alignItems: 'center', gap: 8 }}>
                  <span className="chip">${role.short_name || role.role_name}</span>
                  <span style=${{ fontSize: 13 }}>${role.display_name || role.role_name}</span>
                </div>
              `)}
            </div>
          </div>
        </div>
      </div>

      <div className="card" style=${{ flex: 1, display: 'flex', flexDirection: 'column', gap: 12 }}>
        <select value=${selectedGroupId} onChange=${e => handleGroupSelect(e.target.value)} className="input">
          <option value="new">+ 새로운 그룹 추가하기</option>
          ${existingGroups.map(g => html`<option key=${g.group_id} value=${g.group_id}>[불러오기] ${g.group_name}</option>`)}
        </select>
        <input type="text" placeholder="새 그룹 명칭 입력" value=${groupName} onChange=${e => setGroupName(e.target.value)} className="input" />
        <p className="label">드래그 앤 드롭 영역</p>
        <div
          onDragOver=${e => e.preventDefault()}
          onDrop=${e => {
            e.preventDefault();
            const raw = e.dataTransfer.getData('application/json');
            if (raw) {
              const role = JSON.parse(raw);
              if (!droppedRoles.find(r => r.role_id === role.role_id)) setDroppedRoles([...droppedRoles, role]);
            }
          }}
          style=${{ border: '2px dashed var(--border)', borderRadius: 12, flex: 1, padding: 12, overflowY: 'auto', background: 'var(--bg)' }}
        >
          ${droppedRoles.length === 0 && html`<p style=${{ color: 'var(--text-secondary)', fontSize: 13 }}>여기로 포인트 롤을 드래그하세요.</p>`}
          ${droppedRoles.map((role) => html`
            <div key=${role.role_id} className="card" style=${{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', padding: '8px 10px', marginBottom: 6 }}>
              <div style=${{ display: 'flex', alignItems: 'center', gap: 8 }}>
                <span className="chip">${role.short_name || role.role_name}</span>
                <span style=${{ fontSize: 13 }}>${role.display_name || role.role_name}</span>
              </div>
              <span onClick=${() => setDroppedRoles(droppedRoles.filter(r => r.role_id !== role.role_id))} style=${{ cursor: 'pointer', color: 'var(--text-secondary)' }}>✕</span>
            </div>
          `)}
        </div>
        <button onClick=${handleSaveGroup} className="btn btn-primary" style=${{ height: 44 }}>등록하기</button>
      </div>
    </div>
  `;
};

// ===================== 4. PRIndexingPage =====================
const PRIndexingPage = () => {
  const [facilities, setFacilities] = useState([]);
  const [rooms, setRooms] = useState([]);
  const [roles, setRoles] = useState([]);
  const [selectedFacility, setSelectedFacility] = useState('');
  const [selectedRoom, setSelectedRoom] = useState('');
  const [editMap, setEditMap] = useState({});

  useEffect(() => { apiService.getFacilities().then(res => setFacilities(res.facilities || [])); }, []);

  const handleFacilitySelect = async (facId) => {
    setSelectedFacility(facId); setSelectedRoom(''); setRoles([]); setEditMap({});
    const res = await apiService.getRooms(facId);
    setRooms(res.rooms || []);
  };

  const handleRoomSelect = async (roomId) => {
    setSelectedRoom(roomId);
    const res = await apiService.getPointRoles(Number(selectedFacility), roomId);
    const fetched = res.roles || [];
    setRoles(fetched);
    const init = {};
    fetched.forEach(r => {
      init[r.role_id] = {
        display_name: r.display_name !== r.role_name ? (r.display_name || '') : '',
        short_name: r.short_name !== r.role_name ? (r.short_name || '') : '',
      };
    });
    setEditMap(init);
  };

  const handleSaveAll = async () => {
    const payload = roles.map(r => ({
      role_id: r.role_id,
      display_name: editMap[r.role_id]?.display_name || '',
      short_name: editMap[r.role_id]?.short_name || ''
    }));
    try {
      await apiService.updatePointRoleIndexing(payload);
      alert('인덱싱 명칭이 성공적으로 저장되었습니다.');
      handleRoomSelect(Number(selectedRoom));
    } catch (e) { alert(`저장 실패: ${e.message}`); }
  };

  return html`
    <div style=${{ display: 'flex', flexDirection: 'column', flex: 1, minHeight: 0, gap: 12, padding: 24 }}>
      <div className="card" style=${{ display: 'flex', gap: 10, alignItems: 'center', padding: 14 }}>
        <select value=${selectedFacility} onChange=${e => handleFacilitySelect(Number(e.target.value))} className="input" style=${{ width: 200 }}>
          <option value="">-- 시설 선택 --</option>
          ${facilities.map(f => html`<option key=${f.id} value=${f.id}>${f.name}</option>`)}
        </select>
        <select value=${selectedRoom} onChange=${e => handleRoomSelect(Number(e.target.value))} disabled=${!selectedFacility} className="input" style=${{ width: 200 }}>
          <option value="">-- 호실 선택 --</option>
          ${rooms.map(r => html`<option key=${r.id} value=${r.id}>${r.name}</option>`)}
        </select>
        <div style=${{ flex: 1 }} />
        <button onClick=${handleSaveAll} disabled=${roles.length === 0} className="btn btn-primary">수정 확인</button>
      </div>

      <div className="card" style=${{ flex: 1, overflowY: 'auto', padding: 0 }}>
        <table style=${{ width: '100%', borderCollapse: 'collapse', fontSize: 13 }}>
          <thead style=${{ position: 'sticky', top: 0, background: 'var(--surface)', borderBottom: '1px solid var(--border)' }}>
            <tr>
              <th style=${{ padding: '12px 16px', width: 80 }}>ID</th>
              <th style=${{ padding: '12px 16px', width: 220 }}>기능형 명칭</th>
              <th style=${{ padding: '12px 16px' }}>디스플레이용 명칭</th>
              <th style=${{ padding: '12px 16px', width: 150 }}>약어 명칭 (3자)</th>
            </tr>
          </thead>
          <tbody>
            ${roles.map(r => html`
              <tr key=${r.role_id} style=${{ borderBottom: '1px solid var(--border)' }}>
                <td style=${{ padding: '8px 16px' }}>${r.role_id}</td>
                <td style=${{ padding: '8px 16px', fontFamily: 'monospace' }}>${r.role_name}</td>
                <td style=${{ padding: '6px 16px' }}>
                  <input className="input" style=${{ height: 36 }} placeholder=${r.role_name} value=${editMap[r.role_id]?.display_name || ''}
                    onChange=${e => setEditMap(p => ({ ...p, [r.role_id]: { ...p[r.role_id], display_name: e.target.value } }))} />
                </td>
                <td style=${{ padding: '6px 16px' }}>
                  <input className="input" style=${{ height: 36, textAlign: 'center', fontWeight: 700, color: 'var(--primary)' }} maxLength=${3} placeholder=${r.role_name.slice(0, 3)} value=${editMap[r.role_id]?.short_name || ''}
                    onChange=${e => setEditMap(p => ({ ...p, [r.role_id]: { ...p[r.role_id], short_name: e.target.value.toUpperCase() } }))} />
                </td>
              </tr>
            `)}
          </tbody>
        </table>
      </div>
    </div>
  `;
};

// ===================== 5. RoomComparePage =====================
const RoomComparePage = () => {
  const [facilities, setFacilities] = useState([]);
  const [selectedFacility, setSelectedFacility] = useState('');
  const [roles, setRoles] = useState([]);
  const [selectedRole, setSelectedRole] = useState('');
  const [scale, setScale] = useState('1m');
  const [timeRange, setTimeRange] = useState('1d');
  const [datasets, setDatasets] = useState([]);
  const [roleColors, setRoleColors] = useState({});
  const [isLoading, setIsLoading] = useState(false);

  const PALETTE = ['#2e6bef', '#d64545', '#1f8f5f', '#b6791f', '#1e4fbd', '#0c8599', '#9a60b4', '#ea7ccc'];

  useEffect(() => { apiService.getAllFacilitiesAdmin().then(res => setFacilities(res.facilities || [])); }, []);

  useEffect(() => {
    setSelectedRole(''); setRoles([]); setDatasets([]);
    if (!selectedFacility) return;
    apiService.getComparableRoles(Number(selectedFacility)).then(res => setRoles(res.data?.roles || []));
  }, [selectedFacility]);

  const handleCompare = async () => {
    if (!selectedFacility || !selectedRole) return;
    setIsLoading(true);
    try {
      const res = await apiService.getCompareData(Number(selectedFacility), selectedRole, scale, timeRange);
      const raw = res.data?.datasets || [];
      const colors = {};
      raw.forEach((ds, idx) => { colors[ds.role_id] = PALETTE[idx % PALETTE.length]; });
      setDatasets(raw.map(ds => ({ ...ds, display_name: ds.room_name })));
      setRoleColors(colors);
    } finally { setIsLoading(false); }
  };

  return html`
    <div style=${{ display: 'flex', flexDirection: 'column', flex: 1, gap: 12, padding: 24, minHeight: 0 }}>
      <h1 style=${{ fontSize: 24, fontWeight: 800 }}>호실 비교</h1>
      <div className="card" style=${{ display: 'flex', gap: 10, alignItems: 'flex-end', flexWrap: 'wrap' }}>
        <div style=${{ minWidth: 180 }}>
          <span className="label">시설</span>
          <select className="input" value=${selectedFacility} onChange=${e => setSelectedFacility(e.target.value ? Number(e.target.value) : '')}>
            <option value="">-- 시설 선택 --</option>
            ${facilities.map(f => html`<option key=${f.id} value=${f.id}>${f.name}</option>`)}
          </select>
        </div>
        <div style=${{ minWidth: 220 }}>
          <span className="label">비교할 항목</span>
          <select className="input" value=${selectedRole} onChange=${e => setSelectedRole(e.target.value)} disabled=${roles.length === 0}>
            <option value="">-- 항목 선택 --</option>
            ${roles.map(r => html`<option key=${r.role_name} value=${r.role_name}>${r.display_name} (${r.room_count}개 호실)</option>`)}
          </select>
        </div>
        <div style=${{ minWidth: 130 }}>
          <span className="label">해상도</span>
          <select className="input" value=${scale} onChange=${e => setScale(e.target.value)}>
            <option value="1m">1분 단위</option><option value="5m">5분 단위</option><option value="10m">10분 단위</option><option value="1h">1시간 단위</option>
          </select>
        </div>
        <div style=${{ minWidth: 130 }}>
          <span className="label">조회 기간</span>
          <select className="input" value=${timeRange} onChange=${e => setTimeRange(e.target.value)}>
            <option value="1h">최근 1시간</option><option value="12h">최근 12시간</option><option value="1d">최근 1일</option><option value="7d">최근 7일</option><option value="15d">최근 15일</option>
          </select>
        </div>
        <button className="btn btn-primary" style=${{ height: 42 }} onClick=${handleCompare} disabled=${!selectedFacility || !selectedRole || isLoading}>비교하기</button>
      </div>
      <div className="card" style=${{ flex: 1, minHeight: 420, padding: 12 }}>
        <${MainChartViewer} datasets=${datasets} roleColors=${roleColors} isLoading=${isLoading} showInfo=${true} showGrid=${true} />
      </div>
    </div>
  `;
};

// ===================== 6. FacilityManagerPage =====================
const FacilityManagerPage = () => {
  const [facilities, setFacilities] = useState([]);
  const [rooms, setRooms] = useState([]);
  const [users, setUsers] = useState([]);
  const [selectedFacility, setSelectedFacility] = useState('');
  const [expandedRoomIds, setExpandedRoomIds] = useState([]);
  const [roomRolesMap, setRoomRolesMap] = useState({});
  const [selectedRoom, setSelectedRoom] = useState(null);
  const [selectedRole, setSelectedRole] = useState(null);
  const [editFac, setEditFac] = useState(null);
  const [newFac, setNewFac] = useState({ name: '', access_code: '', start_date: '', end_date: '' });
  const [newRoomName, setNewRoomName] = useState('');
  const [newRole, setNewRole] = useState({ role_name: '', display_name: '', short_name: '', data_type: 'TEMP', target_value: '', target_low_limit: '', target_high_limit: '', valid_from: '', valid_to: '' });

  const loadFacilities = async () => {
    const res = await apiService.getAllFacilitiesAdmin();
    setFacilities(res.facilities || []);
  };
  useEffect(() => { loadFacilities(); }, []);

  const loadRoomsAndUsers = async (facId) => {
    const [rRes, uRes] = await Promise.all([apiService.getRooms(facId), apiService.getFacilityUsersAdmin(facId)]);
    setRooms(rRes.rooms || []); setUsers(uRes.users || []);
  };

  const loadRolesForRoom = async (roomId) => {
    const res = await apiService.getRolesByRoomAdmin(roomId);
    setRoomRolesMap(p => ({ ...p, [roomId]: res.roles || [] }));
  };

  const handleFacilityChange = (facId) => {
    setSelectedFacility(facId); setSelectedRoom(null); setSelectedRole(null); setExpandedRoomIds([]); setRoomRolesMap({});
    const target = facilities.find(f => f.id === facId);
    setEditFac(target ? { ...target, start_date: target.start_date || '', end_date: target.end_date || '' } : null);
    if (facId) loadRoomsAndUsers(facId);
  };

  return html`
    <div style=${{ display: 'flex', flexDirection: 'column', height: '100%', minHeight: 0, gap: 12, padding: 24 }}>
      <h1 style=${{ fontSize: 24, fontWeight: 800 }}>시설 / 호실 관리</h1>
      <div style=${{ display: 'flex', gap: 12, flex: 1, minHeight: 0, overflowX: 'auto' }}>
        <!-- 1열: 시설 -->
        <div className="card" style=${{ flex: 1, minWidth: 260, display: 'flex', flexDirection: 'column', gap: 10 }}>
          <h4>시설 관리</h4>
          <select value=${selectedFacility} onChange=${e => handleFacilityChange(Number(e.target.value))} className="input">
            <option value="">-- [시설 선택] --</option>
            ${facilities.map(f => html`<option key=${f.id} value=${f.id}>${f.name} (${f.access_code})</option>`)}
          </select>
          ${editFac ? html`
            <div style=${{ display: 'flex', flexDirection: 'column', gap: 6 }}>
              <span className="label">선택 시설 수정</span>
              <input className="input" value=${editFac.name} onChange=${e => setEditFac({ ...editFac, name: e.target.value })} />
              <input className="input" value=${editFac.access_code} onChange=${e => setEditFac({ ...editFac, access_code: e.target.value })} />
              <button className="btn btn-primary" onClick=${async () => { await apiService.updateFacilityAdmin(editFac.id, editFac); alert('수정됨'); loadFacilities(); }}>시설 갱신</button>
            </div>
          ` : html`
            <div style=${{ display: 'flex', flexDirection: 'column', gap: 6 }}>
              <span className="label">신규 시설 등록</span>
              <input className="input" placeholder="시설 이름" value=${newFac.name} onChange=${e => setNewFac({ ...newFac, name: e.target.value })} />
              <input className="input" placeholder="접근 코드" value=${newFac.access_code} onChange=${e => setNewFac({ ...newFac, access_code: e.target.value })} />
              <button className="btn btn-primary" onClick=${async () => { await apiService.createFacilityAdmin(newFac); setNewFac({ name: '', access_code: '', start_date: '', end_date: '' }); loadFacilities(); }}>시설 생성</button>
            </div>
          `}
          <h5 style=${{ fontSize: 12, color: 'var(--text-secondary)' }}>소속 유저 (${users.length}명)</h5>
          <div style=${{ flex: 1, overflowY: 'auto', fontSize: 12 }}>
            ${users.map(u => html`<div key=${u.id}><strong>${u.name}</strong> (${u.email})</div>`)}
          </div>
        </div>

        <!-- 2열: 호실 트리 -->
        <div className="card" style=${{ flex: 1.8, minWidth: 340, display: 'flex', flexDirection: 'column', gap: 10 }}>
          <h4>호실 및 포인트 롤 트리</h4>
          <div style=${{ display: 'flex', gap: 6 }}>
            <input className="input" style=${{ height: 36 }} placeholder="새 호실 명칭" value=${newRoomName} onChange=${e => setNewRoomName(e.target.value)} disabled=${!selectedFacility} />
            <button className="btn btn-primary btn-sm" onClick=${async () => { await apiService.createRoomAdmin(Number(selectedFacility), { name: newRoomName }); setNewRoomName(''); loadRoomsAndUsers(Number(selectedFacility)); }}>호실 추가</button>
          </div>
          <div style=${{ flex: 1, overflowY: 'auto' }}>
            ${rooms.map(r => {
              const isExp = expandedRoomIds.includes(r.id);
              const roles = roomRolesMap[r.id] || [];
              return html`
                <div key=${r.id} className="card" style=${{ marginBottom: 6, padding: 8 }}>
                  <div style=${{ display: 'flex', justifyContent: 'space-between', cursor: 'pointer' }} onClick=${() => { setSelectedRoom(r); setSelectedRole(null); }}>
                    <div onClick=${(e) => { e.stopPropagation(); if (isExp) setExpandedRoomIds(p => p.filter(x => x !== r.id)); else { setExpandedRoomIds(p => [...p, r.id]); loadRolesForRoom(r.id); } }}>${isExp ? '▼' : '▶'} <strong>${r.name}</strong> [${r.status}]
                    </div>
                    <button className="btn btn-danger btn-sm" onClick=${async (e) => { e.stopPropagation(); await apiService.deleteRoomAdmin(r.id); loadRoomsAndUsers(Number(selectedFacility)); }}>삭제</button>
                  </div>
                  ${isExp && html`
                    <div style=${{ paddingLeft: 20, marginTop: 6 }}>
                      ${roles.map(role => html`
                        <div key=${role.role_id} onClick=${() => setSelectedRole(role)} style=${{ display: 'flex', justifyContent: 'space-between', padding: 4, cursor: 'pointer' }}>
                          <span><span className="chip">${role.short_name || 'N/A'}</span>${role.display_name || role.role_name}</span>
                          <button onClick=${async (e) => { e.stopPropagation(); await apiService.deletePointRoleAdmin(role.role_id); loadRolesForRoom(r.id); }} style=${{ border: 'none', background: 'transparent', color: 'var(--error)', cursor: 'pointer' }}>✕</button>
                        </div>
                      `)}
                    </div>
                  `}
                </div>
              `;
            })}
          </div>
        </div>

        <!-- 3열: 포인트 롤 추가 -->
        <div className="card" style=${{ flex: 1.2, minWidth: 280, display: 'flex', flexDirection: 'column', gap: 8 }}>
          <h4>포인트 롤 관리 ${selectedRoom ? `(${selectedRoom.name})` : ''}</h4>
          <input className="input" style=${{ height: 36 }} placeholder="기능 명칭 (role_name)" value=${newRole.role_name} onChange=${e => setNewRole({ ...newRole, role_name: e.target.value })} disabled=${!selectedRoom} />
          <input className="input" style=${{ height: 36 }} placeholder="디스플레이 명칭" value=${newRole.display_name} onChange=${e => setNewRole({ ...newRole, display_name: e.target.value })} disabled=${!selectedRoom} />
          <input className="input" style=${{ height: 36 }} maxLength=${3} placeholder="약어 명칭 (3자)" value=${newRole.short_name} onChange=${e => setNewRole({ ...newRole, short_name: e.target.value.toUpperCase() })} disabled=${!selectedRoom} />
          <select className="input" style=${{ height: 36 }} value=${newRole.data_type} onChange=${e => setNewRole({ ...newRole, data_type: e.target.value })} disabled=${!selectedRoom}>
            <option value="TEMP">TEMP</option><option value="GEAR">GEAR</option><option value="BOOL">BOOL</option><option value="STATIC">STATIC</option>
          </select>
          <input className="input" style=${{ height: 36 }} placeholder="목표 수치 (target_value)" value=${newRole.target_value} onChange=${e => setNewRole({ ...newRole, target_value: e.target.value })} disabled=${!selectedRoom} />
          <button className="btn btn-primary" disabled=${!selectedRoom} onClick=${async () => {
            await apiService.createPointRoleAdmin(Number(selectedFacility), selectedRoom.id, newRole);
            alert('생성 완료'); loadRolesForRoom(selectedRoom.id);
          }}>신규 롤 생성</button>
        </div>
      </div>
    </div>
  `;
};

// ===================== 7. ChartViewerPage =====================
const getLocalDatetimeString = (date) => {
  const offset = date.getTimezoneOffset() * 60000;
  return (new Date(date.getTime() - offset)).toISOString().slice(0, 16);
};
const COLOR_PALETTE = ['#5470c6', '#91cc75', '#fac858', '#ee6666', '#73c0de', '#3ba272', '#fc8452', '#9a60b4', '#ea7ccc', '#ff9f7f'];

const ChartViewerPage = () => {
  const [mode, setMode] = useState('DEFAULT');
  const [scale, setScale] = useState('1m');
  const [targetDate, setTargetDate] = useState(getLocalDatetimeString(new Date()));
  const [refreshTrigger, setRefreshTrigger] = useState(0);

  const [facilities, setFacilities] = useState([]);
  const [rooms, setRooms] = useState([]);
  const [groups, setGroups] = useState([]);
  const [allRoles, setAllRoles] = useState([]);

  const [selectedFacility, setSelectedFacility] = useState('');
  const [selectedRoom, setSelectedRoom] = useState('');
  const [selectedGroupId, setSelectedGroupId] = useState('');
  const [checkedRoles, setCheckedRoles] = useState([]);

  const [chartDataSets, setChartDataSets] = useState([]);
  const [roleColors, setRoleColors] = useState({});
  const [showMainInfo, setShowMainInfo] = useState(true);
  const [showMainGrid, setShowMainGrid] = useState(true);
  const [showSubInfo, setShowSubInfo] = useState(false);
  const [showSubGrid, setShowSubGrid] = useState(true);
  const [activeGuidelines, setActiveGuidelines] = useState([]);
  const [invertedBools, setInvertedBools] = useState([]);
  const [isChartLoading, setIsChartLoading] = useState(false);

  const [posts, setPosts] = useState([]);
  const [alarms, setAlarms] = useState([]);
  const [hiddenPosts, setHiddenPosts] = useState([]);
  const [selectedPostViewerIds, setSelectedPostViewerIds] = useState([]);
  const [omniboxInput, setOmniboxInput] = useState('');

  const mainChartRef = useRef(null);
  const subChartRef = useRef(null);
  const [loadedRangeState, setLoadedRangeState] = useState(null);

  useEffect(() => { apiService.getFacilities().then(res => setFacilities(res.facilities || [])); }, []);

  useEffect(() => {
    if (!selectedFacility) { setRooms([]); setSelectedRoom(''); return; }
    setSelectedRoom(''); setRooms([]); setGroups([]); setAllRoles([]); setSelectedGroupId(''); setCheckedRoles([]);
    apiService.getRooms(Number(selectedFacility)).then(res => {
      const r = res.rooms || [];
      setRooms(r);
      if (r.length > 0) setSelectedRoom(r[0].id);
    });
  }, [selectedFacility]);

  useEffect(() => {
    if (selectedFacility && selectedRoom) {
      apiService.getChartGroups(Number(selectedFacility), Number(selectedRoom)).then(res => {
        const g = res.groups || [];
        setGroups(g);
        if (g.length > 0) setSelectedGroupId(g[0].group_id);
      });
      apiService.getPointRoles(Number(selectedFacility), Number(selectedRoom)).then(res => {
        const roles = res.roles || [];
        setAllRoles(roles);
        const cmap = {};
        roles.forEach((r, idx) => { cmap[r.role_id] = COLOR_PALETTE[idx % COLOR_PALETTE.length]; });
        setRoleColors(cmap);
      });
    }
  }, [selectedRoom, selectedFacility]);

  useEffect(() => {
    if (selectedGroupId) {
      const g = groups.find(x => x.group_id === Number(selectedGroupId));
      if (g?.role_ids) setCheckedRoles(g.role_ids.filter(id => id != null));
    } else setCheckedRoles([]);
  }, [selectedGroupId, groups]);

  useEffect(() => {
    if (selectedFacility && selectedRoom && checkedRoles.length > 0 && targetDate) {
      const endMs = new Date(targetDate).getTime();
      const chunkMs = CHART_SCOPING_CONFIG[mode][scale].chunkSize;
      const startMs = endMs - chunkMs;
      setIsChartLoading(true);
      apiService.getHistoricalData(
        Number(selectedFacility), Number(selectedRoom), selectedGroupId, scale,
        new Date(startMs).toISOString(), new Date(endMs).toISOString(), checkedRoles
      ).then(res => {
        setChartDataSets(res.data?.datasets || []);
        setPosts(res.data?.posts || []);
        setAlarms(res.data?.alarms || []);
        setHiddenPosts(res.data?.hidden_posts || []);
        setLoadedRangeState({ start: startMs, end: endMs });
      }).finally(() => setIsChartLoading(false));
    }
  }, [selectedFacility, selectedRoom, scale, targetDate, checkedRoles, refreshTrigger, mode]);

  const isBoolRole = (roleId) => {
    const role = allRoles.find(r => String(r.role_id) === String(roleId));
    if (!role) return false;
    return role.data_type ? role.data_type === 'BOOL' : role.role_name.toLowerCase().includes('bool');
  };

  const mainDataSets = chartDataSets.filter(ds => ds.role_name && !isBoolRole(ds.role_id));
  const subDataSets = chartDataSets.filter(ds => ds.role_name && isBoolRole(ds.role_id));
  const currentGroup = groups.find(g => g.group_id === Number(selectedGroupId));
  const groupRoleIds = currentGroup?.role_ids ? currentGroup.role_ids.filter(id => id != null) : [];

  return html`
    <div style=${{ display: 'flex', flexDirection: 'column', height: '100%', overflowY: 'auto', gap: 12, padding: 24 }}>
      <div style=${{ display: 'flex', gap: 12, minHeight: 620, flexShrink: 0 }}>
        <div style=${{ flex: 3, display: 'flex', flexDirection: 'column', gap: 10 }}>
          <div className="card" style=${{ padding: 10, display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
            <span className="label">메인 차트</span>
            <div style=${{ display: 'flex', gap: 8, alignItems: 'center' }}>
              <button onClick=${() => setShowMainInfo(!showMainInfo)} className=${showMainInfo ? 'btn btn-primary btn-sm' : 'btn btn-ghost btn-sm'}>정보 ${showMainInfo ? 'ON' : 'OFF'}</button>
              <button onClick=${() => setShowMainGrid(!showMainGrid)} className=${showMainGrid ? 'btn btn-primary btn-sm' : 'btn btn-ghost btn-sm'}>그리드 ${showMainGrid ? 'ON' : 'OFF'}</button>
              <input type="datetime-local" value=${targetDate} onChange=${e => setTargetDate(e.target.value)} className="input" style=${{ height: 32, width: 190 }} />
            </div>
          </div>
          <div className="card" style=${{ flex: 2, padding: 12 }}>
            <${MainChartViewer} chartRef=${mainChartRef} datasets=${mainDataSets} roleColors=${roleColors} showInfo=${showMainInfo} showGrid=${showMainGrid} activeGuidelines=${activeGuidelines} isLoading=${isChartLoading} posts=${posts} alarms=${alarms} onChartClick=${(t, ids) => t === 'post' && setSelectedPostViewerIds(Array.isArray(ids) ? ids : [ids])} loadedRange=${loadedRangeState} />
          </div>
          <div className="card" style=${{ flex: 1, padding: 12 }}>
            <${SubChartViewer} chartRef=${subChartRef} datasets=${subDataSets} roleColors=${roleColors} showInfo=${showSubInfo} showGrid=${showSubGrid} isLoading=${isChartLoading} posts=${posts} alarms=${alarms} invertedBools=${invertedBools} loadedRange=${loadedRangeState} />
          </div>
        </div>

        <div style=${{ flex: 1, display: 'flex', flexDirection: 'column', gap: 10 }}>
          <div className="card" style=${{ padding: 15, display: 'flex', flexDirection: 'column', gap: 10 }}>
            <h4 style=${{ fontSize: 14 }}>조회 범위 설정</h4>
            <button onClick=${() => setMode(m => m === 'DEFAULT' ? 'EXTENT' : 'DEFAULT')} className="btn btn-outline">현재 모드: ${mode}</button>
            <select value=${scale} onChange=${e => setScale(e.target.value)} className="input">
              <option value="1m">1분 단위</option><option value="5m">5분 단위</option><option value="10m">10분 단위</option><option value="15m">15분 단위</option><option value="1h">1시간 단위</option>
            </select>
            <select value=${selectedFacility} onChange=${e => setSelectedFacility(e.target.value ? Number(e.target.value) : '')} className="input">
              <option value="">-- 시설 선택 --</option>
              ${facilities.map(f => html`<option key=${f.id} value=${f.id}>${f.name}</option>`)}
            </select>
            <select value=${selectedRoom} onChange=${e => setSelectedRoom(e.target.value ? Number(e.target.value) : '')} className="input">
              <option value="">-- 호실 선택 --</option>
              ${rooms.map(r => html`<option key=${r.id} value=${r.id}>${r.name}</option>`)}
            </select>
          </div>

          <div className="card" style=${{ flex: 1, overflowY: 'auto' }}>
            <h4 style=${{ fontSize: 14, marginBottom: 8 }}>소요기록 Viewer</h4>
            ${selectedPostViewerIds.map(pid => {
              const post = posts.find(p => p.id === pid);
              if (!post) return null;
              return html`
                <div key=${pid} style=${{ borderBottom: '1px solid var(--border)', paddingBottom: 8, marginBottom: 8 }}>
                  <h5 style=${{ color: 'var(--error)' }}>${post.title}</h5>
                  <p style=${{ fontSize: 12, color: 'var(--text-secondary)' }}>${post.content}</p>
                  <button className="btn btn-danger btn-sm" onClick=${async () => { await apiService.hidePostFromGroup(Number(selectedGroupId), pid); setRefreshTrigger(x => x + 1); }}>숨기기</button>
                </div>
              `;
            })}
          </div>
        </div>
      </div>

      <div style=${{ display: 'flex', gap: 12 }}>
        <div className="card" style=${{ flex: 3, display: 'flex', gap: 15, alignItems: 'center', flexWrap: 'wrap' }}>
          <select value=${selectedGroupId} onChange=${e => setSelectedGroupId(e.target.value ? Number(e.target.value) : '')} className="input" style=${{ width: 200 }}>
            <option value="">-- 맵핑 그룹 선택 --</option>
            ${groups.map(g => html`<option key=${g.group_id} value=${g.group_id}>${g.group_name}</option>`)}
          </select>
          ${groupRoleIds.map(roleId => {
            const rInfo = allRoles.find(r => r.role_id === roleId);
            const color = roleColors[roleId] || 'var(--primary)';
            const shortLabel = (rInfo && rInfo.short_name) ? rInfo.short_name : roleId;
            const dispLabel = (rInfo && (rInfo.display_name || rInfo.role_name)) ? (rInfo.display_name || rInfo.role_name) : `Role ${roleId}`;
            return html`
              <label key=${roleId} style=${{ display: 'flex', alignItems: 'center', gap: 5, color, fontWeight: 700, fontSize: 13, cursor: 'pointer' }}>
                <input type="checkbox" checked=${checkedRoles.includes(roleId)} onChange=${() => setCheckedRoles(p => p.includes(roleId) ? p.filter(x => x !== roleId) : [...p, roleId])} />
                <span className="chip">${shortLabel}</span>${dispLabel}
              </label>
            `;
          })}
        </div>

        <div className="card" style=${{ flex: 1 }}>
          <h4 style=${{ fontSize: 14, color: 'var(--error)', marginBottom: 8 }}>소요기록 Black List</h4>
          ${hiddenPosts.map(hp => html`
            <div key=${hp.id} style=${{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: 4 }}>
              <span style=${{ fontSize: 12 }}>${hp.title}</span>
              <button className="btn btn-danger btn-sm" onClick=${async () => { await apiService.showPostInGroup(Number(selectedGroupId), hp.id); setRefreshTrigger(x => x + 1); }}>복구</button>
            </div>
          `)}
        </div>
      </div>
    </div>
  `;
};

// ===================== 최상위 App 라우터 =====================
const App = () => {
  const [user, setUser] = useState(null);
  const [page, setPage] = useState('main');

  const isAdmin = user && (user.role === 'ADMIN' || user.role === 'DEVELOPER');

  const handleLoginSuccess = (u) => {
    setUser(u);
    setPage(u.role === 'ADMIN' || u.role === 'DEVELOPER' ? 'main' : 'viewer');
  };

  return html`
    <div style=${{ display: 'flex', flexDirection: 'column', height: '100vh' }}>
      <header style=${{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', padding: '14px 24px', borderBottom: '1px solid var(--border)', background: 'var(--surface)' }}>
        <div style=${{ display: 'flex', alignItems: 'center', gap: 10 }}>
          <${Monogram} size=${32} />
          <${Wordmark} size=${17} />
        </div>
        ${user && html`
          <div style=${{ display: 'flex', alignItems: 'center', gap: 14 }}>
            <span style=${{ fontSize: 13, color: 'var(--text-secondary)' }}>${user.name} <span className="chip" style=${{ marginLeft: 6 }}>${user.role}</span>
            </span>
            <button onClick=${() => setUser(null)} className="btn btn-ghost btn-sm">로그아웃</button>
          </div>
        `}
      </header>

      ${user && html`
        <nav style=${{ display: 'flex', gap: 6, alignItems: 'center', padding: '10px 24px', borderBottom: '1px solid var(--border)', background: 'var(--surface)' }}>${isAdmin && html`
            <button onClick=${() => setPage('main')} className=${`nav-link ${page === 'main' ? 'active' : ''}`}>대시보드 / 노드 관리</button>
            <button onClick=${() => setPage('mapping')} className=${`nav-link ${page === 'mapping' ? 'active' : ''}`}>맵핑 관리자</button>
          `}
          <button onClick=${() => setPage('viewer')} className=${`nav-link ${page === 'viewer' ? 'active' : ''}`}>차트 뷰어</button>
          ${isAdmin && html`
            <button onClick=${() => setPage('indexing')} className=${`nav-link ${page === 'indexing' ? 'active' : ''}`}>명칭 인덱싱</button>
            <button onClick=${() => setPage('facility-manager')} className=${`nav-link ${page === 'facility-manager' ? 'active' : ''}`}>시설/호실 관리</button>
            <button onClick=${() => setPage('compare')} className=${`nav-link ${page === 'compare' ? 'active' : ''}`}>호실 비교</button>
          `}
        </nav>
      `}

      <div style=${{ flex: 1, display: 'flex', flexDirection: 'column', overflow: 'auto', background: 'var(--bg)' }}>
        ${!user ? html`<${LoginPage} onLogin=${handleLoginSuccess} />` : html`
          ${page === 'main' && isAdmin && html`<${MainAndNodePage} />`}
          ${page === 'mapping' && isAdmin && html`<${ChartMappingPage} />`}
          ${page === 'viewer' && html`<${ChartViewerPage} />`}
          ${page === 'indexing' && isAdmin && html`<${PRIndexingPage} />`}
          ${page === 'facility-manager' && isAdmin && html`<${FacilityManagerPage} />`}
          ${page === 'compare' && isAdmin && html`<${RoomComparePage} />`}
        `}
      </div>
    </div>
  `;
};

createRoot(document.getElementById('root')).render(html`<${App} />`);