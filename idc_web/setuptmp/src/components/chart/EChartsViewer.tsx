// src/components/chart/EChartsViewer.tsx
import React, { useRef, useEffect } from 'react';
import ReactECharts from 'echarts-for-react';
import * as echarts from 'echarts';

interface Props {
  datasets?: any[];
  roleColors: Record<number, string>;
}

const SYNC_GROUP_NAME = 'idcool-chart-group';
echarts.connect(SYNC_GROUP_NAME);

// ==========================================
// 1. 수치형 데이터 전용 메인 차트
// ==========================================
export const MainChartViewer: React.FC<Props> = ({ datasets, roleColors }) => {
  const chartRef = useRef<ReactECharts>(null);

  useEffect(() => {
    if (chartRef.current) {
      chartRef.current.getEchartsInstance().group = SYNC_GROUP_NAME;
    }
  }, []);

  const getOption = () => {
    const seriesData = (datasets || []).map(ds => ({
      name: ds.role_name,
      type: 'line',
      showSymbol: false,
      itemStyle: { color: roleColors[ds.role_id] },
      data: (ds.data || []).map((pt: any) => [new Date(pt.timestamp).getTime(), pt.mean])
    }));

    return {
      tooltip: { trigger: 'axis', axisPointer: { type: 'cross' } },
      axisPointer: { link: [{ xAxisIndex: 'all' }] },
      grid: { left: 60, right: 50, top: 30, bottom: 25 },
      xAxis: { type: 'time', axisLabel: { show: false }, axisTick: { show: false } },
      yAxis: { type: 'value', name: '수치 (Main)' },
      dataZoom: [{ type: 'inside' }],
      series: seriesData
    };
  };

  return <ReactECharts ref={chartRef} option={getOption()} style={{ height: '100%', width: '100%' }} notMerge={true} />;
};

// ==========================================
// 2. 상태형(BOOL) 데이터 전용 서브 차트
// ==========================================
export const SubChartViewer: React.FC<Props> = ({ datasets, roleColors }) => {
  const chartRef = useRef<ReactECharts>(null);

  useEffect(() => {
    if (chartRef.current) {
      chartRef.current.getEchartsInstance().group = SYNC_GROUP_NAME;
    }
  }, []);

  const getOption = () => {
    const seriesData: any[] = [];
    const boolCategories = (datasets || []).map(ds => ds.role_name);

    (datasets || []).forEach((ds, index) => {
      // 💡 다양한 True 상태값 (1, "1", "true", true) 필터링
      const mappedData = (ds.data || [])
        .filter((pt: any) => 
          pt.status === true || pt.status === 1 || String(pt.status) === 'true' || 
          pt.mean === 1 || String(pt.mean) === '1'
        )
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
      tooltip: { trigger: 'axis', axisPointer: { type: 'cross' } },
      grid: { left: 60, right: 50, top: 10, bottom: 25 },
      xAxis: { type: 'time' },
      // 💡 ECharts 에러 방어: 카테고리가 0개일 때 빈 배열 대신 placeholder 제공
      yAxis: { 
        type: 'category', 
        name: '상태 (Sub)', 
        data: boolCategories.length > 0 ? boolCategories : ['데이터 없음'],
        splitLine: { show: true, lineStyle: { color: '#333' } },
        axisLabel: { color: '#ccc', fontSize: 10 }
      },
      dataZoom: [
        { type: 'inside' },
        { type: 'slider', bottom: 0, height: 20 }
      ],
      series: seriesData
    };
  };

  return <ReactECharts ref={chartRef} option={getOption()} style={{ height: '100%', width: '100%' }} notMerge={true} />;
};