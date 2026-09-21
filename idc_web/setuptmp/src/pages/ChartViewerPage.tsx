import React, { useState, useEffect, useRef, useCallback } from 'react';
import ReactECharts from 'echarts-for-react';
import { MainChartViewer, SubChartViewer } from '../components/chart/viewer/EChartsViewer';
import { TopToolBar } from '../components/chart/viewer/TopToolBar';
import { LowerToolBar } from '../components/chart/viewer/LowerToolBar';
import { SmartOmniboxPanel } from '../components/chart/viewer/panels/SmartOmniboxPanel';
import { ScopingPanel } from '../components/chart/viewer/panels/ScopingPanel';
import { PostViewerPanel } from '../components/chart/viewer/panels/PostViewerPanel';
import { MappingActivePanel } from '../components/chart/viewer/panels/MappingActivePanel';
import { BlacklistPanel } from '../components/chart/viewer/panels/BlacklistPanel';
import { ChartStatsPanel } from '../components/chart/viewer/panels/ChartStatsPanel';
import { CHART_SCOPING_CONFIG} from '../constants/chartConfig'; 
import type{ ChartMode, ChartScale } from '../constants/chartConfig'; 
import { apiService } from '../services/apiService';
import type { Role, ChartGroup } from '../types';

const getLocalDatetimeString = (date: Date) => {
  const offset = date.getTimezoneOffset() * 60000;
  return (new Date(date.getTime() - offset)).toISOString().slice(0, 16);
};

interface ViewerProps {
  user: { id: number; role: string; name: string };
}

const COLOR_PALETTE = ['#5470c6', '#91cc75', '#fac858', '#ee6666', '#73c0de', '#3ba272', '#fc8452', '#9a60b4', '#ea7ccc', '#ff9f7f'];

function useDebouncedCallback<T extends (...args: any[]) => void>(callback: T, delay: number) {
  const timeoutRef = useRef<number | null>(null);
  return useCallback((...args: Parameters<T>) => {
    if (timeoutRef.current) window.clearTimeout(timeoutRef.current);
    timeoutRef.current = window.setTimeout(() => callback(...args), delay);
  }, [callback, delay]);
}

