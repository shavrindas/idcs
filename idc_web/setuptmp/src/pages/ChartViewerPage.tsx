// src/pages/ChartViewerPage.tsx
import React, { useState, useEffect, useRef } from 'react';
import ReactECharts from 'echarts-for-react';
import { MainChartViewer, SubChartViewer } from '../components/chart/EChartsViewer';
import type { ChartMode, ChartScale } from '../constants/chartConfig';
import { apiService } from '../services/apiService';
import type { Role, ChartGroup } from '../types';

const getLocalDatetimeString = (date: Date) => {
  const offset = date.getTimezoneOffset() * 60000;
  return (new Date(date.getTime() - offset)).toISOString().slice(0, 16);
};

const COLOR_PALETTE = [
  '#5470c6', '#91cc75', '#fac858', '#ee6666', '#73c0de', 
  '#3ba272', '#fc8452', '#9a60b4', '#ea7ccc', '#ff9f7f'
];

export const ChartViewerPage: React.FC = () => {
  const [mode, setMode] = useState<ChartMode>('DEFAULT');
  const [scale, setScale] = useState<ChartScale>('1m');
  const [targetDate, setTargetDate] = useState<string>(getLocalDatetimeString(new Date()));
  
  const [facilities, setFacilities] = useState<any[]>([]);
  const [rooms, setRooms] = useState<any[]>([]);
  const [groups, setGroups] = useState<ChartGroup[]>([]);
  const [allRoles, setAllRoles] = useState<Role[]>([]);

  const [selectedFacility, setSelectedFacility] = useState<number | ''>('');
  const [selectedRoom, setSelectedRoom] = useState<number | ''>('');
  const [selectedGroupId, setSelectedGroupId] = useState<number | ''>('');
  const [checkedRoles, setCheckedRoles] = useState<number[]>([]);
  
  const [chartDataSets, setChartDataSets] = useState<any[]>([]);
  const [roleColors, setRoleColors] = useState<Record<number, string>>({});

  // [RQ-Top & RQ-Lower] 툴바 상태 관리 추가
  const [showMainInfo, setShowMainInfo] = useState<boolean>(true);
  const [showMainGrid, setShowMainGrid] = useState<boolean>(true);
  const [showSubInfo, setShowSubInfo] = useState<boolean>(false); // 툴팁 가림 현상 방지를 위해 Sub는 기본 Off
  const [showSubGrid, setShowSubGrid] = useState<boolean>(true);

  // [RQ-Lower] 차트 강제 동기화를 위한 ECharts 인스턴스 참조
  const mainChartRef = useRef<ReactECharts>(null);
  const subChartRef = useRef<ReactECharts>(null);

  useEffect(() => {
    apiService.getFacilities().then(res => setFacilities(res.facilities || []));
  }, []);

  useEffect(() => {
    if (selectedFacility) {
      apiService.getRooms(Number(selectedFacility)).then(res => setRooms(res.rooms || []));
      setSelectedRoom(''); setGroups([]); setAllRoles([]); setSelectedGroupId(''); setCheckedRoles([]); setChartDataSets([]);
    }
  }, [selectedFacility]);

  useEffect(() => {
    if (selectedFacility && selectedRoom) {
      apiService.getChartGroups(Number(selectedFacility), Number(selectedRoom))
        .then(res => setGroups(res.groups || [])); 
      apiService.getPointRoles(Number(selectedFacility), Number(selectedRoom))
        .then(res => {
          const roles = res.roles || [];
          setAllRoles(roles);
          const newColorMap: Record<number, string> = {};
          roles.forEach((r: Role, idx: number) => {
            newColorMap[r.role_id] = COLOR_PALETTE[idx % COLOR_PALETTE.length];
          });
          setRoleColors(newColorMap);
        });
      setSelectedGroupId(''); setCheckedRoles([]); setChartDataSets([]);
    }
  }, [selectedRoom, selectedFacility]);

  useEffect(() => {
    if (selectedGroupId) {
      const group = groups.find(g => g.group_id === Number(selectedGroupId));
      if (group && group.role_ids) {
        setCheckedRoles(group.role_ids.filter(id => id !== null));
      }
    } else {
      setCheckedRoles([]); setChartDataSets([]);
    }
  }, [selectedGroupId, groups]);

  useEffect(() => {
    if (selectedFacility && selectedRoom && checkedRoles.length > 0 && targetDate) {
      const endIso = new Date(targetDate).toISOString();
      apiService.getHistoricalData(Number(selectedFacility), Number(selectedRoom), scale, endIso, checkedRoles)
        .then(res => setChartDataSets(res.data?.datasets || []))
        .catch(err => console.error("차트 호출 오류:", err));
    } else {
      setChartDataSets([]);
    }
  }, [selectedFacility, selectedRoom, scale, targetDate, checkedRoles]);

  const isBoolRole = (roleId: number) => {
    const role = allRoles.find(r => String(r.role_id) === String(roleId));
    return role ? role.role_name.toLowerCase().includes('bool') : false;
  };

  const handleModeToggle = () => {
    setMode(prev => {
      const nextMode = prev === 'DEFAULT' ? 'EXTENT' : 'DEFAULT';
      if (nextMode === 'EXTENT') {
        const boolRoles = checkedRoles.filter(id => isBoolRole(id));
        const mainRoles = checkedRoles.filter(id => !isBoolRole(id));
        if (mainRoles.length > 1) setCheckedRoles([...boolRoles, mainRoles[0]]);
      }
      return nextMode;
    });
  };

  const handleRoleToggle = (roleId: number) => {
    const isBool = isBoolRole(roleId);
    setCheckedRoles(prev => {
      const isCurrentlyChecked = prev.includes(roleId);
      if (isCurrentlyChecked) return prev.filter(id => id !== roleId);
      else {
        if (mode === 'EXTENT' && !isBool) {
          const boolRoles = prev.filter(id => isBoolRole(id));
          return [...boolRoles, roleId];
        } else return [...prev, roleId];
      }
    });
  };

  // ==========================================
  // 차트 강제 동기화 (Zoom/Pan 일치) 로직
  // ==========================================

  const syncChartDataZoom = (
    sourceRef: React.RefObject<ReactECharts | null>, 
    targetRef: React.RefObject<ReactECharts | null>
  ) => {
    const srcInst = sourceRef.current?.getEchartsInstance();
    const tgtInst = targetRef.current?.getEchartsInstance();
    
    if (srcInst && tgtInst) {
      const option = srcInst.getOption() as any;
      if (option.dataZoom && option.dataZoom.length > 0) {
        const startVal = option.dataZoom[0].startValue;
        const endVal = option.dataZoom[0].endValue;
        tgtInst.dispatchAction({ type: 'dataZoom', startValue: startVal, endValue: endVal });
      }
    }
  };
  
  // [RQ-Top.2] 1시간 단위 강제 포커싱 뷰어
  const applyOneHourView = () => {
    const mainInst = mainChartRef.current?.getEchartsInstance();
    if (mainInst) {
      const option = mainInst.getOption() as any;
      let centerTime = new Date(targetDate).getTime();
      
      // 차트가 현재 줌 되어있다면 화면 중앙을 기준으로 1시간을 잡음
      if (option.dataZoom && option.dataZoom.length > 0 && option.dataZoom[0].startValue) {
        const sv = option.dataZoom[0].startValue;
        const ev = option.dataZoom[0].endValue;
        centerTime = (sv + ev) / 2;
      }
      
      const halfHourMs = 30 * 60 * 1000;
      const zoomPayload = { type: 'dataZoom', startValue: centerTime - halfHourMs, endValue: centerTime + halfHourMs };
      
      mainInst.dispatchAction(zoomPayload);
      subChartRef.current?.getEchartsInstance().dispatchAction(zoomPayload);
    }
  };

  const currentGroup = groups.find(g => g.group_id === Number(selectedGroupId));
  const groupRoleIds = currentGroup && currentGroup.role_ids ? currentGroup.role_ids.filter(id => id !== null) : [];

  const mainDataSets = chartDataSets.filter(ds => ds.role_name && !ds.role_name.toLowerCase().includes('bool'));
  const subDataSets = chartDataSets.filter(ds => ds.role_name && ds.role_name.toLowerCase().includes('bool'));

  return (
    <div style={{ display: 'flex', flexDirection: 'column', height: '100%', gap: 10, boxSizing: 'border-box' }}>
      <div style={{ display: 'flex', flex: 1, gap: 10, minHeight: 0 }}>
        
        {/* ================= 왼쪽: 차트 영역 ================= */}
        <div style={{ flex: 3, border: '2px solid #2196f3', display: 'flex', flexDirection: 'column', padding: 10, gap: 10, minHeight: 0 }}>
          
          {/* Top Tool Bar */}
          <div style={{ border: '2px solid #9c27b0', padding: 10, display: 'flex', justifyContent: 'space-between', alignItems: 'center', flexShrink: 0, backgroundColor: '#2a2a2a' }}>
            <span style={{ color: '#9c27b0', fontWeight: 'bold' }}>Top Tool Bar</span>
            <div style={{ display: 'flex', gap: 10 }}>
              {/* [RQ-Top.1] 메인 차트 정보 툴팁 토글 */}
              <button onClick={() => setShowMainInfo(!showMainInfo)} style={{ padding: '4px 8px', backgroundColor: showMainInfo ? '#4caf50' : '#555', color: 'white', border: 'none', cursor: 'pointer' }}>
                정보 {showMainInfo ? 'ON' : 'OFF'}
              </button>
              {/* [RQ-Top.3] 메인 차트 그리드 토글 */}
              <button onClick={() => setShowMainGrid(!showMainGrid)} style={{ padding: '4px 8px', backgroundColor: showMainGrid ? '#2196f3' : '#555', color: 'white', border: 'none', cursor: 'pointer' }}>
                그리드 {showMainGrid ? 'ON' : 'OFF'}
              </button>
              {/* [RQ-Top.2] 공용 시간 출력 (1시간 뷰포트) */}
              <button onClick={applyOneHourView} style={{ padding: '4px 8px', backgroundColor: '#ff9800', color: 'white', border: 'none', cursor: 'pointer' }}>
                1시간 뷰
              </button>
              {/* [RQ-Top.4] 날짜(시간) 설정 */}
              <input type="datetime-local" value={targetDate} onChange={(e) => setTargetDate(e.target.value)} style={{ padding: 4, backgroundColor: '#333', color: 'white', border: '1px solid #555' }} />
            </div>
          </div>
          
          {/* Main Chart Viewer */}
          <div style={{ border: '2px solid #ffffff', flex: 2, display: 'flex', flexDirection: 'column', backgroundColor: '#1e1e1e', minHeight: 0 }}>
            <MainChartViewer 
              echartsRef={mainChartRef}
              datasets={mainDataSets} 
              roleColors={roleColors} 
              showInfo={showMainInfo} 
              showGrid={showMainGrid} 
            />
          </div>
          
          {/* Lower Tool Bar */}
          <div style={{ border: '2px solid #9c27b0', padding: 10, display: 'flex', justifyContent: 'space-between', alignItems: 'center', flexShrink: 0, backgroundColor: '#2a2a2a' }}>
            <span style={{ color: '#9c27b0', fontWeight: 'bold' }}>Lower Tool Bar</span>
            <div style={{ display: 'flex', gap: 10 }}>
              {/* [RQ-Lower.1] 서브 차트 정보 툴팁 토글 */}
              <button onClick={() => setShowSubInfo(!showSubInfo)} style={{ padding: '4px 8px', backgroundColor: showSubInfo ? '#4caf50' : '#555', color: 'white', border: 'none', cursor: 'pointer' }}>
                정보 {showSubInfo ? 'ON' : 'OFF'}
              </button>
              {/* [RQ-Lower.4] 서브 차트 그리드 토글 */}
              <button onClick={() => setShowSubGrid(!showSubGrid)} style={{ padding: '4px 8px', backgroundColor: showSubGrid ? '#2196f3' : '#555', color: 'white', border: 'none', cursor: 'pointer' }}>
                그리드 {showSubGrid ? 'ON' : 'OFF'}
              </button>
              {/* [RQ-Lower.2] 서브 차트를 메인 차트 기준 시점으로 동기화 */}
              <button onClick={() => syncChartDataZoom(mainChartRef, subChartRef)} style={{ padding: '4px 8px', backgroundColor: '#9c27b0', color: 'white', border: 'none', cursor: 'pointer' }}>
                시점 맞추기 (TOP 기준)
              </button>
              {/* [RQ-Lower.3] 메인 차트를 서브 차트 기준 시점으로 동기화 */}
              <button onClick={() => syncChartDataZoom(subChartRef, mainChartRef)} style={{ padding: '4px 8px', backgroundColor: '#9c27b0', color: 'white', border: 'none', cursor: 'pointer' }}>
                시점 맞추기 (BOOL 기준)
              </button>
            </div>
          </div>

          {/* Sub Chart Viewer */}
          <div style={{ border: '2px solid #ffffff', flex: 1, display: 'flex', flexDirection: 'column', backgroundColor: '#1e1e1e', minHeight: 0 }}>
            <SubChartViewer 
              echartsRef={subChartRef}
              datasets={subDataSets} 
              roleColors={roleColors} 
              showInfo={showSubInfo}
              showGrid={showSubGrid}
            />
          </div>
        </div>

        {/* ================= 오른쪽: 패널 1 영역 (유지) ================= */}
        <div style={{ flex: 1, border: '2px solid #e91e63', display: 'flex', flexDirection: 'column', padding: 10, gap: 10 }}>
          <div style={{ border: '2px solid #ffffff', padding: 15, textAlign: 'center', fontWeight: 'bold' }}>
            [임시 격리] 검색창 모듈
          </div>
          
          <div style={{ border: '2px solid #ffffff', padding: 15, display: 'flex', flexDirection: 'column', gap: 10 }}>
            <h4 style={{ margin: 0, textAlign: 'center' }}>메인 조작 패널 1 (스코핑)</h4>
            <button onClick={handleModeToggle} style={{ padding: 8, cursor: 'pointer' }}>
              현재 모드: {mode} (토글)
            </button>
            <select value={scale} onChange={(e) => setScale(e.target.value as ChartScale)} style={{ padding: 8 }}>
              <option value="1m">1분 단위</option>
              <option value="5m">5분 단위</option>
              <option value="10m">10분 단위</option>
              <option value="15m">15분 단위</option>
              <option value="1h">1시간 단위</option>
            </select>
            <select value={selectedFacility} onChange={(e) => setSelectedFacility(e.target.value ? Number(e.target.value) : '')} style={{ padding: 8 }}>
              <option value="">-- 시설 선택 --</option>
              {facilities.map(fac => <option key={fac.id} value={fac.id}>{fac.name}</option>)}
            </select>
            <select value={selectedRoom} onChange={(e) => setSelectedRoom(e.target.value ? Number(e.target.value) : '')} disabled={!selectedFacility} style={{ padding: 8 }}>
              <option value="">-- 호실 선택 --</option>
              {rooms.map(room => <option key={room.id} value={room.id}>{room.name}</option>)}
            </select>
          </div>
          
          <div style={{ border: '2px solid #ffffff', flex: 1, display: 'flex', alignItems: 'center', justifyContent: 'center', textAlign: 'center', fontWeight: 'bold' }}>
            소요기록 viewer
          </div>
        </div>
      </div>

      {/* ================= 하단: 메인 조작 패널 2 (유지) ================= */}
      <div style={{ border: '2px solid #4caf50', padding: 15, display: 'flex', flexDirection: 'column', gap: 10 }}>
        <h4 style={{ margin: 0, textAlign: 'center', color: '#4caf50' }}>메인 조작 패널 2 (맵핑 그룹 활성화)</h4>
        
        <div style={{ display: 'flex', gap: 15, alignItems: 'center', justifyContent: 'center' }}>
          <select 
            value={selectedGroupId} 
            onChange={(e) => setSelectedGroupId(e.target.value ? Number(e.target.value) : '')} 
            disabled={!selectedRoom || groups.length === 0}
            style={{ padding: 8, minWidth: 200, backgroundColor: '#333', color: 'white' }}
          >
            <option value="">-- 맵핑 그룹 선택 --</option>
            {groups.map(g => <option key={g.group_id} value={g.group_id}>{g.group_name}</option>)}
          </select>
          
          <div style={{ display: 'flex', flexWrap: 'wrap', gap: 15 }}>
            {selectedGroupId && groupRoleIds.map(roleId => {
              const roleInfo = allRoles.find(r => r.role_id === roleId);
              const roleName = roleInfo ? roleInfo.role_name : `Role ${roleId}`;
              const color = roleColors[roleId] || '#ffffff';
              
              return (
                <label key={roleId} style={{ display: 'flex', alignItems: 'center', cursor: 'pointer', color: color, fontWeight: 'bold' }}>
                  <input 
                    type="checkbox" 
                    checked={checkedRoles.includes(roleId)} 
                    onChange={() => handleRoleToggle(roleId)}
                    style={{ marginRight: 5, accentColor: color }}
                  /> 
                  <span style={{ display: 'inline-block', width: 12, height: 12, backgroundColor: color, marginRight: 5, borderRadius: 2 }}></span>
                  {roleName}
                </label>
              );
            })}
            {selectedGroupId && groupRoleIds.length === 0 && (
              <span style={{ color: '#aaa' }}>그룹에 포함된 포인트 롤이 없습니다.</span>
            )}
          </div>
        </div>
      </div>
    </div>
  );
};