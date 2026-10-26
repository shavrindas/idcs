import React, { useState, useEffect, useRef, useCallback } from 'react';
import ReactECharts from 'echarts-for-react';
import { useSearchParams } from 'react-router-dom';
import { MainChartViewer, SubChartViewer } from '../components/chart/viewer/EChartsViewer';
import { TopToolBar } from '../components/chart/viewer/TopToolBar';
import { LowerToolBar } from '../components/chart/viewer/LowerToolBar';
import { SmartOmniboxPanel } from '../components/chart/viewer/panels/SmartOmniboxPanel';
import { ScopingPanel } from '../components/chart/viewer/panels/ScopingPanel';
import { PostViewerPanel } from '../components/chart/viewer/panels/PostViewerPanel';
import { MappingActivePanel } from '../components/chart/viewer/panels/MappingActivePanel';
import { BlacklistPanel } from '../components/chart/viewer/panels/BlacklistPanel';
import { ChartStatsPanel } from '../components/chart/viewer/panels/ChartStatsPanel';
import { ChartEmptyState } from '../components/chart/viewer/ChartEmptyState';
import type { EmptyReason } from '../components/chart/viewer/ChartEmptyState';
import { CHART_SCOPING_CONFIG} from '../constants/chartConfig'; 
import type{ ChartMode, ChartScale } from '../constants/chartConfig'; 
import { apiService } from '../services/apiService';
import { copyToClipboard } from '../services/clipboard';
import { extractDateTime, removeName } from '../services/omnibox';
import type { Role, ChartGroup, SessionUser } from '../types';

interface Props {
  user: SessionUser;
}

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

