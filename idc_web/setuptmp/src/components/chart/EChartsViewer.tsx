// src/components/chart/EChartsViewer.tsx
import React, { useRef } from 'react';
import ReactECharts from 'echarts-for-react';
import * as echarts from 'echarts';

interface Props {
  datasets?: any[];
}

export const EChartsViewer: React.FC<Props> = ({ datasets }) => {
  const chartRef = useRef<ReactECharts>(null);

  const getOption = () => {
    const seriesData: any[] = [];
    
    datasets?.forEach(ds => {
      // 롤 이름이나 데이터 구조로 bool 데이터를 식별
      const isBool = ds.role_name.toLowerCase().includes('bool') || (ds.data[0] && ds.data[0].hasOwnProperty('status'));
      
      const mappedData = ds.data.map((pt: any) => {
        const time = new Date(pt.timestamp).getTime();
        const val = isBool ? (pt.status ? 1 : 0) : pt.mean;
        return [time, val];
      });

      if (isBool) {
        seriesData.push({
          name: ds.role_name,
          type: 'scatter',
          xAxisIndex: 1, // Sub Chart 영역
          yAxisIndex: 1,
          symbolSize: 8,
          data: mappedData
        });
      } else {
        seriesData.push({
          name: ds.role_name,
          type: 'line',
          xAxisIndex: 0, // Main Chart 영역
          yAxisIndex: 0,
          showSymbol: false,
          data: mappedData
        });
      }
    });

    return {
      tooltip: {
        trigger: 'axis',
        axisPointer: { type: 'cross' },
      },
      axisPointer: {
        link: [{ xAxisIndex: 'all' }],
        label: { backgroundColor: '#777' }
      },
      grid: [
        { left: 50, right: 50, top: 40, bottom: '35%' }, // Main Chart
        { left: 50, right: 50, top: '75%', height: '20%' } // Sub Chart
      ],
      xAxis: [
        { type: 'time', gridIndex: 0, axisLabel: { show: false }, axisLine: { show: false }, axisTick: { show: false } },
        { type: 'time', gridIndex: 1 }
      ],
      yAxis: [
        { type: 'value', gridIndex: 0, name: '수치' },
        { type: 'value', gridIndex: 1, name: '상태', splitLine: { show: false }, min: -0.5, max: 1.5, axisLabel: { show: false } }
      ],
      dataZoom: [
        { type: 'inside', xAxisIndex: [0, 1] },
        { type: 'slider', xAxisIndex: [0, 1], bottom: 0, height: 20 }
      ],
      series: seriesData
    };
  };

  return (
    <ReactECharts
      ref={chartRef}
      option={getOption()}
      style={{ height: '100%', width: '100%' }}
      notMerge={false} 
    />
  );
};