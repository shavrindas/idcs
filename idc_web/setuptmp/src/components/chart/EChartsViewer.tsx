// src/components/chart/EChartsViewer.tsx
import React, { useRef, useEffect } from 'react';
import ReactECharts from 'echarts-for-react';
import * as echarts from 'echarts';

interface Props {
  // 나중에 실제 데이터를 받을 프롭스
  mainData?: any[];
  subData?: any[];
  onDataZoom?: (start: number, end: number) => void;
}

export const EChartsViewer: React.FC<Props> = ({ mainData, subData, onDataZoom }) => {
  const chartRef = useRef<ReactECharts>(null);

  const getOption = () => {
    return {
      tooltip: {
        trigger: 'axis',
        axisPointer: { type: 'cross' }
      },
      // 두 차트가 하나의 툴팁 선(AxisPointer)을 공유 (RQ-3.3)
      axisPointer: {
        link: [{ xAxisIndex: 'all' }],
        label: { backgroundColor: '#777' }
      },
      // RQ-3.3: 두 개의 차트 영역 (위: Main, 아래: Sub)
      grid: [
        { left: 50, right: 50, top: 40, height: '50%' }, // Main Chart
        { left: 50, right: 50, top: '65%', height: '20%' } // Sub Chart
      ],
      xAxis: [
        {
          type: 'time',
          gridIndex: 0,
          axisLabel: { show: false }, // 상단 X축 레이블 숨김
          axisLine: { show: false },
          axisTick: { show: false },
        },
        {
          type: 'time',
          gridIndex: 1, // 하단 차트에 날짜/시간 표시 (RQ-1.3)
        }
      ],
      yAxis: [
        { type: 'value', gridIndex: 0, name: '수치 (Main)' },
        { 
          type: 'category', 
          gridIndex: 1, 
          name: '상태 (Sub)',
          data: ['에러', '가동'], // RQ-3.2.2: 여러 Bool 롤 간격 분리
          splitLine: { show: true }
        }
      ],
      // RQ-1.2: 데이터 줌 (마우스 스크롤, 드래그 팬 지원)
      dataZoom: [
        {
          type: 'inside', // 마우스 휠, 드래그 팬
          xAxisIndex: [0, 1], // 두 차트를 동시에 제어
        },
        {
          type: 'slider', // 하단 슬라이더
          xAxisIndex: [0, 1],
          bottom: 10
        }
      ],
      series: [
        // Main Chart Series (수치형)
        {
          name: '온도',
          type: 'line',
          xAxisIndex: 0,
          yAxisIndex: 0,
          data: mainData || [], // [timestamp, value]
        },
        // Sub Chart Series (RQ-3.2.1: 발생 시점 세로선 또는 Scatter)
        {
          name: '가동',
          type: 'scatter', // 또는 markLine을 활용할 수 있음
          xAxisIndex: 1,
          yAxisIndex: 1,
          symbolSize: 10,
          itemStyle: { color: 'green' },
          data: subData || [], // [timestamp, '가동']
        }
      ]
    };
  };

  const handleEvents = {
    // RQ-1.2.3 & RQ-2.3: 확대/이동 시 범위를 감지하여 리렌더링(청크 로드) 트리거
    datazoom: (params: any) => {
      if (chartRef.current && onDataZoom) {
        const echartsInstance = chartRef.current.getEchartsInstance();
        const option = echartsInstance.getOption() as echarts.EChartsOption;
        // x축의 현재 보여지는 시간값 추출
        const xAxis = option.xAxis as any[];
        if (xAxis && xAxis.length > 0) {
          const range = xAxis[0].range || xAxis[0].scale.getExtent(); // 라이브러리 버전마다 상이할 수 있음
          // onDataZoom(range[0], range[1]); 
        }
      }
    }
  };

  return (
    <ReactECharts
      ref={chartRef}
      option={getOption()}
      style={{ height: '100%', width: '100%' }}
      onEvents={handleEvents}
      notMerge={false} // 청크가 추가될 때 차트 전체가 깜빡이지 않고 자연스럽게 머지됨
    />
  );
};