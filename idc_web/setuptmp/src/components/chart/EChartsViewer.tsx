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
  // [RQ-6.4] 가이드라인 활성화된 포인트 롤 ID 배열
  activeGuidelines?: number[]; 
}

const SYNC_GROUP_NAME = 'idcool-chart-group';
echarts.connect(SYNC_GROUP_NAME);

// ==========================================
// 1. 수치형 데이터 전용 메인 차트
// ==========================================
export const MainChartViewer: React.FC<Props> = ({ datasets, roleColors, showInfo = true, showGrid = true, echartsRef, activeGuidelines = [] }) => {
  useEffect(() => {
    if (echartsRef && echartsRef.current) {
      echartsRef.current.getEchartsInstance().group = SYNC_GROUP_NAME;
    }
  }, [echartsRef]);

  const getOption = () => {
    const seriesData = (datasets || []).map(ds => {
      const color = roleColors[ds.role_id];
      const seriesItem: any = {
        name: ds.role_name,
        type: 'line',
        showSymbol: false,
        itemStyle: { color: color },
        data: (ds.data || []).map((pt: any) => [new Date(pt.timestamp).getTime(), pt.mean])
      };

      // [RQ-6.4] 활성화된 가이드라인 렌더링
      if (activeGuidelines.includes(ds.role_id)) {
        const markLineData: any[] = [];
        
        if (ds.target_value != null) {
          markLineData.push({ yAxis: Number(ds.target_value), name: 'Target', lineStyle: { type: 'solid', color: color, width: 2 } });
        }
        if (ds.target_low_limit != null) {
          markLineData.push({ yAxis: Number(ds.target_low_limit), name: 'Low', lineStyle: { type: 'dashed', color: color, width: 1.5 } });
        }
        if (ds.target_high_limit != null) {
          markLineData.push({ yAxis: Number(ds.target_high_limit), name: 'High', lineStyle: { type: 'dashed', color: color, width: 1.5 } });
        }

        if (markLineData.length > 0) {
          seriesItem.markLine = {
            data: markLineData,
            symbol: 'none',
            label: { 
              show: true, 
              position: 'start', // 💡 좌측(시작점)에 배치
              distance: [10, -10], // 선 바로 위쪽/좌측 안쪽으로 살짝 띄움
              formatter: '{b}: {c}', 
              color: color,
              fontSize: 11,
              backgroundColor: 'rgba(30, 30, 30, 0.7)', // 💡 배경 그리드와 겹칠 때 글자가 또렷하게 보이도록 반투명 배경 추가
              padding: [2, 4],
              borderRadius: 2
            }
          };
        }
      }

      return seriesItem;
    });

    return {
      tooltip: { show: showInfo, trigger: 'axis', axisPointer: { type: 'cross' } },
      axisPointer: { link: [{ xAxisIndex: 'all' }] },
      grid: { left: 60, right: 50, top: 30, bottom: 25 },
      xAxis: { 
        type: 'time', 
        axisLabel: { show: false }, 
        axisTick: { show: false },
        splitLine: { show: showGrid, lineStyle: { color: '#333' } }
      },
      yAxis: { 
        type: 'value', 
        name: '수치 (Main)',
        splitLine: { show: showGrid, lineStyle: { color: '#333' } },
        // [RQ-6.4] 가이드라인이 차트 범위를 벗어나도 렌더링되도록 스케일 조정 방지 풀기
        scale: true 
      },
      dataZoom: [{ type: 'inside' }],
      series: seriesData
    };
  };

  return <ReactECharts ref={echartsRef as any} option={getOption()} style={{ height: '100%', width: '100%' }} notMerge={true} />;
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
      tooltip: { show: showInfo, trigger: 'axis', axisPointer: { type: 'cross' } },
      grid: { left: 60, right: 50, top: 10, bottom: 25 },
      xAxis: { 
        type: 'time',
        splitLine: { show: showGrid, lineStyle: { color: '#333' } }
      },
      yAxis: { 
        type: 'category', 
        name: '상태 (Sub)', 
        data: boolCategories.length > 0 ? boolCategories : ['데이터 없음'],
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

  return <ReactECharts ref={echartsRef as any} option={getOption()} style={{ height: '100%', width: '100%' }} notMerge={true} />;
};