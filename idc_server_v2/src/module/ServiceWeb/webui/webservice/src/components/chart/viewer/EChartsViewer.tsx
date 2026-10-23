// src/components/chart/EChartsViewer.tsx
import React, { useEffect } from 'react';
import ReactECharts from 'echarts-for-react';
import * as echarts from 'echarts';
import { useTheme } from '../../../services/theme';

interface Props {
  datasets?: any[];
  roleColors: Record<number, string>;
  showInfo?: boolean;
  showGrid?: boolean;
  echartsRef?: React.RefObject<ReactECharts | null>;
  activeGuidelines?: number[]; 
  isLoading?: boolean; 
  posts?: any[];
  alarms?: any[];
  onChartClick?: (type: 'post' | 'alarm', id: number | number[]) => void;
  onDataZoomPan?: (startVal: number, endVal: number) => void;
  loadedRange?: { start: number; end: number } | null;
  // 💡 [신규] 반전된 상태를 출력할 BOOL 롤 ID 목록
  invertedBools?: number[];
  /** y축 위아래로 둘 여백. 'auto' 는 구간 폭의 10%, 숫자는 그 값만큼, 0은 딱 맞춤. */
  yBuffer?: number | 'auto';
}


/**
 * 차트가 쓸 색.
 *
 * ECharts 는 캔버스에 직접 그려서 CSS 변수를 모른다. 그래서 그릴 때마다 지금
 * 값을 읽어다 넘긴다. 전에는 '#e5e7eb' 처럼 밝은 테마 색이 박혀 있었는데,
 * 어두운 테마에서는 눈금선이 안 보이고 글자 배경만 흰 네모로 남는다.
 */
const chartPalette = (isDark: boolean) => {
  const read = (name: string, fallback: string) => {
    const v = getComputedStyle(document.documentElement).getPropertyValue(name).trim();
    return v || fallback;
  };
  return {
    grid: read('--border', isDark ? '#36454f' : '#e5e7eb'),
    axisText: read('--text-secondary', isDark ? '#9fb0bc' : '#5b6b73'),
    // 차트 위에 얹는 글자의 받침. 선 위에 바로 적으면 선과 겹쳐 읽히지 않는다.
    labelBack: isDark ? 'rgba(34, 48, 64, 0.92)' : 'rgba(255, 255, 255, 0.92)',
    mark: read('--error', isDark ? '#ff6b6b' : '#d64545'),
    markFill: isDark ? 'rgba(255, 107, 107, 0.10)' : 'rgba(214, 69, 69, 0.06)',
    alarm: isDark ? '#4dd0c7' : '#0891b2',
    // 말풍선은 ECharts 가 기본으로 흰 바탕에 어두운 글씨를 쓴다. 어두운 화면
    // 한가운데에 흰 상자가 뜨면 거기만 도려낸 것처럼 보인다.
    tipBack: read('--surface', isDark ? '#223040' : '#ffffff'),
    tipText: read('--text', isDark ? '#e9eef3' : '#16232a'),
  };
};

const SYNC_GROUP_NAME = 'idcool-chart-group';
echarts.connect(SYNC_GROUP_NAME);

/**
 * 툴팁에 찍을 값.
 *
 * 온도는 DB 에 REAL 로 들어 있어 그대로 내보내면 -20.299999237060547 처럼
 * 뜬다. 현장에서 의미 있는 자리는 소수점 아래 한두 자리뿐이라, 둘째 자리에서
 * 끊고 뒤에 남는 0 은 지운다 (-20.3, 12.45, 380).
 */
const round3 = (n: number) => Number(n.toFixed(3));

const formatValue = (v: any) => {
  const n = Number(Array.isArray(v) ? v[1] : v);
  if (v == null || Number.isNaN(n)) return '-';
  // `|| 0` folds -0 into 0 so tiny negatives don't print as "-0".
  return String(Number(n.toFixed(2)) || 0);
};

const formatShortTime = (ts: number) => {
  const d = new Date(ts);
  return `${(d.getMonth() + 1).toString().padStart(2, '0')}/${d.getDate().toString().padStart(2, '0')} ${d.getHours().toString().padStart(2, '0')}:${d.getMinutes().toString().padStart(2, '0')}`;
};

