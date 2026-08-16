// src/components/chart/EChartsViewer.tsx
import React, { useEffect } from 'react';
import ReactECharts from 'echarts-for-react';
import * as echarts from 'echarts';

interface Props {
  datasets?: any[];
  roleColors: Record<number, string>;
  // [RQ-Top.1, RQ-Lower.1] 정보 출력 토글용
  showInfo?: boolean;
  // [RQ-Top.3, RQ-Lower.4] 그리드 출력 토글용
  showGrid?: boolean;
  // [RQ-Lower.2, RQ-Lower.3] 시점 동기화를 위한 부모 컴포넌트 참조 전달
  echartsRef?: React.RefObject<ReactECharts | null>; // 👈 '| null' 추가
}

// RQ-3.3: 두 개의 분리된 차트를 묶기 위한 그룹명
const SYNC_GROUP_NAME = 'idcool-chart-group';
echarts.connect(SYNC_GROUP_NAME);

// ==========================================
// 1. 수치형 데이터 전용 메인 차트
// ==========================================
export const MainChartViewer: React.FC<Props> = ({ datasets, roleColors, showInfo = true, showGrid = true, echartsRef }) => {
  useEffect(() => {
    if (echartsRef && echartsRef.current) {
      echartsRef.current.getEchartsInstance().group = SYNC_GROUP_NAME;
    }
  }, [echartsRef]);

  const getOption = () => {
    const seriesData = (datasets || []).map(ds => ({
      name: ds.role_name,
      type: 'line',
      showSymbol: false,
      itemStyle: { color: roleColors[ds.role_id] },
      data: (ds.data || []).map((pt: any) => [new Date(pt.timestamp).getTime(), pt.mean])
    }));

    return {
      // [RQ-Top.1] 정보 출력 토글
      tooltip: { show: showInfo, trigger: 'axis', axisPointer: { type: 'cross' } },
      axisPointer: { link: [{ xAxisIndex: 'all' }] },
      grid: { left: 60, right: 50, top: 30, bottom: 25 },
      // [RQ-Top.3] 그리드 출력 토글 (X축)
      xAxis: { 
        type: 'time', 
        axisLabel: { show: false }, 
        axisTick: { show: false },
        splitLine: { show: showGrid, lineStyle: { color: '#333' } }
      },
      // [RQ-Top.3] 그리드 출력 토글 (Y축)
      yAxis: { 
        type: 'value', 
        name: '수치 (Main)',
        splitLine: { show: showGrid, lineStyle: { color: '#333' } }
      },
      dataZoom: [{ type: 'inside' }],
      series: seriesData
    };
  };

  return <ReactECharts ref={echartsRef} option={getOption()} style={{ height: '100%', width: '100%' }} notMerge={true} />;
};

// ==========================================
// 2. 상태형(BOOL) 데이터 전용 서브 차트
// ==========================================
export const SubChartViewer: React.FC<Props> = ({ datasets, roleColors, showInfo = true, showGrid = true, echartsRef }) => {
  useEffect(() => {
    if (echartsRef && echartsRef.current) {
      echartsRef.current.getEchartsInstance().group = SYNC_GROUP_NAME;
    }
  }, [echartsRef]);

  const getOption = () => {
    const seriesData: any[] = [];
    const boolCategories = (datasets || []).map(ds => ds.role_name);

    (datasets || []).forEach((ds, index) => {
      const mappedData = (ds.data || [])
        .filter((pt: any) => pt.status === true || pt.status === 1 || String(pt.status) === 'true' || pt.mean === 1 || String(pt.mean) === '1')
        .map((pt: any) => [new Date(pt.timestamp).getTime(), index]);

      seriesData.push({
        name: ds.role_name,
        type: 'scatter',
        symbol: 'rect',
        symbolSize: [3, 20],
        itemStyle: { color: roleColors[ds.role_id] },
        data: mappedData
      });
    });

    return {
      // [RQ-Lower.1] 정보 출력 토글
      tooltip: { show: showInfo, trigger: 'axis', axisPointer: { type: 'cross' } },
      grid: { left: 60, right: 50, top: 10, bottom: 25 },
      // [RQ-Lower.4] 그리드 출력 토글 (X축)
      xAxis: { 
        type: 'time',
        splitLine: { show: showGrid, lineStyle: { color: '#333' } }
      },
      yAxis: { 
        type: 'category', 
        name: '상태 (Sub)', 
        data: boolCategories.length > 0 ? boolCategories : ['데이터 없음'],
        // [RQ-Lower.4] 그리드 출력 토글 (Y축)
        splitLine: { show: showGrid, lineStyle: { color: '#444', type: 'dashed' } },
        axisLabel: { color: '#ccc', fontSize: 10 }
      },
      dataZoom: [
        { type: 'inside' },
        { type: 'slider', bottom: 0, height: 20 }
      ],
      series: seriesData
    };
  };

  return <ReactECharts ref={echartsRef} option={getOption()} style={{ height: '100%', width: '100%' }} notMerge={true} />;
};