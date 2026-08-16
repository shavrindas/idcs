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

  const [showMainInfo, setShowMainInfo] = useState<boolean>(true);
  const [showMainGrid, setShowMainGrid] = useState<boolean>(true);
  const [showSubInfo, setShowSubInfo] = useState<boolean>(false); 
  const [showSubGrid, setShowSubGrid] = useState<boolean>(true);

  const [openMenuRoleId, setOpenMenuRoleId] = useState<number | null>(null);
  const [activeGuidelines, setActiveGuidelines] = useState<number[]>([]);

  // 💡 [신규] 로딩 상태 관리
  const [isChartLoading, setIsChartLoading] = useState<boolean>(false);

  const mainChartRef = useRef<ReactECharts | null>(null);
  const subChartRef = useRef<ReactECharts | null>(null);

  useEffect(() => {
    apiService.getFacilities().then(res => setFacilities(res.facilities || []));
  }, []);

  useEffect(() => {
    if (selectedFacility) {
      apiService.getRooms(Number(selectedFacility)).then(res => setRooms(res.rooms || []));
      setSelectedRoom(''); setGroups([]); setAllRoles([]); setSelectedGroupId(''); setCheckedRoles([]); setChartDataSets([]);
      setActiveGuidelines([]); setOpenMenuRoleId(null);
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
      setActiveGuidelines([]); setOpenMenuRoleId(null);
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

  // 💡 [수정] 데이터 호출 시 경합 조건(Race Condition) 방어 로직 추가
  useEffect(() => {
    let isMounted = true; // 컴포넌트 마운트 상태 추적 플래그

    if (selectedFacility && selectedRoom && checkedRoles.length > 0 && targetDate) {
      setIsChartLoading(true); // 로딩 시작
      const endIso = new Date(targetDate).toISOString();
      
      apiService.getHistoricalData(Number(selectedFacility), Number(selectedRoom), scale, endIso, checkedRoles)
        .then(res => {
          // 응답이 도착했을 때, 컴포넌트가 살아있고 스코프가 바뀌지 않았을 때만 상태 업데이트
          if (isMounted) {
            setChartDataSets(res.data?.datasets || []);
          }
        })
        .catch(err => {
          if (isMounted) console.error("차트 호출 오류:", err);
        })
        .finally(() => {
          if (isMounted) setIsChartLoading(false); // 로딩 종료
        });
    } else {
      setChartDataSets([]);
    }

    // 의존성 배열이 바뀌어 재호출되기 직전(또는 언마운트 시) 실행되는 클린업 함수
    return () => {
      isMounted = false; // 이전 API의 결과가 나중에 도착하더라도 무시되도록 함
    };
  }, [selectedFacility, selectedRoom, scale, targetDate, checkedRoles]);

  const isBoolRole = (roleId: number) => {
    const role = allRoles.find(r => String(r.role_id) === String(roleId));
    return role ? role.role_name.toLowerCase().includes('bool') : false;
  };

  const handleModeToggle = () => {
    if (isChartLoading) return; // 로딩 중 조작 방지
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
    if (isChartLoading) return; // 로딩 중 조작 방지
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

  const syncChartDataZoom = (sourceRef: React.RefObject<ReactECharts | null>, targetRef: React.RefObject<ReactECharts | null>) => {
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

  const applyOneHourView = () => {
    const mainInst = mainChartRef.current?.getEchartsInstance();
    if (mainInst) {
      const option = mainInst.getOption() as any;
      let centerTime = new Date(targetDate).getTime();
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

  const handleQuickTimeSelect = (hours: number) => {
    if (isChartLoading) return; // 로딩 중 조작 방지
    const now = new Date();
    setTargetDate(getLocalDatetimeString(now)); 
    setTimeout(() => {
      const mainInst = mainChartRef.current?.getEchartsInstance();
      if (mainInst) {
        const end = now.getTime();
        const start = end - (hours * 60 * 60 * 1000);
        const zoomPayload = { type: 'dataZoom', startValue: start, endValue: end };
        mainInst.dispatchAction(zoomPayload);
        subChartRef.current?.getEchartsInstance().dispatchAction(zoomPayload);
      }
    }, 300); 
  };

  const handleQuickDaySelect = (targetDayOfWeek: number) => {
    if (isChartLoading) return; // 로딩 중 조작 방지
    const now = new Date();
    const currentDay = now.getDay();
    let diff = currentDay - targetDayOfWeek;
    if (diff < 0) diff += 7;
    const targetDateObj = new Date(now.getTime() - (diff * 24 * 60 * 60 * 1000));
    setTargetDate(getLocalDatetimeString(targetDateObj));
  };

  const handleColorChange = (roleId: number, color: string) => {
    setRoleColors(prev => ({ ...prev, [roleId]: color }));
  };

  const handleGuidelineToggle = (roleId: number) => {
    setActiveGuidelines(prev => 
      prev.includes(roleId) ? prev.filter(id => id !== roleId) : [...prev, roleId]
    );
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
          
          <div style={{ border: '2px solid #9c27b0', padding: 10, display: 'flex', justifyContent: 'space-between', alignItems: 'center', flexShrink: 0, backgroundColor: '#2a2a2a' }}>
            <span style={{ color: '#9c27b0', fontWeight: 'bold' }}>Top Tool Bar</span>
            <div style={{ display: 'flex', gap: 10 }}>
              <button onClick={() => setShowMainInfo(!showMainInfo)} style={{ padding: '4px 8px', backgroundColor: showMainInfo ? '#4caf50' : '#555', color: 'white', border: 'none', cursor: 'pointer' }}>
                정보 {showMainInfo ? 'ON' : 'OFF'}
              </button>
              <button onClick={() => setShowMainGrid(!showMainGrid)} style={{ padding: '4px 8px', backgroundColor: showMainGrid ? '#2196f3' : '#555', color: 'white', border: 'none', cursor: 'pointer' }}>
                그리드 {showMainGrid ? 'ON' : 'OFF'}
              </button>
              <button onClick={applyOneHourView} style={{ padding: '4px 8px', backgroundColor: '#ff9800', color: 'white', border: 'none', cursor: 'pointer' }}>
                1시간 뷰
              </button>
              <input type="datetime-local" value={targetDate} onChange={(e) => setTargetDate(e.target.value)} disabled={isChartLoading} style={{ padding: 4, backgroundColor: '#333', color: 'white', border: '1px solid #555' }} />
            </div>
          </div>
          
          <div style={{ border: '2px solid #ffffff', flex: 2, display: 'flex', flexDirection: 'column', backgroundColor: '#1e1e1e', minHeight: 0 }}>
            {/* 💡 [신규] 로딩 상태 주입 */}
            <MainChartViewer 
              echartsRef={mainChartRef}
              datasets={mainDataSets} 
              roleColors={roleColors} 
              showInfo={showMainInfo} 
              showGrid={showMainGrid} 
              activeGuidelines={activeGuidelines} 
              isLoading={isChartLoading}
            />
          </div>
          
          <div style={{ border: '2px solid #9c27b0', padding: 10, display: 'flex', justifyContent: 'space-between', alignItems: 'center', flexShrink: 0, backgroundColor: '#2a2a2a' }}>
            <span style={{ color: '#9c27b0', fontWeight: 'bold' }}>Lower Tool Bar</span>
            <div style={{ display: 'flex', gap: 10 }}>
              <button onClick={() => setShowSubInfo(!showSubInfo)} style={{ padding: '4px 8px', backgroundColor: showSubInfo ? '#4caf50' : '#555', color: 'white', border: 'none', cursor: 'pointer' }}>
                정보 {showSubInfo ? 'ON' : 'OFF'}
              </button>
              <button onClick={() => setShowSubGrid(!showSubGrid)} style={{ padding: '4px 8px', backgroundColor: showSubGrid ? '#2196f3' : '#555', color: 'white', border: 'none', cursor: 'pointer' }}>
                그리드 {showSubGrid ? 'ON' : 'OFF'}
              </button>
              <button onClick={() => syncChartDataZoom(mainChartRef, subChartRef)} style={{ padding: '4px 8px', backgroundColor: '#9c27b0', color: 'white', border: 'none', cursor: 'pointer' }}>
                시점 맞추기 (TOP 기준)
              </button>
              <button onClick={() => syncChartDataZoom(subChartRef, mainChartRef)} style={{ padding: '4px 8px', backgroundColor: '#9c27b0', color: 'white', border: 'none', cursor: 'pointer' }}>
                시점 맞추기 (BOOL 기준)
              </button>
            </div>
          </div>

          <div style={{ border: '2px solid #ffffff', flex: 1, display: 'flex', flexDirection: 'column', backgroundColor: '#1e1e1e', minHeight: 0 }}>
            {/* 💡 [신규] 로딩 상태 주입 */}
            <SubChartViewer 
              echartsRef={subChartRef}
              datasets={subDataSets} 
              roleColors={roleColors} 
              showInfo={showSubInfo}
              showGrid={showSubGrid}
              isLoading={isChartLoading}
            />
          </div>
        </div>

        {/* ================= 오른쪽: 패널 1 영역 ================= */}
        <div style={{ flex: 1, border: '2px solid #e91e63', display: 'flex', flexDirection: 'column', padding: 10, gap: 10 }}>
          <div style={{ border: '2px solid #ffffff', padding: 15, textAlign: 'center', fontWeight: 'bold' }}>
            [임시 격리] 검색창 모듈
          </div>
          
          <div style={{ border: '2px solid #ffffff', padding: 15, display: 'flex', flexDirection: 'column', gap: 10 }}>
            <h4 style={{ margin: 0, textAlign: 'center' }}>메인 조작 패널 1 (스코핑)</h4>
            
            <button onClick={handleModeToggle} disabled={isChartLoading} style={{ padding: 8, cursor: 'pointer', backgroundColor: '#555', color: '#fff', border: 'none', opacity: isChartLoading ? 0.5 : 1 }}>
              현재 모드: {mode} (토글)
            </button>
            <select value={scale} onChange={(e) => setScale(e.target.value as ChartScale)} disabled={isChartLoading} style={{ padding: 8, backgroundColor: '#333', color: '#fff', opacity: isChartLoading ? 0.5 : 1 }}>
              <option value="1m">1분 단위</option>
              <option value="5m">5분 단위</option>
              <option value="10m">10분 단위</option>
              <option value="15m">15분 단위</option>
              <option value="1h">1시간 단위</option>
            </select>
            <select value={selectedFacility} onChange={(e) => setSelectedFacility(e.target.value ? Number(e.target.value) : '')} disabled={isChartLoading} style={{ padding: 8, backgroundColor: '#333', color: '#fff', opacity: isChartLoading ? 0.5 : 1 }}>
              <option value="">-- 시설 선택 --</option>
              {facilities.map(fac => <option key={fac.id} value={fac.id}>{fac.name}</option>)}
            </select>
            <select value={selectedRoom} onChange={(e) => setSelectedRoom(e.target.value ? Number(e.target.value) : '')} disabled={!selectedFacility || isChartLoading} style={{ padding: 8, backgroundColor: '#333', color: '#fff', opacity: isChartLoading ? 0.5 : 1 }}>
              <option value="">-- 호실 선택 --</option>
              {rooms.map(room => <option key={room.id} value={room.id}>{room.name}</option>)}
            </select>

            <div style={{ border: '1px solid #555', padding: 10, marginTop: 5, backgroundColor: '#222' }}>
              <div style={{ fontSize: 12, marginBottom: 8, color: '#aaa' }}>최근 시간 이동 (현재 기준)</div>
              <div style={{ display: 'flex', gap: 5, flexWrap: 'wrap' }}>
                {[
                  { label: '1H', h: 1 }, { label: '3H', h: 3 }, { label: '6H', h: 6 }, 
                  { label: '12H', h: 12 }, { label: '1D', h: 24 }, { label: '1W', h: 24 * 7 }
                ].map(btn => (
                  <button 
                    key={btn.label} 
                    onClick={() => handleQuickTimeSelect(btn.h)} 
                    disabled={isChartLoading}
                    style={{ flex: 1, padding: '6px 0', backgroundColor: '#444', color: '#fff', border: '1px solid #666', cursor: isChartLoading ? 'not-allowed' : 'pointer', fontSize: 12, opacity: isChartLoading ? 0.5 : 1 }}
                  >
                    {btn.label}
                  </button>
                ))}
              </div>
            </div>

            <div style={{ border: '1px solid #555', padding: 10, backgroundColor: '#222' }}>
              <div style={{ fontSize: 12, marginBottom: 8, color: '#aaa' }}>최근 요일 이동</div>
              <div style={{ display: 'flex', gap: 5 }}>
                {['일', '월', '화', '수', '목', '금', '토'].map((dayStr, idx) => (
                  <button 
                    key={dayStr} 
                    onClick={() => handleQuickDaySelect(idx)} 
                    disabled={isChartLoading}
                    style={{ flex: 1, padding: '6px 0', backgroundColor: '#444', color: '#fff', border: '1px solid #666', cursor: isChartLoading ? 'not-allowed' : 'pointer', fontSize: 12, opacity: isChartLoading ? 0.5 : 1 }}
                  >
                    {dayStr}
                  </button>
                ))}
              </div>
            </div>

          </div>
          
          <div style={{ border: '2px solid #ffffff', flex: 1, display: 'flex', alignItems: 'center', justifyContent: 'center', textAlign: 'center', fontWeight: 'bold' }}>
            소요기록 viewer
          </div>
        </div>
      </div>

      {/* ================= 하단: 메인 조작 패널 2 ================= */}
      <div style={{ border: '2px solid #4caf50', padding: 15, display: 'flex', flexDirection: 'column', gap: 10 }}>
        <h4 style={{ margin: 0, textAlign: 'center', color: '#4caf50' }}>메인 조작 패널 2 (맵핑 그룹 활성화)</h4>
        
        <div style={{ display: 'flex', gap: 15, alignItems: 'center', justifyContent: 'center' }}>
          <select 
            value={selectedGroupId} 
            onChange={(e) => setSelectedGroupId(e.target.value ? Number(e.target.value) : '')} 
            disabled={!selectedRoom || groups.length === 0 || isChartLoading}
            style={{ padding: 8, minWidth: 200, backgroundColor: '#333', color: 'white', opacity: isChartLoading ? 0.5 : 1 }}
          >
            <option value="">-- 맵핑 그룹 선택 --</option>
            {groups.map(g => <option key={g.group_id} value={g.group_id}>{g.group_name}</option>)}
          </select>
          
          <div style={{ display: 'flex', flexWrap: 'wrap', gap: 15 }}>
            {selectedGroupId && groupRoleIds.map(roleId => {
              const roleInfo = allRoles.find(r => r.role_id === roleId);
              const roleName = roleInfo ? roleInfo.role_name : `Role ${roleId}`;
              const color = roleColors[roleId] || '#ffffff';
              const isBool = isBoolRole(roleId);
              
              return (
                <div key={roleId} style={{ position: 'relative', display: 'flex', alignItems: 'center' }}>
                  <label style={{ display: 'flex', alignItems: 'center', cursor: isChartLoading ? 'not-allowed' : 'pointer', color: color, fontWeight: 'bold', opacity: isChartLoading ? 0.5 : 1 }}>
                    <input 
                      type="checkbox" 
                      checked={checkedRoles.includes(roleId)} 
                      onChange={() => handleRoleToggle(roleId)}
                      disabled={isChartLoading}
                      style={{ marginRight: 5, accentColor: color }}
                    /> 
                    <span style={{ display: 'inline-block', width: 12, height: 12, backgroundColor: color, marginRight: 5, borderRadius: 2 }}></span>
                    {roleName}
                  </label>
                  
                  <span 
                    onClick={() => setOpenMenuRoleId(openMenuRoleId === roleId ? null : roleId)}
                    style={{ marginLeft: 5, cursor: 'pointer', fontSize: 16 }}
                  >
                    ⚙️
                  </span>

                  {openMenuRoleId === roleId && (
                    <div style={{ 
                      position: 'absolute', 
                      bottom: 'calc(100% + 8px)', 
                      left: 0, 
                      zIndex: 1000, 
                      backgroundColor: '#2a2a2a', 
                      border: '1px solid #555', 
                      padding: 10, 
                      borderRadius: 4, 
                      minWidth: 160,
                      boxShadow: '0 4px 12px rgba(0,0,0,0.5)'
                    }}>
                      <div style={{ marginBottom: 10, display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
                        <span style={{ fontSize: 12, color: '#ccc' }}>색상 변경:</span>
                        <input 
                          type="color" 
                          value={color} 
                          onChange={(e) => handleColorChange(roleId, e.target.value)} 
                          style={{ cursor: 'pointer', border: 'none', background: 'transparent', width: 30, height: 25 }}
                        />
                      </div>
                      
                      {!isBool && (
                        <div style={{ display: 'flex', alignItems: 'center' }}>
                          <label style={{ fontSize: 12, color: '#ccc', cursor: 'pointer' }}>
                            <input 
                              type="checkbox" 
                              checked={activeGuidelines.includes(roleId)} 
                              onChange={() => handleGuidelineToggle(roleId)}
                              style={{ marginRight: 5 }}
                            /> 
                            가이드라인 표시
                          </label>
                        </div>
                      )}
                    </div>
                  )}
                </div>
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