const generatePostSegments = (validPosts: any[]) => {
  if (!validPosts || validPosts.length === 0) return [];
  const points = new Set<number>();
  validPosts.forEach(p => { points.add(p.st); points.add(p.et); });
  const sortedPoints = Array.from(points).sort((a, b) => a - b);
  const segments: any[] = [];
  
  for (let i = 0; i < sortedPoints.length - 1; i++) {
    const segSt = sortedPoints[i];
    const segEt = sortedPoints[i + 1];
    if (segSt === segEt) continue;
    const activePosts = validPosts.filter(p => p.st <= segSt && p.et >= segEt);
    if (activePosts.length > 0) segments.push({ st: segSt, et: segEt, activePosts });
  }
  return segments;
};

// ==========================================
// 1. 수치형 데이터 전용 메인 차트
// ==========================================
export const MainChartViewer: React.FC<Props> = ({ datasets, roleColors, showInfo = true, showGrid = true, echartsRef, activeGuidelines = [], isLoading = false, posts = [], alarms = [], onChartClick, onDataZoomPan: _onDataZoomPan, loadedRange, yBuffer = 'auto' }) => {
  // 테마가 바뀌면 이 값이 바뀌고, 그래서 차트가 다시 그려진다.
  const { resolved } = useTheme();
  const palette = chartPalette(resolved === 'dark');

  useEffect(() => {
    if (echartsRef && echartsRef.current) {
      const instance = echartsRef.current.getEchartsInstance();
      instance.group = SYNC_GROUP_NAME; 
      instance.off('click');
      instance.on('click', (params: any) => {
        if (params.seriesName === 'GlobalAnnotations' && params.data && params.data.postIds) {
          if (onChartClick) onChartClick('post', params.data.postIds);
        }
      });
    }
  }, [echartsRef, onChartClick]);

  // 'auto' 는 구간 폭에 비례해서 둔다. 고정값은 온도(-22~-16)처럼 폭이 좁은
  // 그래프에서는 선을 납작하게 만들고, Hz·전압처럼 폭이 넓은 쪽에서는 티도 안 난다.
  const pad = (value: any) =>
    yBuffer === 'auto' ? Math.max((value.max - value.min) * 0.1, 0.1) : (yBuffer as number);

  const getOption = () => {
    const seriesData: any[] = (datasets || []).map(ds => {
      const color = roleColors[ds.role_id];
      const seriesItem: any = {
        name: ds.display_name || ds.role_name,
        type: 'line',
        showSymbol: false,
        itemStyle: { color: color },
        data: (ds.data || []).map((pt: any) => [new Date(pt.timestamp).getTime(), pt.mean])
      };
      if (activeGuidelines.includes(ds.role_id)) {
        const markLineData: any[] = [];
        if (ds.target_value != null) markLineData.push({ yAxis: Number(ds.target_value), name: 'Target', lineStyle: { type: 'solid', color: color, width: 2 } });
        if (ds.target_low_limit != null) markLineData.push({ yAxis: Number(ds.target_low_limit), name: 'Low', lineStyle: { type: 'dashed', color: color, width: 1.5 } });
        if (ds.target_high_limit != null) markLineData.push({ yAxis: Number(ds.target_high_limit), name: 'High', lineStyle: { type: 'dashed', color: color, width: 1.5 } });
        if (markLineData.length > 0) {
          seriesItem.markLine = { data: markLineData, symbol: 'none', label: { show: true, position: 'start', distance: [10, -10], formatter: (p: any) => `${p.name}: ${formatValue(p.value)}`, color: color, fontSize: 11, backgroundColor: palette.labelBack, padding: [2, 4], borderRadius: 2 } };
        }
      }
      return seriesItem;
    });

    const validPosts = posts.filter(p => p.start_date && p.end_date).map(p => {
      const st = new Date(p.start_date).getTime();
      let et = new Date(p.end_date).getTime();
      if (st === et) et += 60 * 60 * 1000;
      return { ...p, st, et };
    });

    const segments = generatePostSegments(validPosts);
    const postAreas = segments.map(seg => {
      const combinedTitle = seg.activePosts.map((p: any) => p.title).join('\n');
      const postIds = seg.activePosts.map((p: any) => p.id);
      return [
        { xAxis: seg.st, postIds: postIds, itemStyle: { color: palette.markFill }, label: { show: true, position: 'insideTop', formatter: combinedTitle, color: palette.mark, fontWeight: 'bold', fontSize: 12, backgroundColor: palette.labelBack, padding: [4, 8], borderRadius: 4, lineHeight: 18 } },
        { xAxis: seg.et }
      ];
    });

    const globalLines: any[] = [];
    validPosts.forEach(p => {
      globalLines.push({ xAxis: p.st, label: { show: true, position: 'end', formatter: formatShortTime(p.st), color: palette.mark, fontSize: 10 }, lineStyle: { type: 'solid', color: palette.mark, width: 2 } });
      globalLines.push({ xAxis: p.et, label: { show: true, position: 'end', formatter: formatShortTime(p.et), color: palette.mark, fontSize: 10 }, lineStyle: { type: 'solid', color: palette.mark, width: 2 } });
    });
    alarms.forEach(a => {
      const time = new Date(a.timestamp).getTime();
      globalLines.push({ xAxis: time, label: { show: true, position: 'end', formatter: formatShortTime(time), color: palette.alarm, fontSize: 10 }, lineStyle: { type: 'dashed', color: palette.alarm, width: 2 } });
      globalLines.push({ xAxis: time, label: { show: true, position: 'start', formatter: a.alarm_name, color: palette.alarm, fontSize: 10 }, lineStyle: { type: 'dashed', color: palette.alarm, width: 2 } });
    });

    const annotationSeries: any = { name: 'GlobalAnnotations', type: 'line', xAxisIndex: 0, yAxisIndex: 0, data: [], markArea: { silent: false, data: postAreas }, markLine: { silent: false, symbol: ['none', 'none'], z: 10, data: globalLines } };
    seriesData.push(annotationSeries);

    if (loadedRange) {
      const oneYear = 365 * 24 * 60 * 60 * 1000;
      seriesData.push({
        name: 'InvisibleBoundary', type: 'line', itemStyle: { color: 'transparent' }, lineStyle: { width: 0 }, symbolSize: 0, showSymbol: false, tooltip: { show: false },
        data: [ [loadedRange.start - oneYear, 0], [loadedRange.end + oneYear, 0] ]
      });
    }

    return {
      tooltip: { show: showInfo, trigger: 'axis', axisPointer: { type: 'cross' }, valueFormatter: formatValue, backgroundColor: palette.tipBack, borderColor: palette.grid, textStyle: { color: palette.tipText } },
      axisPointer: { link: [{ xAxisIndex: 'all' }] },
      grid: { left: 60, right: 50, top: 40, bottom: 25 },
      xAxis: { 
        type: 'time', 
        min: loadedRange?.start, 
        max: loadedRange?.end,
        axisLabel: { show: false },
        axisTick: { show: false },
        splitLine: { show: showGrid, lineStyle: { color: palette.grid } }
      },
      // scale: true 는 데이터에 딱 맞춰 눈금을 잡아, 선이 위아래 테두리에 붙어
      // 버린다. 위아래로 여백을 둬야 꼭대기와 바닥이 보인다. 여백 폭은 툴바에서
      // 조절한다 (0이면 예전과 같은 동작).
      yAxis: {
        type: 'value',
        name: '수치 (Main)',
        splitLine: { show: showGrid, lineStyle: { color: palette.grid } },
        scale: true,
        // 여백을 준 값도 반올림해서 넘긴다. 그대로 넘기면 축 끝에
        // 3302.2709999084473 같은 숫자가 그대로 찍힌다.
        min: yBuffer === 0 ? undefined : (value: any) => round3(value.min - pad(value)),
        max: yBuffer === 0 ? undefined : (value: any) => round3(value.max + pad(value)),
        axisLabel: { formatter: formatValue, color: palette.axisText },
        // The cross pointer prints its own label; without this it shows the raw float.
        axisPointer: { label: { formatter: (p: any) => formatValue(p.value) } },
        nameTextStyle: { color: palette.axisText },
      },
      dataZoom: [{ type: 'inside', filterMode: 'empty' }],
      series: seriesData
    }; 
  };

  return <ReactECharts ref={echartsRef as any} option={getOption()} showLoading={isLoading} style={{ height: '100%', width: '100%' }} notMerge={true} />; 
};

