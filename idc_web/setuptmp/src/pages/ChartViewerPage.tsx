// src/pages/ChartViewerPage.tsx
import React, { useState, useEffect, useRef, useCallback } from 'react';
import ReactECharts from 'echarts-for-react';
import { MainChartViewer, SubChartViewer } from '../components/chart/EChartsViewer';
import { CHART_SCOPING_CONFIG} from '../constants/chartConfig'; 
import type{ ChartMode, ChartScale } from '../constants/chartConfig'; 
import { apiService } from '../services/apiService';
import type { Role, ChartGroup } from '../types';

const getLocalDatetimeString = (date: Date) => {
  const offset = date.getTimezoneOffset() * 60000;
  return (new Date(date.getTime() - offset)).toISOString().slice(0, 16);
};

const COLOR_PALETTE = ['#5470c6', '#91cc75', '#fac858', '#ee6666', '#73c0de', '#3ba272', '#fc8452', '#9a60b4', '#ea7ccc', '#ff9f7f'];

function useDebouncedCallback<T extends (...args: any[]) => void>(callback: T, delay: number) {
  const timeoutRef = useRef<number | null>(null);
  return useCallback((...args: Parameters<T>) => {
    if (timeoutRef.current) window.clearTimeout(timeoutRef.current);
    timeoutRef.current = window.setTimeout(() => callback(...args), delay);
  }, [callback, delay]);
}

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
  const [selectedPostViewerIds, setSelectedPostViewerIds] = useState<number[]>([]);

  // 💡 [신규] Smart Omnibox 상태
  const [omniboxInput, setOmniboxInput] = useState('');
  const [omniboxSuggestions, setOmniboxSuggestions] = useState<any[]>([]);

  const mainChartRef = useRef<ReactECharts | null>(null);
  const subChartRef = useRef<ReactECharts | null>(null); 
  const currentZoomRef = useRef<{start: number, end: number} | null>(null);
  const loadedRangeRef = useRef<{ start: number, end: number } | null>(null);
  const [loadedRangeState, setLoadedRangeState] = useState<{ start: number, end: number } | null>(null);

  useEffect(() => { apiService.getFacilities().then(res => setFacilities(res.facilities || [])); }, []); 

  // 💡 [개선] 종속된 객체가 로드되면 가장 작은 ID(배열의 첫 요소)를 자동으로 선택합니다.
  useEffect(() => {
    if (selectedFacility) {
      apiService.getRooms(Number(selectedFacility)).then(res => {
        const fetchedRooms = res.rooms || [];
        setRooms(fetchedRooms);
        if (fetchedRooms.length > 0) setSelectedRoom(fetchedRooms[0].id); // 자동 선택
      });
      setSelectedRoom(''); setGroups([]); setAllRoles([]); setSelectedGroupId(''); setCheckedRoles([]); 
      setChartDataSets([]); setPosts([]); setHiddenPosts([]); setAlarms([]); setSelectedPostViewerIds([]);
      loadedRangeRef.current = null; setLoadedRangeState(null); currentZoomRef.current = null;
    }
  }, [selectedFacility]); 

  useEffect(() => {
    if (selectedFacility && selectedRoom) {
      apiService.getChartGroups(Number(selectedFacility), Number(selectedRoom)).then(res => {
        const fetchedGroups = res.groups || [];
        setGroups(fetchedGroups);
        if (fetchedGroups.length > 0) setSelectedGroupId(fetchedGroups[0].group_id); // 자동 선택
      }); 
      apiService.getPointRoles(Number(selectedFacility), Number(selectedRoom)).then(res => {
        const roles = res.roles || [];
        setAllRoles(roles);
        const newColorMap: Record<number, string> = {};
        roles.forEach((r: Role, idx: number) => { newColorMap[r.role_id] = COLOR_PALETTE[idx % COLOR_PALETTE.length]; });
        setRoleColors(newColorMap);
      });
      setSelectedGroupId(''); setCheckedRoles([]); setChartDataSets([]); setPosts([]); setHiddenPosts([]); setAlarms([]); setSelectedPostViewerIds([]);
      loadedRangeRef.current = null; setLoadedRangeState(null); currentZoomRef.current = null;
    }
  }, [selectedRoom, selectedFacility]); 

  useEffect(() => {
    if (selectedGroupId) {
      const group = groups.find(g => g.group_id === Number(selectedGroupId));
      if (group && group.role_ids) setCheckedRoles(group.role_ids.filter(id => id !== null));
    } else {
      setCheckedRoles([]); setChartDataSets([]); setPosts([]); setHiddenPosts([]); setAlarms([]); setSelectedPostViewerIds([]);
      loadedRangeRef.current = null; setLoadedRangeState(null); currentZoomRef.current = null;
    }
  }, [selectedGroupId, groups]); 

  // 💡 [신규] Smart Omnibox 자동완성 탐색 로직 (시설 종속성 반영)
  useEffect(() => {
    const q = omniboxInput.replace(/\s+/g, '').toLowerCase();
    if (!q) {
      setOmniboxSuggestions([]);
      return;
    }
    const sugs: any[] = [];
    
    // 시설은 항상 검색 대상
    facilities.forEach(f => {
      if (f.name.replace(/\s+/g, '').toLowerCase().includes(q)) sugs.push({ type: 'facility', id: f.id, name: f.name, label: `${f.name} (시설)` });
    });
    // 호실은 시설이 선택되어 있을 때만
    if (selectedFacility) {
      rooms.forEach(r => {
        if (r.name.replace(/\s+/g, '').toLowerCase().includes(q)) sugs.push({ type: 'room', id: r.id, name: r.name, label: `${r.name} (호실)` });
      });
    }
    // 그룹은 호실이 선택되어 있을 때만
    if (selectedRoom) {
      groups.forEach(g => {
        if (g.group_name.replace(/\s+/g, '').toLowerCase().includes(q)) sugs.push({ type: 'group', id: g.group_id, name: g.group_name, label: `${g.group_name} (맵핑)` });
      });
    }
    
    // 최대 유사도(길이 차이가 가장 적은 순) 정렬
    sugs.sort((a, b) => a.name.length - b.name.length);
    setOmniboxSuggestions(sugs);
  }, [omniboxInput, facilities, rooms, groups, selectedFacility, selectedRoom]);

  const handleOmniboxSelect = (sug: any) => {
    if (sug.type === 'facility') setSelectedFacility(sug.id);
    else if (sug.type === 'room') setSelectedRoom(sug.id);
    else if (sug.type === 'group') setSelectedGroupId(sug.id);
    setOmniboxInput('');
  };

  // 💡 [신규] 파서: 날짜 및 시간 추출 후 남은 문자로 상태 제어
  const handleOmniboxSubmit = () => {
    let remain = omniboxInput;
    let updatedDate = new Date(targetDate);
    let dateChanged = false;
    let timeChanged = false;

    // 1. 날짜 추출
    const dateRegex1 = /(?:^|\s)(\d{4})[./-](\d{1,2})[./-](\d{1,2})(?:\s|$)/; // YYYY/MM/DD
    const dateRegex2 = /(?:^|\s)(\d{1,2})[./-](\d{1,2})(?:\s|$)/;             // MM/DD
    const dateRegex3 = /(?:^|\s)(\d{1,2})\s*월\s*(\d{1,2})\s*일(?:\s|$)/;     // M월 D일

    let m;
    if ((m = remain.match(dateRegex1))) {
      updatedDate.setFullYear(parseInt(m[1]), parseInt(m[2]) - 1, parseInt(m[3]));
      remain = remain.replace(m[0], ' ');
      dateChanged = true;
    } else if ((m = remain.match(dateRegex3))) {
      updatedDate.setMonth(parseInt(m[1]) - 1, parseInt(m[2]));
      remain = remain.replace(m[0], ' ');
      dateChanged = true;
    } else if ((m = remain.match(dateRegex2))) {
      updatedDate.setMonth(parseInt(m[1]) - 1, parseInt(m[2]));
      remain = remain.replace(m[0], ' ');
      dateChanged = true;
    }

    // 2. 시간 추출
    const timeRegex1 = /(?:^|\s)([01]\d|2[0-3]):([0-5]\d)(?:\s|$)/; // 12:34
    const timeRegex2 = /(?:^|\s)([01]\d|2[0-3])([0-5]\d)(?:\s|$)/;  // 1234
    
    if ((m = remain.match(timeRegex1))) {
      updatedDate.setHours(parseInt(m[1]), parseInt(m[2]), 0, 0);
      remain = remain.replace(m[0], ' ');
      timeChanged = true;
    } else if ((m = remain.match(timeRegex2))) {
      updatedDate.setHours(parseInt(m[1]), parseInt(m[2]), 0, 0);
      remain = remain.replace(m[0], ' ');
      timeChanged = true;
    }

    // 일자만 입력하고 시간을 치지 않았다면 00:00으로 초기화
    if (dateChanged && !timeChanged) {
      updatedDate.setHours(0, 0, 0, 0);
    }

    if (dateChanged || timeChanged) {
      setTargetDate(getLocalDatetimeString(updatedDate));
    }

    // 3. 남은 문자열이 있다면 1순위 추천 항목을 자동 선택
    const q = remain.replace(/\s+/g, '');
    if (q && omniboxSuggestions.length > 0) {
      handleOmniboxSelect(omniboxSuggestions[0]);
    } else {
      setOmniboxInput('');
    }
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
        currentZoomRef.current = null;
        setChartDataSets(newDatasets);
        setPosts(newPosts);
        setAlarms(newAlarms);
        setHiddenPosts(newHiddenPosts);
        loadedRangeRef.current = { start: fetchStartMs, end: fetchEndMs };
      } else {
        setChartDataSets(prev => prev.map(prevDs => {
          const newDs = newDatasets.find((n: any) => n.role_id === prevDs.role_id);
          if (!newDs) return prevDs;
          
          let mergedData = direction === 'append' ? [...prevDs.data, ...newDs.data] : [...newDs.data, ...prevDs.data];
          mergedData.sort((a, b) => new Date(a.timestamp).getTime() - new Date(b.timestamp).getTime());
          
          const MAX_POINTS = 5000;
          if (mergedData.length > MAX_POINTS) {
            mergedData = direction === 'append' ? mergedData.slice(-MAX_POINTS) : mergedData.slice(0, MAX_POINTS);
          }
          return { ...prevDs, data: mergedData };
        }));

        setPosts(prev => {
          const combined = direction === 'append' ? [...prev, ...newPosts] : [...newPosts, ...prev];
          return Array.from(new Map(combined.map(p => [p.id, p])).values()); 
        });
        setAlarms(prev => {
          const combined = direction === 'append' ? [...prev, ...newAlarms] : [...newAlarms, ...prev];
          return Array.from(new Map(combined.map(a => [a.alarm_id, a])).values());
        });

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
    } catch (err) {
      console.error("차트 청크 호출 오류:", err);
    } finally {
      setIsChartLoading(false);
    }
  };

  useEffect(() => {
    if (selectedFacility && selectedRoom && checkedRoles.length > 0 && targetDate) {
      const endMs = new Date(targetDate).getTime();
      const chunkMs = CHART_SCOPING_CONFIG[mode][scale].chunkSize;
      const startMs = endMs - chunkMs;
      fetchAndMergeChunk(startMs, endMs, 'replace');
    } else {
      setChartDataSets([]); setPosts([]); setAlarms([]); setHiddenPosts([]);
      loadedRangeRef.current = null; setLoadedRangeState(null);
    }
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [selectedFacility, selectedRoom, scale, targetDate, checkedRoles, refreshTrigger]); 

  const handleDataZoomFetch = useDebouncedCallback((viewStartMs: number, viewEndMs: number) => {
    if (isChartLoading || !loadedRangeRef.current || checkedRoles.length === 0) return;
    const config = CHART_SCOPING_CONFIG[mode][scale];
    const chunkMs = config.chunkSize;
    const buffer = chunkMs * 0.2; 

    if (viewStartMs < loadedRangeRef.current.start + buffer) {
      fetchAndMergeChunk(loadedRangeRef.current.start - chunkMs, loadedRangeRef.current.start, 'prepend');
    } else if (viewEndMs > loadedRangeRef.current.end - buffer) {
      fetchAndMergeChunk(loadedRangeRef.current.end, loadedRangeRef.current.end + chunkMs, 'append');
    }
  }, 500);

  const handleZoomCapture = useCallback((start: number, end: number) => {
    currentZoomRef.current = { start, end };
    handleDataZoomFetch(start, end);
  }, [handleDataZoomFetch]);

  const isBoolRole = (roleId: number) => {
    const role = allRoles.find(r => String(r.role_id) === String(roleId));
    if (!role) return false;
    if (role.data_type) {
      return role.data_type === 'BOOL';
    }
    return role.role_name.toLowerCase().includes('bool');
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

  const handleChartClick = (type: 'post' | 'alarm', ids: number | number[]) => {
    if (type === 'post') setSelectedPostViewerIds(Array.isArray(ids) ? ids : [ids]);
  };

  const handleHidePost = async (postId: number) => {
    if (!selectedGroupId) return;
    try {
      await apiService.hidePostFromGroup(Number(selectedGroupId), postId);
      setSelectedPostViewerIds(prev => prev.filter(id => id !== postId)); 
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
            <MainChartViewer 
              echartsRef={mainChartRef} datasets={mainDataSets} roleColors={roleColors} 
              showInfo={showMainInfo} showGrid={showMainGrid} activeGuidelines={activeGuidelines} isLoading={isChartLoading}
              posts={posts} alarms={alarms} onChartClick={handleChartClick} 
              loadedRange={loadedRangeState} 
              onDataZoomPan={handleZoomCapture} 
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
              loadedRange={loadedRangeState} 
            />
          </div>
        </div>

        {/* ================= 오른쪽: 패널 1 영역 ================= */}
        <div style={{ flex: 1, border: '2px solid #e91e63', display: 'flex', flexDirection: 'column', padding: 10, gap: 10 }}>
          
          {/* 💡 [신규] Smart Omnibox UI */}
          <div style={{ border: '2px solid #ffffff', padding: 15, display: 'flex', flexDirection: 'column', gap: 10 }}>
            <h4 style={{ margin: 0, textAlign: 'center', color: '#ff9800' }}>Smart Omnibox (스마트 검색)</h4>
            <div style={{ position: 'relative' }}>
              <input 
                type="text" 
                value={omniboxInput}
                onChange={e => setOmniboxInput(e.target.value)}
                onKeyDown={e => { if (e.key === 'Enter') handleOmniboxSubmit(); }}
                disabled={isChartLoading}
                placeholder="예: 제1시설 101호 8월17일 1234"
                style={{ width: '100%', padding: 8, boxSizing: 'border-box', backgroundColor: '#333', color: '#fff', border: '1px solid #555', outline: 'none' }}
              />
              {omniboxSuggestions.length > 0 && (
                <div style={{ position: 'absolute', top: '100%', left: 0, right: 0, backgroundColor: '#444', border: '1px solid #666', zIndex: 100, maxHeight: 150, overflowY: 'auto' }}>
                  {omniboxSuggestions.map((sug, i) => (
                    <div 
                      key={i} 
                      onClick={() => handleOmniboxSelect(sug)}
                      style={{ padding: '8px 12px', cursor: 'pointer', borderBottom: '1px solid #555', color: '#82b1ff', fontSize: 13 }}
                      onMouseEnter={(e) => (e.currentTarget.style.backgroundColor = '#555')}
                      onMouseLeave={(e) => (e.currentTarget.style.backgroundColor = 'transparent')}
                    >
                      {sug.label}
                    </div>
                  ))}
                </div>
              )}
            </div>
            <div style={{ fontSize: 11, color: '#aaa', textAlign: 'center' }}>엔터키 입력 시 자동 파싱 적용</div>
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