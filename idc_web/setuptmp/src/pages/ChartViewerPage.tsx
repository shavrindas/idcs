// src/pages/ChartViewerPage.tsx
import React, { useState, useEffect } from 'react';
import { EChartsViewer } from '../components/chart/EChartsViewer';
import type { ChartMode, ChartScale } from '../constants/chartConfig';

export const ChartViewerPage: React.FC = () => {
  // RQ-2.2 & RQ-6: 메인 조작 상태 관리
  const [mode, setMode] = useState<ChartMode>('DEFAULT');
  const [scale, setScale] = useState<ChartScale>('1m');
  
  // RQ-1.1 & RQ-2.2.1: 시점 저장 (기본값: 오늘)
  const [centerTime, setCenterTime] = useState<number>(Date.now());
  
  // RQ-6.4: 선택된 포인트 롤 (EXTENT 모드일 땐 단일 선택 강제 로직 필요)
  const [selectedRoles, setSelectedRoles] = useState<number[]>([]);

  // TODO: activeChunks (불러온 데이터 청크들을 관리하는 배열 State)

  // 모드 변경 토글 핸들러 (RQ-6.3.2.1)
  const handleModeToggle = () => {
    setMode(prev => {
      const nextMode = prev === 'DEFAULT' ? 'EXTENT' : 'DEFAULT';
      // EXTENT 모드로 진입 시, 다중 선택된 롤이 있다면 첫 번째 롤만 남기도록 강제
      if (nextMode === 'EXTENT' && selectedRoles.length > 1) {
        setSelectedRoles([selectedRoles[0]]);
      }
      return nextMode;
    });
  };

  return (
    <div style={{ display: 'flex', flexDirection: 'column', height: '100%', gap: 10, boxSizing: 'border-box' }}>
      
      <div style={{ display: 'flex', flex: 1, gap: 10, minHeight: 0 }}>
        
        {/* 왼쪽: 차트 영역 */}
        <div style={{ flex: 2, display: 'flex', flexDirection: 'column', gap: 10 }}>
          <div style={{ border: '2px solid #9c27b0', padding: 10, display: 'flex', justifyContent: 'space-between' }}>
            <span>Top Tool Bar (RQ-6.1)</span>
            <input type="datetime-local" title="RQ-6.3 일자 검색" />
          </div>
          
          <div style={{ border: '2px solid #2196f3', flex: 1, backgroundColor: '#1e1e1e' }}>
            <EChartsViewer 
              onDataZoom={(start, end) => {
                // TODO: 중심점 계산하여 centerTime 업데이트 및 새 청크 로드 트리거 (RQ-2.3)
              }} 
            />
          </div>
        </div>

        {/* 오른쪽: 패널 1 (RQ-6.3) */}
        <div style={{ flex: 1, display: 'flex', flexDirection: 'column', gap: 10 }}>
          <div style={{ border: '2px solid #ffffff', padding: 15, textAlign: 'center', fontWeight: 'bold' }}>
            [임시 격리] 검색창 모듈
          </div>
          
          <div style={{ border: '2px solid #e91e63', padding: 15, display: 'flex', flexDirection: 'column', gap: 15 }}>
            <h4 style={{ margin: 0 }}>메인 조작 패널 1 (스코핑)</h4>
            
            <button onClick={handleModeToggle} style={{ padding: 10 }}>
              현재 모드: {mode} (토글)
            </button>

            <select value={scale} onChange={(e) => setScale(e.target.value as ChartScale)} style={{ padding: 10 }}>
              <option value="1m">1분 단위</option>
              <option value="5m">5분 단위</option>
              <option value="10m">10분 단위</option>
              <option value="15m">15분 단위</option>
              <option value="1h">1시간 단위</option>
            </select>
          </div>
          
          <div style={{ border: '2px solid #ffffff', flex: 2, display: 'flex', alignItems: 'center', justifyContent: 'center' }}>
            소요기록 viewer
          </div>
        </div>
      </div>

      {/* 하단: 패널 2 (RQ-6.4) */}
      <div style={{ border: '2px solid #4caf50', padding: 20 }}>
        <h4>메인 조작 패널 2 (맵핑 그룹 활성화)</h4>
        <div>
          <label style={{ marginRight: 15 }}>
            <input type="checkbox" checked disabled={mode === 'EXTENT' && selectedRoles.length > 0} /> 
            포인트롤 1 (수치)
          </label>
          <label style={{ marginRight: 15 }}>
            <input type="checkbox" /> 
            포인트롤 2 (BOOL - Sub Chart)
          </label>
        </div>
      </div>

    </div>
  );
};