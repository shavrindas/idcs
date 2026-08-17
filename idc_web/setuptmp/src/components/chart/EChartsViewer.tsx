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
  onChartClick?: (type: 'post' | 'alarm', id: number) => void;
}

const SYNC_GROUP_NAME = 'idcool-chart-group';
echarts.connect(SYNC_GROUP_NAME);

// ==========================================
// 1. 수치형 데이터 전용 메인 차트
// ==========================================
export const MainChartViewer: React.FC<Props> = ({ datasets, roleColors, showInfo = true, showGrid = true, echartsRef, activeGuidelines = [], isLoading = false, posts = [], alarms = [], onChartClick }) => {
  useEffect(() => {
    if (echartsRef && echartsRef.current) {
      const instance = echartsRef.current.getEchartsInstance();
      instance.group = SYNC_GROUP_NAME; 
      
      instance.off('click');
      instance.on('click', (params: any) => {
        if (params.seriesName === 'GlobalAnnotations' && params.data && params.data.postId) {
          if (onChartClick) onChartClick('post', params.data.postId);
        }
      });
    }
  }, [echartsRef, onChartClick]);

  const getOption = () => {
    const seriesData: any[] = (datasets || []).map(ds => {
      const color = roleColors[ds.role_id];
      const seriesItem: any = {
        name: ds.role_name, type: 'line', showSymbol: false, itemStyle: { color: color },
        data: (ds.data || []).map((pt: any) => [new Date(pt.timestamp).getTime(), pt.mean])
      }; 

      if (activeGuidelines.includes(ds.role_id)) {
        const markLineData: any[] = [];
        if (ds.target_value != null) markLineData.push({ yAxis: Number(ds.target_value), name: 'Target', lineStyle: { type: 'solid', color: color, width: 2 } });
        if (ds.target_low_limit != null) markLineData.push({ yAxis: Number(ds.target_low_limit), name: 'Low', lineStyle: { type: 'dashed', color: color, width: 1.5 } });
        if (ds.target_high_limit != null) markLineData.push({ yAxis: Number(ds.target_high_limit), name: 'High', lineStyle: { type: 'dashed', color: color, width: 1.5 } });

        if (markLineData.length > 0) {
          seriesItem.markLine = {
            data: markLineData, symbol: 'none',
            label: { show: true, position: 'start', distance: [10, -10], formatter: '{b}: {c}', color: color, fontSize: 11, backgroundColor: 'rgba(30, 30, 30, 0.7)', padding: [2, 4], borderRadius: 2 }
          };
        }
      }
      return seriesItem;
    });

    // 💡 [개선] 소요기록(Post)과 알람(Alarm)을 동시에 완벽하게 처리하는 어노테이션 시리즈
    const validPosts = posts.filter(p => p.start_date && p.end_date);
    
    // 1. 소요기록 영역(배경색)
    const postAreas = validPosts.map(p => [
      { xAxis: new Date(p.start_date).getTime(), postId: p.id, itemStyle: { color: 'rgba(255, 0, 0, 0.05)' } },
      { xAxis: new Date(p.end_date).getTime() }
    ]);

    // 2. 소요기록 경계선(시작/끝) 및 알람 선(점선) 통합
    const globalLines: any[] = [];
    
    // 포스트 라인 (실선)
    validPosts.forEach(p => {
      const st = new Date(p.start_date).getTime();
      const et = new Date(p.end_date).getTime();
      globalLines.push({ xAxis: st, postId: p.id, label: { show: true, position: 'end', formatter: '시작: ' + p.title, color: '#ff4d4f' }, lineStyle: { type: 'solid', color: '#ff4d4f', width: 2 } });
      globalLines.push({ xAxis: et, postId: p.id, label: { show: true, position: 'start', formatter: '종료: ' + p.title, color: '#ff4d4f' }, lineStyle: { type: 'solid', color: '#ff4d4f', width: 2 } });
    });

    // 알람 라인 (점선)
    alarms.forEach(a => {
      const time = new Date(a.timestamp).getTime();
      const timeStr = new Date(time).toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' });
      globalLines.push({ xAxis: time, label: { show: true, position: 'end', formatter: timeStr, color: 'cyan' }, lineStyle: { type: 'dashed', color: 'cyan', width: 2 } });
      globalLines.push({ xAxis: time, label: { show: true, position: 'start', formatter: a.alarm_name, color: 'cyan' }, lineStyle: { type: 'dashed', color: 'cyan', width: 2 } });
    });

    const annotationSeries: any = {
      name: 'GlobalAnnotations',
      type: 'line', xAxisIndex: 0, yAxisIndex: 0, data: [], 
      markArea: { silent: false, data: postAreas },
      markLine: { silent: false, symbol: ['none', 'none'], z: 10, data: globalLines }
    };
    seriesData.push(annotationSeries);

    return {
      tooltip: { show: showInfo, trigger: 'axis', axisPointer: { type: 'cross' } },
      axisPointer: { link: [{ xAxisIndex: 'all' }] },
      grid: { left: 60, right: 50, top: 40, bottom: 25 }, // Top 여백 살짝 증가
      xAxis: { type: 'time', axisLabel: { show: false }, axisTick: { show: false }, splitLine: { show: showGrid, lineStyle: { color: '#333' } } },
      yAxis: { type: 'value', name: '수치 (Main)', splitLine: { show: showGrid, lineStyle: { color: '#333' } }, scale: true },
      dataZoom: [{ type: 'inside' }],
      series: seriesData
    }; 
  };

  return <ReactECharts ref={echartsRef as any} option={getOption()} showLoading={isLoading} style={{ height: '100%', width: '100%' }} notMerge={true} />; 
};

