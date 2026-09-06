// src/components/chart/EChartsViewer.tsx
import React, { useEffect } from 'react';
import ReactECharts from 'echarts-for-react';
import * as echarts from 'echarts';

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
}

const SYNC_GROUP_NAME = 'idcool-chart-group';
echarts.connect(SYNC_GROUP_NAME);

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
export const MainChartViewer: React.FC<Props> = ({ datasets, roleColors, showInfo = true, showGrid = true, echartsRef, activeGuidelines = [], isLoading = false, posts = [], alarms = [], onChartClick, onDataZoomPan: _onDataZoomPan, loadedRange }) => {
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
          seriesItem.markLine = { data: markLineData, symbol: 'none', label: { show: true, position: 'start', distance: [10, -10], formatter: '{b}: {c}', color: color, fontSize: 11, backgroundColor: 'rgba(255, 255, 255, 0.92)', padding: [2, 4], borderRadius: 2 } };
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
        { xAxis: seg.st, postIds: postIds, itemStyle: { color: 'rgba(214, 69, 69, 0.06)' }, label: { show: true, position: 'insideTop', formatter: combinedTitle, color: '#d64545', fontWeight: 'bold', fontSize: 12, backgroundColor: 'rgba(255,255,255,0.9)', padding: [4, 8], borderRadius: 4, lineHeight: 18 } },
        { xAxis: seg.et }
      ];
    });

    const globalLines: any[] = [];
    validPosts.forEach(p => {
      globalLines.push({ xAxis: p.st, label: { show: true, position: 'end', formatter: formatShortTime(p.st), color: '#d64545', fontSize: 10 }, lineStyle: { type: 'solid', color: '#d64545', width: 2 } });
      globalLines.push({ xAxis: p.et, label: { show: true, position: 'end', formatter: formatShortTime(p.et), color: '#d64545', fontSize: 10 }, lineStyle: { type: 'solid', color: '#d64545', width: 2 } });
    });
    alarms.forEach(a => {
      const time = new Date(a.timestamp).getTime();
      globalLines.push({ xAxis: time, label: { show: true, position: 'end', formatter: formatShortTime(time), color: '#0891b2', fontSize: 10 }, lineStyle: { type: 'dashed', color: '#0891b2', width: 2 } });
      globalLines.push({ xAxis: time, label: { show: true, position: 'start', formatter: a.alarm_name, color: '#0891b2', fontSize: 10 }, lineStyle: { type: 'dashed', color: '#0891b2', width: 2 } });
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
      tooltip: { show: showInfo, trigger: 'axis', axisPointer: { type: 'cross' } },
      axisPointer: { link: [{ xAxisIndex: 'all' }] },
      grid: { left: 60, right: 50, top: 40, bottom: 25 },
      xAxis: { 
        type: 'time', 
        min: loadedRange?.start, 
        max: loadedRange?.end,
        axisLabel: { show: false },
        axisTick: { show: false },
        splitLine: { show: showGrid, lineStyle: { color: '#e5e7eb' } }
      },
      yAxis: { type: 'value', name: '수치 (Main)', splitLine: { show: showGrid, lineStyle: { color: '#e5e7eb' } }, scale: true },
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
      globalLines.push({ xAxis: p.st, lineStyle: { type: 'solid', color: '#d64545', width: 2 }, label: { show: false } });
      globalLines.push({ xAxis: p.et, lineStyle: { type: 'solid', color: '#d64545', width: 2 }, label: { show: false } });
    });
    alarms.forEach(a => {
      const time = new Date(a.timestamp).getTime();
      globalLines.push({ xAxis: time, lineStyle: { type: 'dashed', color: '#0891b2', width: 2 }, label: { show: false } });
    });

    const annotationSeries: any = {
      name: 'GlobalAnnotationsSub', type: 'line', xAxisIndex: 0, yAxisIndex: 0, data: [],
      markArea: { silent: true, data: segments.map(seg => [ { xAxis: seg.st, itemStyle: { color: 'rgba(214,69,69,0.06)' } }, { xAxis: seg.et } ])},
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
      tooltip: { show: showInfo, trigger: 'axis', axisPointer: { type: 'cross' } },
      grid: { left: 60, right: 50, top: 10, bottom: 25 },
      xAxis: {
        type: 'time',
        min: loadedRange?.start,
        max: loadedRange?.end,
        splitLine: { show: showGrid, lineStyle: { color: '#e5e7eb' } }
      },
      yAxis: { type: 'category', name: '상태 (Sub)', data: boolCategories.length > 0 ? boolCategories : ['데이터 없음'], splitLine: { show: showGrid, lineStyle: { color: '#e5e7eb', type: 'dashed' } }, axisLabel: { color: '#5b6b73', fontSize: 10 } },
      dataZoom: [{ type: 'inside', filterMode: 'empty' }, { type: 'slider', bottom: 0, height: 20, filterMode: 'empty' }],
      series: seriesData
    }; 
  };

  return <ReactECharts ref={echartsRef as any} option={getOption()} showLoading={isLoading} style={{ height: '100%', width: '100%' }} notMerge={true} />; 
};