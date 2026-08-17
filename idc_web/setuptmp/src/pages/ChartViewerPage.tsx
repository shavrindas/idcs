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
  const [refreshTrigger, setRefreshTrigger] = useState<number>(0); 
  
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
  const [isChartLoading, setIsChartLoading] = useState<boolean>(false); 

  const [posts, setPosts] = useState<any[]>([]);
  const [alarms, setAlarms] = useState<any[]>([]);
  const [hiddenPosts, setHiddenPosts] = useState<any[]>([]);
  
  // 💡 [수정] 여러 개의 포스트를 띄우기 위해 배열로 상태 변경
  const [selectedPostViewerIds, setSelectedPostViewerIds] = useState<number[]>([]);

  const mainChartRef = useRef<ReactECharts | null>(null);
  const subChartRef = useRef<ReactECharts | null>(null); 

  useEffect(() => {
    apiService.getFacilities().then(res => setFacilities(res.facilities || []));
  }, []); 

  useEffect(() => {
    if (selectedFacility) {
      apiService.getRooms(Number(selectedFacility)).then(res => setRooms(res.rooms || []));
      setSelectedRoom(''); setGroups([]); setAllRoles([]); setSelectedGroupId(''); setCheckedRoles([]); 
      setChartDataSets([]); setPosts([]); setHiddenPosts([]); setAlarms([]); setSelectedPostViewerIds([]);
    }
  }, [selectedFacility]); 

  useEffect(() => {
    if (selectedFacility && selectedRoom) {
      apiService.getChartGroups(Number(selectedFacility), Number(selectedRoom)).then(res => setGroups(res.groups || [])); 
      apiService.getPointRoles(Number(selectedFacility), Number(selectedRoom)).then(res => {
        const roles = res.roles || [];
        setAllRoles(roles);
        const newColorMap: Record<number, string> = {};
        roles.forEach((r: Role, idx: number) => { newColorMap[r.role_id] = COLOR_PALETTE[idx % COLOR_PALETTE.length]; });
        setRoleColors(newColorMap);
      });
      setSelectedGroupId(''); setCheckedRoles([]); setChartDataSets([]); setPosts([]); setHiddenPosts([]); setAlarms([]); setSelectedPostViewerIds([]);
    }
  }, [selectedRoom, selectedFacility]); 

  useEffect(() => {
    if (selectedGroupId) {
      const group = groups.find(g => g.group_id === Number(selectedGroupId));
      if (group && group.role_ids) setCheckedRoles(group.role_ids.filter(id => id !== null));
    } else {
      setCheckedRoles([]); setChartDataSets([]); setPosts([]); setHiddenPosts([]); setAlarms([]); setSelectedPostViewerIds([]);
    }
  }, [selectedGroupId, groups]); 

  useEffect(() => {
    let isMounted = true; 

    if (selectedFacility && selectedRoom && checkedRoles.length > 0 && targetDate) {
      setIsChartLoading(true); 
      const endIso = new Date(targetDate).toISOString();
      
      apiService.getHistoricalData(Number(selectedFacility), Number(selectedRoom), selectedGroupId, scale, endIso, checkedRoles)
        .then(res => {
          if (isMounted) {
            setChartDataSets(res.data?.datasets || []);
            setAlarms(res.data?.alarms || []);
            setPosts(res.data?.posts || []);
            setHiddenPosts(res.data?.hidden_posts || []);
          }
        })
        .catch(err => { if (isMounted) console.error("차트 호출 오류:", err); })
        .finally(() => { if (isMounted) setIsChartLoading(false); });
    } else {
      setChartDataSets([]); setPosts([]); setHiddenPosts([]); setAlarms([]);
    }
    return () => { isMounted = false; };
  }, [selectedFacility, selectedRoom, scale, targetDate, checkedRoles, refreshTrigger]); 

  const isBoolRole = (roleId: number) => {
    const role = allRoles.find(r => String(r.role_id) === String(roleId));
    return role ? role.role_name.toLowerCase().includes('bool') : false;
  }; 

  const handleModeToggle = () => {
    if (isChartLoading) return; 
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
    if (isChartLoading) return; 
    const isBool = isBoolRole(roleId);
    setCheckedRoles(prev => {
      if (prev.includes(roleId)) return prev.filter(id => id !== roleId);
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
        tgtInst.dispatchAction({ type: 'dataZoom', startValue: option.dataZoom[0].startValue, endValue: option.dataZoom[0].endValue });
      }
    }
  }; 

  const applyOneHourView = () => {
    const mainInst = mainChartRef.current?.getEchartsInstance();
    if (mainInst) {
      const option = mainInst.getOption() as any;
      let centerTime = new Date(targetDate).getTime();
      if (option.dataZoom && option.dataZoom.length > 0 && option.dataZoom[0].startValue) {
        centerTime = (option.dataZoom[0].startValue + option.dataZoom[0].endValue) / 2;
      }
      const halfHourMs = 30 * 60 * 1000;
      const zoomPayload = { type: 'dataZoom', startValue: centerTime - halfHourMs, endValue: centerTime + halfHourMs };
      mainInst.dispatchAction(zoomPayload);
      subChartRef.current?.getEchartsInstance().dispatchAction(zoomPayload);
    }
  }; 

  const handleQuickTimeSelect = (hours: number) => {
    if (isChartLoading) return; 
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
    if (isChartLoading) return; 
    const now = new Date();
    const currentDay = now.getDay();
    let diff = currentDay - targetDayOfWeek;
    if (diff < 0) diff += 7;
    const targetDateObj = new Date(now.getTime() - (diff * 24 * 60 * 60 * 1000));
    setTargetDate(getLocalDatetimeString(targetDateObj));
  }; 

  const handleColorChange = (roleId: number, color: string) => setRoleColors(prev => ({ ...prev, [roleId]: color }));
  const handleGuidelineToggle = (roleId: number) => setActiveGuidelines(prev => prev.includes(roleId) ? prev.filter(id => id !== roleId) : [...prev, roleId]);

  // 💡 [수정] 여러 포스트가 병합된 구역을 클릭 시 배열을 수용
  const handleChartClick = (type: 'post' | 'alarm', ids: number | number[]) => {
    if (type === 'post') {
      setSelectedPostViewerIds(Array.isArray(ids) ? ids : [ids]);
    }
  };

  const handleHidePost = async (postId: number) => {
    if (!selectedGroupId) return;
    try {
      await apiService.hidePostFromGroup(Number(selectedGroupId), postId);
      setSelectedPostViewerIds(prev => prev.filter(id => id !== postId)); // 뷰어 목록에서도 제거
      setRefreshTrigger(prev => prev + 1); 
    } catch (e) { console.error(e); }
  };

  const handleRestorePost = async (postId: number) => {
    if (!selectedGroupId) return;
    try {
      await apiService.showPostInGroup(Number(selectedGroupId), postId);
      setRefreshTrigger(prev => prev + 1); 
    } catch (e) { console.error(e); }
  };

  const currentGroup = groups.find(g => g.group_id === Number(selectedGroupId));
  const groupRoleIds = currentGroup && currentGroup.role_ids ? currentGroup.role_ids.filter(id => id !== null) : [];

  const mainDataSets = chartDataSets.filter(ds => ds.role_name && !isBoolRole(ds.role_id));
  const subDataSets = chartDataSets.filter(ds => ds.role_name && isBoolRole(ds.role_id)); 

  return (
    <div style={{ display: 'flex', flexDirection: 'column', height: '100%', gap: 10, boxSizing: 'border-box' }}>
      <div style={{ display: 'flex', flex: 1, gap: 10, minHeight: 0 }}>
        
        {/* ================= 왼쪽: 차트 영역 ================= */}
        <div style={{ flex: 3, border: '2px solid #2196f3', display: 'flex', flexDirection: 'column', padding: 10, gap: 10, minHeight: 0 }}>
          
          <div style={{ border: '2px solid #9c27b0', padding: 10, display: 'flex', justifyContent: 'space-between', alignItems: 'center', flexShrink: 0, backgroundColor: '#2a2a2a' }}>
            <span style={{ color: '#9c27b0', fontWeight: 'bold' }}>Top Tool Bar</span>
            <div style={{ display: 'flex', gap: 10 }}>
              <button onClick={() => setShowMainInfo(!showMainInfo)} style={{ padding: '4px 8px', backgroundColor: showMainInfo ? '#4caf50' : '#555', color: 'white', border: 'none', cursor: 'pointer' }}>정보 {showMainInfo ? 'ON' : 'OFF'}</button>
              <button onClick={() => setShowMainGrid(!showMainGrid)} style={{ padding: '4px 8px', backgroundColor: showMainGrid ? '#2196f3' : '#555', color: 'white', border: 'none', cursor: 'pointer' }}>그리드 {showMainGrid ? 'ON' : 'OFF'}</button>
              <button onClick={applyOneHourView} style={{ padding: '4px 8px', backgroundColor: '#ff9800', color: 'white', border: 'none', cursor: 'pointer' }}>1시간 뷰</button>
              <input type="datetime-local" value={targetDate} onChange={(e) => setTargetDate(e.target.value)} disabled={isChartLoading} style={{ padding: 4, backgroundColor: '#333', color: 'white', border: '1px solid #555' }} />
            </div>
          </div>
          
          <div style={{ border: '2px solid #ffffff', flex: 2, display: 'flex', flexDirection: 'column', backgroundColor: '#1e1e1e', minHeight: 0, position: 'relative' }}>
            {/* 🚨 기존 플로팅 뱃지 UI 삭제됨 */}
            <MainChartViewer 
              echartsRef={mainChartRef} datasets={mainDataSets} roleColors={roleColors} 
              showInfo={showMainInfo} showGrid={showMainGrid} activeGuidelines={activeGuidelines} isLoading={isChartLoading}
              posts={posts} alarms={alarms} onChartClick={handleChartClick} 
            />
          </div>
          
          <div style={{ border: '2px solid #9c27b0', padding: 10, display: 'flex', justifyContent: 'space-between', alignItems: 'center', flexShrink: 0, backgroundColor: '#2a2a2a' }}>
            <span style={{ color: '#9c27b0', fontWeight: 'bold' }}>Lower Tool Bar</span>
            <div style={{ display: 'flex', gap: 10 }}>
              <button onClick={() => setShowSubInfo(!showSubInfo)} style={{ padding: '4px 8px', backgroundColor: showSubInfo ? '#4caf50' : '#555', color: 'white', border: 'none', cursor: 'pointer' }}>정보 {showSubInfo ? 'ON' : 'OFF'}</button>
              <button onClick={() => setShowSubGrid(!showSubGrid)} style={{ padding: '4px 8px', backgroundColor: showSubGrid ? '#2196f3' : '#555', color: 'white', border: 'none', cursor: 'pointer' }}>그리드 {showSubGrid ? 'ON' : 'OFF'}</button>
              <button onClick={() => syncChartDataZoom(mainChartRef, subChartRef)} style={{ padding: '4px 8px', backgroundColor: '#9c27b0', color: 'white', border: 'none', cursor: 'pointer' }}>시점 맞추기 (TOP 기준)</button>
              <button onClick={() => syncChartDataZoom(subChartRef, mainChartRef)} style={{ padding: '4px 8px', backgroundColor: '#9c27b0', color: 'white', border: 'none', cursor: 'pointer' }}>시점 맞추기 (BOOL 기준)</button>
            </div>
          </div>

          <div style={{ border: '2px solid #ffffff', flex: 1, display: 'flex', flexDirection: 'column', backgroundColor: '#1e1e1e', minHeight: 0 }}>
            <SubChartViewer 
              echartsRef={subChartRef} datasets={subDataSets} roleColors={roleColors} 
              showInfo={showSubInfo} showGrid={showSubGrid} isLoading={isChartLoading}
              posts={posts} alarms={alarms} 
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
                {[{ label: '1H', h: 1 }, { label: '3H', h: 3 }, { label: '6H', h: 6 }, { label: '12H', h: 12 }, { label: '1D', h: 24 }, { label: '1W', h: 24 * 7 }].map(btn => (
                  <button key={btn.label} onClick={() => handleQuickTimeSelect(btn.h)} disabled={isChartLoading} style={{ flex: 1, padding: '6px 0', backgroundColor: '#444', color: '#fff', border: '1px solid #666', cursor: isChartLoading ? 'not-allowed' : 'pointer', fontSize: 12, opacity: isChartLoading ? 0.5 : 1 }}>
                    {btn.label}
                  </button>
                ))}
              </div>
            </div>

            <div style={{ border: '1px solid #555', padding: 10, backgroundColor: '#222' }}>
              <div style={{ fontSize: 12, marginBottom: 8, color: '#aaa' }}>최근 요일 이동</div>
              <div style={{ display: 'flex', gap: 5 }}>
                {['일', '월', '화', '수', '목', '금', '토'].map((dayStr, idx) => (
                  <button key={dayStr} onClick={() => handleQuickDaySelect(idx)} disabled={isChartLoading} style={{ flex: 1, padding: '6px 0', backgroundColor: '#444', color: '#fff', border: '1px solid #666', cursor: isChartLoading ? 'not-allowed' : 'pointer', fontSize: 12, opacity: isChartLoading ? 0.5 : 1 }}>
                    {dayStr}
                  </button>
                ))}
              </div>
            </div>
          </div>
          
          <div style={{ border: '2px solid #ffffff', flex: 1, display: 'flex', flexDirection: 'column', padding: 10, backgroundColor: '#1e1e1e', overflowY: 'auto' }}>
            <h4 style={{ margin: '0 0 10px 0', textAlign: 'center' }}>소요기록 Viewer</h4>
            
            {/* 💡 [수정] 여러 포스트를 동시에 렌더링하기 위한 맵핑 로직 적용 */}
            {selectedPostViewerIds.length > 0 ? (
              <div style={{ display: 'flex', flexDirection: 'column', gap: 15 }}>
                {selectedPostViewerIds.map(postId => {
                  const post = posts.find(p => p.id === postId);
                  if (!post) return null;
                  return (
                    <div key={postId} style={{ color: '#fff', display: 'flex', flexDirection: 'column', borderBottom: '1px solid #444', paddingBottom: 10 }}>
                      <h5 style={{ color: '#ff4d4f', margin: '0 0 5px 0' }}>{post.title}</h5>
                      <p style={{ fontSize: 12, color: '#aaa', margin: '0 0 10px 0' }}>{post.content}</p>
                      <button 
                        onClick={() => handleHidePost(postId)}
                        disabled={!selectedGroupId}
                        style={{ alignSelf: 'flex-end', padding: '4px 8px', backgroundColor: '#ff4d4f', color: '#fff', border: 'none', cursor: 'pointer', borderRadius: 4, fontSize: 11 }}
                      >
                        이 그룹에서 숨기기
                      </button>
                    </div>
                  );
                })}
              </div>
            ) : (
              <div style={{ flex: 1, display: 'flex', alignItems: 'center', justifyContent: 'center', color: '#555' }}>
                차트에서 붉은 영역(소요기록)을 클릭하세요.
              </div>
            )}
          </div>
        </div>
      </div>

      {/* ================= 하단: 메인 조작 패널 2 (분할 구조 도입) ================= */}
      <div style={{ display: 'flex', gap: 10, height: '150px' }}>
        
        {/* 좌측: 맵핑 그룹 활성화 */}
        <div style={{ flex: 3, border: '2px solid #4caf50', padding: 15, display: 'flex', flexDirection: 'column', gap: 10, overflowY: 'auto' }}>
          <h4 style={{ margin: 0, color: '#4caf50' }}>메인 조작 패널 2 (맵핑 그룹 활성화)</h4>
          <div style={{ display: 'flex', gap: 15, alignItems: 'center' }}>
            <select value={selectedGroupId} onChange={(e) => setSelectedGroupId(e.target.value ? Number(e.target.value) : '')} disabled={!selectedRoom || groups.length === 0 || isChartLoading} style={{ padding: 8, minWidth: 150, backgroundColor: '#333', color: 'white', opacity: isChartLoading ? 0.5 : 1 }}>
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
                      <input type="checkbox" checked={checkedRoles.includes(roleId)} onChange={() => handleRoleToggle(roleId)} disabled={isChartLoading} style={{ marginRight: 5, accentColor: color }} /> 
                      <span style={{ display: 'inline-block', width: 12, height: 12, backgroundColor: color, marginRight: 5, borderRadius: 2 }}></span>
                      {roleName}
                    </label>
                    <span onClick={() => setOpenMenuRoleId(openMenuRoleId === roleId ? null : roleId)} style={{ marginLeft: 5, cursor: 'pointer', fontSize: 16 }}>⚙️</span>
                    {openMenuRoleId === roleId && (
                      <div style={{ position: 'absolute', bottom: 'calc(100% + 8px)', left: 0, zIndex: 1000, backgroundColor: '#2a2a2a', border: '1px solid #555', padding: 10, borderRadius: 4, minWidth: 160, boxShadow: '0 4px 12px rgba(0,0,0,0.5)' }}>
                        <div style={{ marginBottom: 10, display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
                          <span style={{ fontSize: 12, color: '#ccc' }}>색상 변경:</span>
                          <input type="color" value={color} onChange={(e) => handleColorChange(roleId, e.target.value)} style={{ cursor: 'pointer', border: 'none', background: 'transparent', width: 30, height: 25 }} />
                        </div>
                        {!isBool && (
                          <div style={{ display: 'flex', alignItems: 'center' }}>
                            <label style={{ fontSize: 12, color: '#ccc', cursor: 'pointer' }}>
                              <input type="checkbox" checked={activeGuidelines.includes(roleId)} onChange={() => handleGuidelineToggle(roleId)} style={{ marginRight: 5 }} /> 
                              가이드라인 표시
                            </label>
                          </div>
                        )}
                      </div>
                    )}
                  </div>
                );
              })}
            </div>
          </div>
        </div>

        {/* 우측: 소요기록 Black List */}
        <div style={{ flex: 1, border: '2px solid #ff4d4f', padding: 15, display: 'flex', flexDirection: 'column', gap: 10, backgroundColor: '#2a1215', overflowY: 'auto' }}>
          <h4 style={{ margin: 0, color: '#ff4d4f', textAlign: 'center' }}>소요기록 Black List</h4>
          <div style={{ fontSize: 12, color: '#aaa', textAlign: 'center', marginBottom: 5 }}>현재 그룹에서 제외된 포스트</div>
          
          <div style={{ display: 'flex', flexDirection: 'column', gap: 5 }}>
            {hiddenPosts.map((hp: any) => (
              <div key={hp.id} style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', backgroundColor: '#441d1f', padding: '6px 10px', borderRadius: 4 }}>
                <span style={{ fontSize: 13, color: '#ffccc7' }}>{hp.title}</span>
                <button 
                  onClick={() => handleRestorePost(hp.id)} 
                  style={{ backgroundColor: 'transparent', border: '1px solid #ff4d4f', color: '#ff4d4f', cursor: 'pointer', borderRadius: 3, fontSize: 11, padding: '2px 6px' }}
                >
                  복구
                </button>
              </div>
            ))}
            {hiddenPosts.length === 0 && (
              <div style={{ textAlign: 'center', color: '#555', marginTop: 10 }}>제외된 항목이 없습니다.</div>
            )}
          </div>
        </div>

      </div>
    </div>
  );
};