// ==========================================
// 2. 상태형(BOOL) 데이터 전용 서브 차트
// ==========================================
export const SubChartViewer: React.FC<Props> = ({ datasets, roleColors, showInfo = true, showGrid = true, echartsRef, isLoading = false, posts = [], alarms = [] }) => {
  useEffect(() => {
    if (echartsRef && echartsRef.current) echartsRef.current.getEchartsInstance().group = SYNC_GROUP_NAME; 
  }, [echartsRef]);

  const getOption = () => {
    const seriesData: any[] = [];
    const boolCategories = (datasets || []).map(ds => ds.role_name); 

    (datasets || []).forEach((ds, index) => {
      const mappedData = (ds.data || [])
        .filter((pt: any) => pt.status === true || pt.status === 1 || String(pt.status) === 'true' || pt.mean === 1 || String(pt.mean) === '1')
        .map((pt: any) => [new Date(pt.timestamp).getTime(), index]); 

      seriesData.push({
        name: ds.role_name, type: 'scatter', symbol: 'rect', symbolSize: [3, 20], itemStyle: { color: roleColors[ds.role_id] }, data: mappedData
      }); 
    });

    const validPosts = posts.filter(p => p.start_date && p.end_date);
    const globalLines: any[] = [];
    
    validPosts.forEach(p => {
      const st = new Date(p.start_date).getTime();
      const et = new Date(p.end_date).getTime();
      globalLines.push({ xAxis: st, lineStyle: { type: 'solid', color: '#ff4d4f', width: 2 }, label: { show: false } });
      globalLines.push({ xAxis: et, lineStyle: { type: 'solid', color: '#ff4d4f', width: 2 }, label: { show: false } });
    });
    alarms.forEach(a => {
      const time = new Date(a.timestamp).getTime();
      globalLines.push({ xAxis: time, lineStyle: { type: 'dashed', color: 'cyan', width: 2 }, label: { show: false } });
    });

    const annotationSeries: any = {
      name: 'GlobalAnnotationsSub', type: 'line', xAxisIndex: 0, yAxisIndex: 0, data: [],
      markArea: { silent: true, data: validPosts.map(p => [ { xAxis: new Date(p.start_date).getTime(), itemStyle: { color: 'rgba(255,0,0,0.05)' } }, { xAxis: new Date(p.end_date).getTime() } ]) },
      markLine: { symbol: ['none', 'none'], z: 10, silent: true, data: globalLines }
    };
    seriesData.push(annotationSeries);

    return {
      tooltip: { show: showInfo, trigger: 'axis', axisPointer: { type: 'cross' } },
      grid: { left: 60, right: 50, top: 10, bottom: 25 },
      xAxis: { type: 'time', splitLine: { show: showGrid, lineStyle: { color: '#333' } } },
      yAxis: { 
        type: 'category', name: '상태 (Sub)', 
        data: boolCategories.length > 0 ? boolCategories : ['데이터 없음'],
        splitLine: { show: showGrid, lineStyle: { color: '#444', type: 'dashed' } },
        axisLabel: { color: '#ccc', fontSize: 10 }
      },
      dataZoom: [{ type: 'inside' }, { type: 'slider', bottom: 0, height: 20 }],
      series: seriesData
    }; 
  };

  return <ReactECharts ref={echartsRef as any} option={getOption()} showLoading={isLoading} style={{ height: '100%', width: '100%' }} notMerge={true} />; 
};