// ==========================================
// 2. 상태형(BOOL) 데이터 전용 서브 차트
// ==========================================
export const SubChartViewer: React.FC<Props> = ({ datasets, roleColors, showInfo = true, showGrid = true, echartsRef, isLoading = false, posts = [], alarms = [], loadedRange, invertedBools = [] }) => {
  // 테마가 바뀌면 이 값이 바뀌고, 그래서 차트가 다시 그려진다.
  const { resolved } = useTheme();
  const palette = chartPalette(resolved === 'dark');

  useEffect(() => {
    if (echartsRef && echartsRef.current) echartsRef.current.getEchartsInstance().group = SYNC_GROUP_NAME; 
  }, [echartsRef]);

  const getOption = () => {
    const seriesData: any[] = [];
    const boolCategories = (datasets || []).map(ds => ds.display_name || ds.role_name);
     

    (datasets || []).forEach((ds, index) => {
      // 💡 [신규] 반전 설정 여부 확인
      const isInverted = invertedBools.includes(ds.role_id);

      const mappedData = (ds.data || [])
        .filter((pt: any) => {
          const isTrue = pt.status === true || pt.status === 1 || String(pt.status) === 'true' || pt.mean === 1 || String(pt.mean) === '1';
          return isInverted ? !isTrue : isTrue; // 상태 반전 적용
        })
        .map((pt: any) => [new Date(pt.timestamp).getTime(), index]); 


      seriesData.push({ name: ds.display_name || ds.role_name, type: 'scatter', symbol: 'rect', symbolSize: [6, 20], itemStyle: { color: roleColors[ds.role_id] }, data: mappedData }); 
    });

    const validPosts = posts.filter(p => p.start_date && p.end_date).map(p => {
      const st = new Date(p.start_date).getTime();
      let et = new Date(p.end_date).getTime();
      if (st === et) et += 60 * 60 * 1000;
      return { ...p, st, et };
    });
    
    const segments = generatePostSegments(validPosts);
    const globalLines: any[] = [];
    
    validPosts.forEach(p => {
      globalLines.push({ xAxis: p.st, lineStyle: { type: 'solid', color: palette.mark, width: 2 }, label: { show: false } });
      globalLines.push({ xAxis: p.et, lineStyle: { type: 'solid', color: palette.mark, width: 2 }, label: { show: false } });
    });
    alarms.forEach(a => {
      const time = new Date(a.timestamp).getTime();
      globalLines.push({ xAxis: time, lineStyle: { type: 'dashed', color: palette.alarm, width: 2 }, label: { show: false } });
    });

    const annotationSeries: any = {
      name: 'GlobalAnnotationsSub', type: 'line', xAxisIndex: 0, yAxisIndex: 0, data: [],
      markArea: { silent: true, data: segments.map(seg => [ { xAxis: seg.st, itemStyle: { color: palette.markFill } }, { xAxis: seg.et } ])},
      markLine: { symbol: ['none', 'none'], z: 10, silent: true, data: globalLines }
    };
    seriesData.push(annotationSeries);

    if (loadedRange) {
      const oneYear = 365 * 24 * 60 * 60 * 1000;
      seriesData.push({
        name: 'InvisibleBoundary', type: 'line', itemStyle: { color: 'transparent' }, lineStyle: { width: 0 }, symbolSize: 0, showSymbol: false, tooltip: { show: false },
        data: [ [loadedRange.start - oneYear, 0], [loadedRange.end + oneYear, 0] ]
      });
    }

    return {
      tooltip: { show: showInfo, trigger: 'axis', axisPointer: { type: 'cross' }, valueFormatter: formatValue, backgroundColor: palette.tipBack, borderColor: palette.grid, textStyle: { color: palette.tipText } },
      grid: { left: 60, right: 50, top: 10, bottom: 25 },
      xAxis: {
        type: 'time',
        min: loadedRange?.start,
        max: loadedRange?.end,
        splitLine: { show: showGrid, lineStyle: { color: palette.grid } }
      },
      yAxis: { type: 'category', name: '상태 (Sub)', nameTextStyle: { color: palette.axisText }, data: boolCategories.length > 0 ? boolCategories : ['데이터 없음'], splitLine: { show: showGrid, lineStyle: { color: palette.grid, type: 'dashed' } }, axisLabel: { color: palette.axisText, fontSize: 10 } },
      dataZoom: [{ type: 'inside', filterMode: 'empty' }, { type: 'slider', bottom: 0, height: 20, filterMode: 'empty' }],
      series: seriesData
    }; 
  };

  return <ReactECharts ref={echartsRef as any} option={getOption()} showLoading={isLoading} style={{ height: '100%', width: '100%' }} notMerge={true} />; 
};