//export const ChartViewerPage: React.FC = () => {
export const ChartViewerPage: React.FC<ViewerProps> = ({ user }) => {
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
  const [invertedBools, setInvertedBools] = useState<number[]>([]);
  const [isChartLoading, setIsChartLoading] = useState<boolean>(false); 

  const [posts, setPosts] = useState<any[]>([]);
  const [alarms, setAlarms] = useState<any[]>([]);
  const [hiddenPosts, setHiddenPosts] = useState<any[]>([]);
  const [selectedPostViewerIds, setSelectedPostViewerIds] = useState<number[]>([]);

  const [omniboxInput, setOmniboxInput] = useState('');
  const [omniboxSuggestions, setOmniboxSuggestions] = useState<any[]>([]);

  const mainChartRef = useRef<ReactECharts | null>(null);
  const subChartRef = useRef<ReactECharts | null>(null); 
  const loadedRangeRef = useRef<{ start: number, end: number } | null>(null);
  const [loadedRangeState, setLoadedRangeState] = useState<{ start: number, end: number } | null>(null);
  const [currentViewStart, setCurrentViewStart] = useState<number | null>(null);

  // useEffect(() => { 
  //   //apiService.getFacilities().then(res => setFacilities(res.facilities || [])); 
  //   apiService.getUserFacilities(user.id).then(res => setFacilities(res.facilities || [])); 
  // }, [user.id]);
  useEffect(() => { 
    apiService.getFacilities().then(res => setFacilities(res.facilities || [])); 
  }, []);

  // useEffect(() => {
  //   if (selectedFacility) {
  //     apiService.getRooms(Number(selectedFacility)).then(res => {
  //       const fetchedRooms = res.rooms || [];
  //       setRooms(fetchedRooms);
  //       if (fetchedRooms.length > 0) setSelectedRoom(fetchedRooms[0].id); 
  //     });
  //     setSelectedRoom(''); setGroups([]); setAllRoles([]); setSelectedGroupId(''); setCheckedRoles([]); 
  //     setChartDataSets([]); setPosts([]); setHiddenPosts([]); setAlarms([]); setSelectedPostViewerIds([]); setInvertedBools([]);
  //     loadedRangeRef.current = null; setLoadedRangeState(null); setCurrentViewStart(null);
  //   }
  // }, [selectedFacility]); 
  useEffect(() => {
  if (!selectedFacility) {
    setRooms([]);
    setSelectedRoom('');
    return;
  }

  // 1. 시설이 변경되었을 때 하위 데이터 먼저 초기화
  setSelectedRoom('');
  setRooms([]);
  setGroups([]);
  setAllRoles([]);
  setSelectedGroupId('');
  setCheckedRoles([]);
  setChartDataSets([]);
  setPosts([]);
  setHiddenPosts([]);
  setAlarms([]);
  setSelectedPostViewerIds([]);
  setInvertedBools([]);
  loadedRangeRef.current = null;
  setLoadedRangeState(null);
  setCurrentViewStart(null);

  // 2. 초기화 완료 후 방 목록 요청
  apiService.getRooms(Number(selectedFacility)).then(res => {
    const fetchedRooms = res.rooms || [];
    setRooms(fetchedRooms);
    if (fetchedRooms.length > 0) {
      setSelectedRoom(fetchedRooms[0].id);
    }
  }).catch(err => {
    console.error("호실 불러오기 실패:", err);
  });
}, [selectedFacility]);


  useEffect(() => {
    if (selectedFacility && selectedRoom) {
      apiService.getChartGroups(Number(selectedFacility), Number(selectedRoom)).then(res => {
        const fetchedGroups = res.groups || [];
        setGroups(fetchedGroups);
        if (fetchedGroups.length > 0) setSelectedGroupId(fetchedGroups[0].group_id); 
      }); 
      apiService.getPointRoles(Number(selectedFacility), Number(selectedRoom)).then(res => {
        const roles = res.roles || [];
        setAllRoles(roles);
        const newColorMap: Record<number, string> = {};
        roles.forEach((r: Role, idx: number) => { newColorMap[r.role_id] = COLOR_PALETTE[idx % COLOR_PALETTE.length]; });
        setRoleColors(newColorMap);
      });
      setSelectedGroupId(''); setCheckedRoles([]); setChartDataSets([]); setPosts([]); setHiddenPosts([]); setAlarms([]); setSelectedPostViewerIds([]); setInvertedBools([]);
      loadedRangeRef.current = null; setLoadedRangeState(null); setCurrentViewStart(null);
    }
  }, [selectedRoom, selectedFacility]); 

  useEffect(() => {
    if (selectedGroupId) {
      const group = groups.find(g => g.group_id === Number(selectedGroupId));
      if (group && group.role_ids) setCheckedRoles(group.role_ids.filter(id => id !== null));
    } else {
      setCheckedRoles([]); setChartDataSets([]); setPosts([]); setHiddenPosts([]); setAlarms([]); setSelectedPostViewerIds([]); setInvertedBools([]);
      loadedRangeRef.current = null; setLoadedRangeState(null); setCurrentViewStart(null);
    }
  }, [selectedGroupId, groups]); 

  useEffect(() => {
    const q = omniboxInput.replace(/\s+/g, '').toLowerCase();
    if (!q) { setOmniboxSuggestions([]); return; }
    const sugs: any[] = [];
    facilities.forEach(f => { if (f.name.replace(/\s+/g, '').toLowerCase().includes(q)) sugs.push({ type: 'facility', id: f.id, name: f.name, label: `${f.name} (시설)` }); });
    if (selectedFacility) {
      rooms.forEach(r => { if (r.name.replace(/\s+/g, '').toLowerCase().includes(q)) sugs.push({ type: 'room', id: r.id, name: r.name, label: `${r.name} (호실)` }); });
    }
    if (selectedRoom) {
      groups.forEach(g => { if (g.group_name.replace(/\s+/g, '').toLowerCase().includes(q)) sugs.push({ type: 'group', id: g.group_id, name: g.group_name, label: `${g.group_name} (맵핑)` }); });
    }
    sugs.sort((a, b) => a.name.length - b.name.length);
    setOmniboxSuggestions(sugs);
  }, [omniboxInput, facilities, rooms, groups, selectedFacility, selectedRoom]);

  const handleOmniboxSelect = (sug: any) => {
    if (sug.type === 'facility') setSelectedFacility(sug.id);
    else if (sug.type === 'room') setSelectedRoom(sug.id);
    else if (sug.type === 'group') setSelectedGroupId(sug.id);
    setOmniboxInput('');
  };

  const handleOmniboxSubmit = () => {
    let remain = omniboxInput;
    let updatedDate = new Date(targetDate);
    let dateChanged = false; let timeChanged = false;

    const dateRegex1 = /(?:^|\s)(\d{4})[./-](\d{1,2})[./-](\d{1,2})(?:\s|$)/; 
    const dateRegex2 = /(?:^|\s)(\d{1,2})[./-](\d{1,2})(?:\s|$)/;             
    const dateRegex3 = /(?:^|\s)(\d{1,2})\s*월\s*(\d{1,2})\s*일(?:\s|$)/;     

    let m;
    if ((m = remain.match(dateRegex1))) { updatedDate.setFullYear(parseInt(m[1]), parseInt(m[2]) - 1, parseInt(m[3])); remain = remain.replace(m[0], ' '); dateChanged = true; } 
    else if ((m = remain.match(dateRegex3))) { updatedDate.setMonth(parseInt(m[1]) - 1, parseInt(m[2])); remain = remain.replace(m[0], ' '); dateChanged = true; } 
    else if ((m = remain.match(dateRegex2))) { updatedDate.setMonth(parseInt(m[1]) - 1, parseInt(m[2])); remain = remain.replace(m[0], ' '); dateChanged = true; }

    const timeRegex1 = /(?:^|\s)([01]\d|2[0-3]):([0-5]\d)(?:\s|$)/; 
    const timeRegex2 = /(?:^|\s)([01]\d|2[0-3])([0-5]\d)(?:\s|$)/;  
    
    if ((m = remain.match(timeRegex1))) { updatedDate.setHours(parseInt(m[1]), parseInt(m[2]), 0, 0); remain = remain.replace(m[0], ' '); timeChanged = true; } 
    else if ((m = remain.match(timeRegex2))) { updatedDate.setHours(parseInt(m[1]), parseInt(m[2]), 0, 0); remain = remain.replace(m[0], ' '); timeChanged = true; }

    if (dateChanged && !timeChanged) updatedDate.setHours(0, 0, 0, 0);
    if (dateChanged || timeChanged) setTargetDate(getLocalDatetimeString(updatedDate));

    const q = remain.replace(/\s+/g, '');
    if (q && omniboxSuggestions.length > 0) handleOmniboxSelect(omniboxSuggestions[0]);
    else setOmniboxInput('');
  };

  const fetchAndMergeChunk = async (fetchStartMs: number, fetchEndMs: number, direction: 'replace' | 'append' | 'prepend') => {
    if (!selectedFacility || !selectedRoom || checkedRoles.length === 0) return;
    setIsChartLoading(true);
    try {
      const startIso = new Date(fetchStartMs).toISOString();
      const endIso = new Date(fetchEndMs).toISOString();
      const res = await apiService.getHistoricalData(Number(selectedFacility), Number(selectedRoom), selectedGroupId, scale, startIso, endIso, checkedRoles);
      
      const newDatasets = res.data?.datasets || [];
      const newPosts = res.data?.posts || [];
      const newAlarms = res.data?.alarms || [];
      const newHiddenPosts = res.data?.hidden_posts || [];

      if (direction === 'replace') {
        setChartDataSets(newDatasets); setPosts(newPosts); setAlarms(newAlarms); setHiddenPosts(newHiddenPosts);
        loadedRangeRef.current = { start: fetchStartMs, end: fetchEndMs };
        setCurrentViewStart(fetchStartMs);
      } else {
        setChartDataSets(prev => prev.map(prevDs => {
          const newDs = newDatasets.find((n: any) => n.role_id === prevDs.role_id);
          if (!newDs) return prevDs;
          let mergedData = direction === 'append' ? [...prevDs.data, ...newDs.data] : [...newDs.data, ...prevDs.data];
          mergedData.sort((a, b) => new Date(a.timestamp).getTime() - new Date(b.timestamp).getTime());
          if (mergedData.length > 5000) mergedData = direction === 'append' ? mergedData.slice(-5000) : mergedData.slice(0, 5000);
          return { ...prevDs, data: mergedData };
        }));

        setPosts(prev => { const combined = direction === 'append' ? [...prev, ...newPosts] : [...newPosts, ...prev]; return Array.from(new Map(combined.map(p => [p.id, p])).values()); });
        setAlarms(prev => { const combined = direction === 'append' ? [...prev, ...newAlarms] : [...newAlarms, ...prev]; return Array.from(new Map(combined.map(a => [a.alarm_id, a])).values()); });

        if (loadedRangeRef.current) {
          const config = CHART_SCOPING_CONFIG[mode][scale];
          const maxMsRange = config.chunkSize * config.maxChunks;
          let newStart = Math.min(loadedRangeRef.current.start, fetchStartMs);
          let newEnd = Math.max(loadedRangeRef.current.end, fetchEndMs);
          if (newEnd - newStart > maxMsRange) {
            if (direction === 'append') newStart = newEnd - maxMsRange;
            if (direction === 'prepend') newEnd = newStart + maxMsRange;
          }
          loadedRangeRef.current = { start: newStart, end: newEnd };
        }
      }
      setLoadedRangeState(loadedRangeRef.current);
    } catch (err) { console.error(err); } 
    finally { setIsChartLoading(false); }
  };

  useEffect(() => {
    if (selectedFacility && selectedRoom && checkedRoles.length > 0 && targetDate) {
      const endMs = new Date(targetDate).getTime();
      const chunkMs = CHART_SCOPING_CONFIG[mode][scale].chunkSize;
      fetchAndMergeChunk(endMs - chunkMs, endMs, 'replace');
    } else {
      setChartDataSets([]); setPosts([]); setAlarms([]); setHiddenPosts([]);
      loadedRangeRef.current = null; setLoadedRangeState(null); setCurrentViewStart(null);
    }
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [selectedFacility, selectedRoom, scale, targetDate, checkedRoles, refreshTrigger]); 

  const handleDataZoomFetch = useDebouncedCallback((viewStartMs: number, viewEndMs: number) => {
    if (isChartLoading || !loadedRangeRef.current || checkedRoles.length === 0) return;
    const config = CHART_SCOPING_CONFIG[mode][scale];
    const buffer = config.chunkSize * 0.2; 
    if (viewStartMs < loadedRangeRef.current.start + buffer) fetchAndMergeChunk(loadedRangeRef.current.start - config.chunkSize, loadedRangeRef.current.start, 'prepend');
    else if (viewEndMs > loadedRangeRef.current.end - buffer) fetchAndMergeChunk(loadedRangeRef.current.end, loadedRangeRef.current.end + config.chunkSize, 'append');
  }, 500);

  const handleZoomCapture = useCallback((start: number, end: number) => {
    setCurrentViewStart(start); 
    handleDataZoomFetch(start, end);
  }, [handleDataZoomFetch]);

  const isBoolRole = (roleId: number) => {
    const role = allRoles.find(r => String(r.role_id) === String(roleId));
    if (!role) return false;
    return role.data_type ? role.data_type === 'BOOL' : role.role_name.toLowerCase().includes('bool');
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
    setCheckedRoles(prev => prev.includes(roleId) ? prev.filter(id => id !== roleId) : (mode === 'EXTENT' && !isBool ? [...prev.filter(id => isBoolRole(id)), roleId] : [...prev, roleId]));
  }; 

  const handleInvertToggle = (roleId: number) => setInvertedBools(prev => prev.includes(roleId) ? prev.filter(id => id !== roleId) : [...prev, roleId]);
  const handleColorChange = (roleId: number, color: string) => setRoleColors(prev => ({ ...prev, [roleId]: color }));
  const handleGuidelineToggle = (roleId: number) => setActiveGuidelines(prev => prev.includes(roleId) ? prev.filter(id => id !== roleId) : [...prev, roleId]);

  const syncChartDataZoom = (sourceRef: React.RefObject<ReactECharts | null>, targetRef: React.RefObject<ReactECharts | null>) => {
    const option = sourceRef.current?.getEchartsInstance().getOption() as any;
    if (option?.dataZoom?.length > 0) targetRef.current?.getEchartsInstance().dispatchAction({ type: 'dataZoom', startValue: option.dataZoom[0].startValue, endValue: option.dataZoom[0].endValue });
  }; 

  const applyOneHourView = () => {
    const option = mainChartRef.current?.getEchartsInstance().getOption() as any;
    let centerTime = new Date(targetDate).getTime();
    if (option?.dataZoom?.length > 0 && option.dataZoom[0].startValue) centerTime = (option.dataZoom[0].startValue + option.dataZoom[0].endValue) / 2;
    const zoomPayload = { type: 'dataZoom', startValue: centerTime - 1800000, endValue: centerTime + 1800000 };
    mainChartRef.current?.getEchartsInstance().dispatchAction(zoomPayload);
    subChartRef.current?.getEchartsInstance().dispatchAction(zoomPayload);
  }; 

  const handleQuickTimeSelect = (hours: number) => {
    if (isChartLoading) return; 
    const now = new Date(); setTargetDate(getLocalDatetimeString(now)); 
    setTimeout(() => {
      const zoomPayload = { type: 'dataZoom', startValue: now.getTime() - (hours * 3600000), endValue: now.getTime() };
      mainChartRef.current?.getEchartsInstance().dispatchAction(zoomPayload);
      subChartRef.current?.getEchartsInstance().dispatchAction(zoomPayload);
    }, 300); 
  }; 

  const handleQuickDaySelect = (targetDayOfWeek: number) => {
    if (isChartLoading) return; 
    const now = new Date();
    let diff = now.getDay() - targetDayOfWeek;
    if (diff < 0) diff += 7;
    setTargetDate(getLocalDatetimeString(new Date(now.getTime() - (diff * 86400000))));
  }; 

  const handleChartClick = (type: 'post' | 'alarm', ids: number | number[]) => {
    if (type === 'post') setSelectedPostViewerIds(Array.isArray(ids) ? ids : [ids]);
  };

  const handleHidePost = async (postId: number) => {
    if (!selectedGroupId) return;
    try { await apiService.hidePostFromGroup(Number(selectedGroupId), postId); setSelectedPostViewerIds(prev => prev.filter(id => id !== postId)); setRefreshTrigger(prev => prev + 1); } catch (e) {}
  };

  const handleRestorePost = async (postId: number) => {
    if (!selectedGroupId) return;
    try { await apiService.showPostInGroup(Number(selectedGroupId), postId); setRefreshTrigger(prev => prev + 1); } catch (e) {}
  };

  const handleCopySearchQuery = () => {
    if (!selectedFacility || !selectedRoom || !currentViewStart) return;
    const facName = facilities.find(f => f.id === selectedFacility)?.name || '';
    const roomName = rooms.find(r => r.id === selectedRoom)?.name || '';
    const d = new Date(currentViewStart);
    const query = `${facName} ${roomName} ${d.getMonth() + 1}/${d.getDate()} ${d.getHours().toString().padStart(2, '0')}:${d.getMinutes().toString().padStart(2, '0')}`;
    navigator.clipboard.writeText(query).then(() => alert(`클립보드에 복사되었습니다:\n${query}`));
  };

  const mainDataSets = chartDataSets.filter(ds => ds.role_name && !isBoolRole(ds.role_id));
  const subDataSets = chartDataSets.filter(ds => ds.role_name && isBoolRole(ds.role_id)); 

  // 💡 [UI 핵심 수정] 최상위 컨테이너에 overflowY: 'auto' 적용
  return (
    <div style={{ display: 'flex', flexDirection: 'column', height: '100%', overflowY: 'auto', gap: 12, boxSizing: 'border-box', padding: 24 }}>

      {/* 상단: 차트 + 검색/스코핑 패널 (최소 높이 보장) */}
      <div style={{ display: 'flex', gap: 12, minHeight: 650, flexShrink: 0 }}>

        {/* 왼쪽 차트 영역 */}
        <div style={{ flex: 3, display: 'flex', flexDirection: 'column', gap: 10 }}>
          <TopToolBar showInfo={showMainInfo} showGrid={showMainGrid} targetDate={targetDate} isChartLoading={isChartLoading} onCopy={handleCopySearchQuery} onToggleInfo={() => setShowMainInfo(!showMainInfo)} onToggleGrid={() => setShowMainGrid(!showMainGrid)} onOneHourView={applyOneHourView} onDateChange={setTargetDate} />
          <div className="card" style={{ flex: 2, display: 'flex', flexDirection: 'column', minHeight: 0, padding: 12 }}>
            <MainChartViewer echartsRef={mainChartRef} datasets={mainDataSets} roleColors={roleColors} showInfo={showMainInfo} showGrid={showMainGrid} activeGuidelines={activeGuidelines} isLoading={isChartLoading} posts={posts} alarms={alarms} onChartClick={handleChartClick} loadedRange={loadedRangeState} onDataZoomPan={handleZoomCapture} />
          </div>
          <LowerToolBar showInfo={showSubInfo} showGrid={showSubGrid} onToggleInfo={() => setShowSubInfo(!showSubInfo)} onToggleGrid={() => setShowSubGrid(!showSubGrid)} onSyncTop={() => syncChartDataZoom(mainChartRef, subChartRef)} onSyncSub={() => syncChartDataZoom(subChartRef, mainChartRef)} />
          <div className="card" style={{ flex: 1, display: 'flex', flexDirection: 'column', minHeight: 0, padding: 12 }}>
            <SubChartViewer echartsRef={subChartRef} datasets={subDataSets} roleColors={roleColors} showInfo={showSubInfo} showGrid={showSubGrid} isLoading={isChartLoading} posts={posts} alarms={alarms} invertedBools={invertedBools} loadedRange={loadedRangeState} />
          </div>
        </div>

        {/* 오른쪽 패널 영역 */}
        <div style={{ flex: 1, display: 'flex', flexDirection: 'column', gap: 10 }}>
          <SmartOmniboxPanel input={omniboxInput} suggestions={omniboxSuggestions} isChartLoading={isChartLoading} onInputChange={setOmniboxInput} onSubmit={handleOmniboxSubmit} onSelect={handleOmniboxSelect} />
          <ScopingPanel mode={mode} scale={scale} facilities={facilities} rooms={rooms} selectedFacility={selectedFacility} selectedRoom={selectedRoom} isChartLoading={isChartLoading} onModeToggle={handleModeToggle} onScaleChange={setScale} onFacilityChange={setSelectedFacility} onRoomChange={setSelectedRoom} onQuickTime={handleQuickTimeSelect} onQuickDay={handleQuickDaySelect} />
          <PostViewerPanel selectedPostIds={selectedPostViewerIds} posts={posts} selectedGroupId={selectedGroupId} onHidePost={handleHidePost} />
          <ChartStatsPanel datasets={mainDataSets} roleColors={roleColors} />
        </div>
      </div>

      {/* 하단: 맵핑 활성화 + 블랙리스트 (내용에 따라 자동 확장) */}
      <div style={{ display: 'flex', gap: 12, flexShrink: 0 }}>
        <MappingActivePanel groups={groups} allRoles={allRoles} roleColors={roleColors} selectedGroupId={selectedGroupId} selectedRoom={selectedRoom} isChartLoading={isChartLoading} checkedRoles={checkedRoles} activeGuidelines={activeGuidelines} invertedBools={invertedBools} openMenuRoleId={openMenuRoleId} onGroupChange={setSelectedGroupId} onRoleToggle={handleRoleToggle} onMenuToggle={setOpenMenuRoleId} onColorChange={handleColorChange} onGuidelineToggle={handleGuidelineToggle} onInvertToggle={handleInvertToggle} isBoolRole={isBoolRole} />
        <BlacklistPanel hiddenPosts={hiddenPosts} onRestore={handleRestorePost} />
      </div>

    </div>
  );
};