// src/pages/ChartViewerPage.tsx
import React from 'react';

export const ChartViewerPage: React.FC = () => {
  return (
    <div style={{ display: 'flex', flexDirection: 'column', height: '100%', gap: 10, boxSizing: 'border-box' }}>
      
      {/* 상단 래퍼 (왼쪽 차트 + 오른쪽 뷰어/조작) */}
      <div style={{ display: 'flex', flex: 1, gap: 10, minHeight: 0 }}>
        
        {/* 왼쪽: 차트 컨테이너 */}
        <div style={{ flex: 2, border: '2px solid #2196f3', display: 'flex', flexDirection: 'column', padding: 10, gap: 10 }}>
          <div style={{ border: '2px solid #9c27b0', padding: 10, textAlign: 'center', color: '#9c27b0', fontWeight: 'bold' }}>
            top tool bar
          </div>
          
          <div style={{ border: '2px solid #ffffff', flex: 2, display: 'flex', alignItems: 'center', justifyContent: 'center', fontWeight: 'bold' }}>
            main chart
          </div>
          
          <div style={{ border: '2px solid #9c27b0', padding: 10, textAlign: 'center', color: '#9c27b0', fontWeight: 'bold' }}>
            lower tool bar
          </div>
          
          <div style={{ border: '2px solid #ffffff', flex: 1, display: 'flex', alignItems: 'center', justifyContent: 'center', fontWeight: 'bold' }}>
            sub chart (*bool 용도)
          </div>
        </div>

        {/* 오른쪽: 패널 컨테이너 */}
        <div style={{ flex: 1, border: '2px solid #e91e63', display: 'flex', flexDirection: 'column', padding: 10, gap: 10 }}>
          <div style={{ border: '2px solid #ffffff', padding: 15, textAlign: 'center', fontWeight: 'bold' }}>
            검색창
          </div>
          
          <div style={{ border: '2px solid #ffffff', flex: 1, display: 'flex', alignItems: 'center', justifyContent: 'center', textAlign: 'center', fontWeight: 'bold' }}>
            메인 조작 패널 1<br />(스코핑)
          </div>
          
          <div style={{ border: '2px solid #ffffff', flex: 2, display: 'flex', alignItems: 'center', justifyContent: 'center', textAlign: 'center', fontWeight: 'bold' }}>
            소요기록 viewer<br />(일자와 연동됨)
          </div>
        </div>

      </div>

      {/* 하단: 메인 조작 패널 2 */}
      <div style={{ border: '2px solid #4caf50', padding: 20, textAlign: 'center', height: '100px', display: 'flex', alignItems: 'center', justifyContent: 'center', fontWeight: 'bold' }}>
        메인 조작 패널 2<br />(맵핑 그룹에 대한 각 포인트 롤 활성화)
      </div>

    </div>
  );
};