export const ChartViewerPage: React.FC<Props> = ({ user }) => {
  const [mode, setMode] = useState<ChartMode>('DEFAULT');
  const [scale, setScale] = useState<ChartScale>('1m');
  const [targetDate, setTargetDate] = useState<string>(getLocalDatetimeString(new Date()));
  const [refreshTrigger, setRefreshTrigger] = useState<number>(0); 
  
  const [facilities, setFacilities] = useState<any[]>([]);
  const [rooms, setRooms] = useState<any[]>([]);
  const [groups, setGroups] = useState<ChartGroup[]>([]);
  const [allRoles, setAllRoles] = useState<Role[]>([]);

  // Opened from an overview card: /viewer?facility=3&room=12 preselects that room.
  const [searchParams] = useSearchParams();
  const requestedRoom = useRef<number | null>(Number(searchParams.get('room')) || null);
  const [selectedFacility, setSelectedFacility] = useState<number | ''>(Number(searchParams.get('facility')) || '');
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
  /// 드롭다운에서 키보드로 짚고 있는 줄.
  const [omniboxActive, setOmniboxActive] = useState(0);

  const mainChartRef = useRef<ReactECharts | null>(null);
  const subChartRef = useRef<ReactECharts | null>(null); 
  const loadedRangeRef = useRef<{ start: number, end: number } | null>(null);
  const [loadedRangeState, setLoadedRangeState] = useState<{ start: number, end: number } | null>(null);
  const [currentViewStart, setCurrentViewStart] = useState<number | null>(null);

  /// 메인 차트 y축 위아래 여백. 툴바에서 고른다.
  const [yBuffer, setYBuffer] = useState<number | 'auto'>('auto');

  useEffect(() => {
    apiService.getUserFacilities(user.id).then(res => setFacilities(res.facilities || []));
  }, [user.id]);

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
    const wanted = fetchedRooms.find((r: any) => r.id === requestedRoom.current);
    requestedRoom.current = null;
    if (wanted) {
      setSelectedRoom(wanted.id);
    } else if (fetchedRooms.length > 0) {
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
    // 날짜·시각은 이름이 아니다. 먼저 걷어내지 않으면 '냉동 1호 8/17 11:30' 이
    // 통째로 한 덩어리가 되어 아무것도 못 찾는다 — 복사한 문장을 그대로
    // 붙여 넣을 수 없던 이유다.
    const { remaining } = extractDateTime(omniboxInput);

    // 낱말마다 따로 맞춘다. 호실 이름에 공백이 있어서('냉동 1호') 공백을 모두
    // 지운 형태로도 함께 본다.
    const words = remaining.split(/\s+/).filter(Boolean);
    const squashed = remaining.replace(/\s+/g, '');
    const needles = Array.from(new Set([...words, squashed].map(w => w.toLowerCase()).filter(Boolean)));
    if (needles.length === 0) { setOmniboxSuggestions([]); return; }

    const hit = (name: string) => {
      const flat = name.replace(/\s+/g, '').toLowerCase();
      return needles.some(n => flat.includes(n.replace(/\s+/g, '')));
    };

    const sugs: any[] = [];
    facilities.forEach(f => { if (hit(f.name)) sugs.push({ type: 'facility', id: f.id, name: f.name, label: `${f.name} (시설)` }); });
    if (selectedFacility) {
      rooms.forEach(r => { if (hit(r.name)) sugs.push({ type: 'room', id: r.id, name: r.name, label: `${r.name} (호실)` }); });
    }
    if (selectedRoom) {
      groups.forEach(g => { if (hit(g.group_name)) sugs.push({ type: 'group', id: g.group_id, name: g.group_name, label: `${g.group_name} (맵핑)` }); });
    }

    // 시설 → 호실 → 맵핑 순으로, 같은 종류끼리는 짧은 이름이 먼저.
    const order = { facility: 0, room: 1, group: 2 } as Record<string, number>;
    sugs.sort((a, b) => (order[a.type] - order[b.type]) || (a.name.length - b.name.length));
    setOmniboxSuggestions(sugs);
    setOmniboxActive(0);
  }, [omniboxInput, facilities, rooms, groups, selectedFacility, selectedRoom]);

  const handleOmniboxSelect = (sug: any) => {
    if (sug.type === 'facility') setSelectedFacility(sug.id);
    else if (sug.type === 'room') setSelectedRoom(sug.id);
    else if (sug.type === 'group') setSelectedGroupId(sug.id);

    // 고른 이름만 지우고 나머지는 남긴다. '다온인터내셔널 냉동 1호' 처럼 한
    // 문장에 여럿이 들어 있을 때, 시설을 고르고 나면 호실이 그제서야 불러와지는데
    // 입력을 통째로 비워 버리면 거기서 끊긴다. 남겨 두면 이어서 고를 수 있다.
    setOmniboxInput(prev => removeName(prev, sug.name));
    setOmniboxActive(0);
  };

  const handleOmniboxSubmit = () => {
    const { date, dateChanged, timeChanged, remaining } = extractDateTime(omniboxInput, new Date(targetDate));
    if (dateChanged || timeChanged) setTargetDate(getLocalDatetimeString(date));

    // 이름이 남아 있으면 지금 고른 줄을 적용한다. 날짜만 적은 경우에는 날짜만
    // 반영하고 입력을 비운다.
    if (remaining.replace(/\s+/g, '') && omniboxSuggestions.length > 0) {
      handleOmniboxSelect(omniboxSuggestions[Math.min(omniboxActive, omniboxSuggestions.length - 1)]);
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

  /// 분류 단위로 한꺼번에 켜고 끈다. EXTENT 모드는 수치 롤을 하나만 허용하므로
  /// 패널이 그때는 이 버튼을 내보내지 않는다.
  const handleRolesToggle = (roleIds: number[], checked: boolean) => {
    if (isChartLoading) return;
    setCheckedRoles(prev => checked
      ? Array.from(new Set([...prev, ...roleIds]))
      : prev.filter(id => !roleIds.includes(id)));
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
    // 실패를 삼키면, 눌렀는데 목록이 그대로인 이유를 알 수가 없다.
    try {
      await apiService.hidePostFromGroup(Number(selectedGroupId), postId);
      setSelectedPostViewerIds(prev => prev.filter(id => id !== postId));
      setRefreshTrigger(prev => prev + 1);
    } catch {
      alert('소요기록을 제외하지 못했습니다.');
    }
  };

  const handleRestorePost = async (postId: number) => {
    if (!selectedGroupId) return;
    try {
      await apiService.showPostInGroup(Number(selectedGroupId), postId);
      setRefreshTrigger(prev => prev + 1);
    } catch {
      alert('소요기록을 복구하지 못했습니다.');
    }
  };

  /**
   * 지금 보고 있는 시점을 스마트 검색에 붙여 넣을 수 있는 문장으로 복사한다.
   *
   * 두 가지가 고장나 있었다.
   *
   * 1) navigator.clipboard 는 보안 컨텍스트(https 또는 localhost)에서만 있다.
   *    이 화면은 백엔드가 http 로 서빙하므로 사내 IP 로 열면 undefined 이고,
   *    writeText 를 부르는 순간 TypeError 로 조용히 죽었다. 예전 방식
   *    (textarea + execCommand)으로 떨어지게 한다.
   * 2) 조건이 하나라도 안 맞으면 아무 말 없이 return 했다. 누른 사람은
   *    복사가 됐는지 안 됐는지 알 수가 없다. 이유를 알린다.
   */
  const handleCopySearchQuery = async () => {
    if (!selectedFacility || !selectedRoom) {
      alert('먼저 시설과 호실을 고르세요.');
      return;
    }
    if (!currentViewStart) {
      alert('먼저 차트를 불러오세요. 조회된 구간이 있어야 그 시점을 복사할 수 있습니다.');
      return;
    }

    const facName = facilities.find(f => f.id === selectedFacility)?.name || '';
    const roomName = rooms.find(r => r.id === selectedRoom)?.name || '';
    const d = new Date(currentViewStart);
    const query = `${facName} ${roomName} ${d.getMonth() + 1}/${d.getDate()} ${d.getHours().toString().padStart(2, '0')}:${d.getMinutes().toString().padStart(2, '0')}`;

    if (await copyToClipboard(query)) {
      alert(`클립보드에 복사되었습니다:\n${query}`);
    } else {
      // 붙여넣기는 못 해 줘도 무엇을 복사하려 했는지는 보여 준다.
      window.prompt('복사가 막혀 있습니다. 아래 내용을 직접 복사하세요.', query);
    }
  };

  const mainDataSets = chartDataSets.filter(ds => ds.role_name && !isBoolRole(ds.role_id));
  const subDataSets = chartDataSets.filter(ds => ds.role_name && isBoolRole(ds.role_id)); 

  /**
   * 차트가 비어 있다면 그 이유.
   *
   * null 이면 그릴 것이 있다는 뜻이다. 불러오는 중에는 ECharts 가 제 로딩
   * 표시를 내므로 안내를 겹쳐 띄우지 않는다 — 둘이 같이 뜨면 "없다"와
   * "오는 중"이 한 화면에 적히게 된다.
   */
  const emptyReason: EmptyReason | null = (() => {
    if (isChartLoading) return null;
    if (!selectedFacility) return 'pick-facility';
    if (!selectedRoom) return 'pick-room';
    // 호실까지 골랐는데 묶인 항목이 하나도 없으면 고르는 문제가 아니라 설정 문제다.
    if (groups.length === 0 || checkedRoles.length === 0) return 'no-mapping';
    // 요청은 갔는데 이 구간에 기록이 없는 경우.
    if (!chartDataSets.some(ds => ds.data?.length)) return 'no-data';
    return null;
  })();

  // 💡 [UI 핵심 수정] 최상위 컨테이너에 overflowY: 'auto' 적용
  return (
    <div style={{ display: 'flex', flexDirection: 'column', height: '100%', overflowY: 'auto', gap: 12, boxSizing: 'border-box', padding: 24 }}>

      {/* 상단: 차트 + 검색/스코핑 패널 (최소 높이 보장) */}
      <div style={{ display: 'flex', gap: 12, minHeight: 650, flexShrink: 0 }}>

        {/* 왼쪽 차트 영역 */}
        <div style={{ flex: 3, display: 'flex', flexDirection: 'column', gap: 10 }}>
          <TopToolBar showInfo={showMainInfo} showGrid={showMainGrid} targetDate={targetDate} isChartLoading={isChartLoading} onCopy={handleCopySearchQuery} onToggleInfo={() => setShowMainInfo(!showMainInfo)} onToggleGrid={() => setShowMainGrid(!showMainGrid)} onOneHourView={applyOneHourView} onDateChange={setTargetDate} yBuffer={yBuffer} onYBufferChange={setYBuffer} />
          <div className="card" style={{ flex: 2, display: 'flex', flexDirection: 'column', minHeight: 0, padding: 12 }}>
            {emptyReason ? <ChartEmptyState reason={emptyReason} /> : <MainChartViewer echartsRef={mainChartRef} datasets={mainDataSets} roleColors={roleColors} showInfo={showMainInfo} showGrid={showMainGrid} activeGuidelines={activeGuidelines} isLoading={isChartLoading} posts={posts} alarms={alarms} onChartClick={handleChartClick} loadedRange={loadedRangeState} onDataZoomPan={handleZoomCapture} yBuffer={yBuffer} />}
          </div>
          <LowerToolBar showInfo={showSubInfo} showGrid={showSubGrid} onToggleInfo={() => setShowSubInfo(!showSubInfo)} onToggleGrid={() => setShowSubGrid(!showSubGrid)} onSyncTop={() => syncChartDataZoom(mainChartRef, subChartRef)} onSyncSub={() => syncChartDataZoom(subChartRef, mainChartRef)} />
          <div className="card" style={{ flex: 1, display: 'flex', flexDirection: 'column', minHeight: 0, padding: 12 }}>
            {emptyReason ? <ChartEmptyState reason={emptyReason} compact /> : <SubChartViewer echartsRef={subChartRef} datasets={subDataSets} roleColors={roleColors} showInfo={showSubInfo} showGrid={showSubGrid} isLoading={isChartLoading} posts={posts} alarms={alarms} invertedBools={invertedBools} loadedRange={loadedRangeState} />}
          </div>
        </div>

        {/* 오른쪽 패널 영역 */}
        <div style={{ flex: 1, display: 'flex', flexDirection: 'column', gap: 10 }}>
          <SmartOmniboxPanel input={omniboxInput} suggestions={omniboxSuggestions} isChartLoading={isChartLoading} activeIndex={omniboxActive} onActiveIndexChange={setOmniboxActive} onInputChange={setOmniboxInput} onSubmit={handleOmniboxSubmit} onSelect={handleOmniboxSelect} />
          <ScopingPanel mode={mode} scale={scale} facilities={facilities} rooms={rooms} selectedFacility={selectedFacility} selectedRoom={selectedRoom} isChartLoading={isChartLoading} onModeToggle={handleModeToggle} onScaleChange={setScale} onFacilityChange={setSelectedFacility} onRoomChange={setSelectedRoom} onQuickTime={handleQuickTimeSelect} onQuickDay={handleQuickDaySelect} />
          <PostViewerPanel selectedPostIds={selectedPostViewerIds} posts={posts} selectedGroupId={selectedGroupId} onHidePost={handleHidePost} />
          <ChartStatsPanel datasets={mainDataSets} roleColors={roleColors} />
        </div>
      </div>

      {/* 하단: 맵핑 활성화 + 블랙리스트 (내용에 따라 자동 확장) */}
      <div style={{ display: 'flex', gap: 12, flexShrink: 0 }}>
        <MappingActivePanel groups={groups} allRoles={allRoles} roleColors={roleColors} selectedGroupId={selectedGroupId} selectedRoom={selectedRoom} isChartLoading={isChartLoading} checkedRoles={checkedRoles} activeGuidelines={activeGuidelines} invertedBools={invertedBools} openMenuRoleId={openMenuRoleId} onGroupChange={setSelectedGroupId} onRoleToggle={handleRoleToggle} onRolesToggle={handleRolesToggle} singleNumericMode={mode === 'EXTENT'} onMenuToggle={setOpenMenuRoleId} onColorChange={handleColorChange} onGuidelineToggle={handleGuidelineToggle} onInvertToggle={handleInvertToggle} isBoolRole={isBoolRole} />
        <BlacklistPanel hiddenPosts={hiddenPosts} onRestore={handleRestorePost} />
      </div>

    </div>
  );
};