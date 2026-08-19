import React from 'react';
import type { ChartMode, ChartScale } from '../../../../constants/chartConfig';

interface Props {
  mode: ChartMode;
  scale: ChartScale;
  facilities: any[];
  rooms: any[];
  selectedFacility: number | '';
  selectedRoom: number | '';
  isChartLoading: boolean;
  onModeToggle: () => void;
  onScaleChange: (val: ChartScale) => void;
  onFacilityChange: (val: number | '') => void;
  onRoomChange: (val: number | '') => void;
  onQuickTime: (hours: number) => void;
  onQuickDay: (dayIdx: number) => void;
}

export const ScopingPanel: React.FC<Props> = ({ mode, scale, facilities, rooms, selectedFacility, selectedRoom, isChartLoading, onModeToggle, onScaleChange, onFacilityChange, onRoomChange, onQuickTime, onQuickDay }) => (
  <div style={{ border: '2px solid #ffffff', padding: 15, display: 'flex', flexDirection: 'column', gap: 10 }}>
    <h4 style={{ margin: 0, textAlign: 'center' }}>메인 조작 패널 1 (스코핑)</h4>
    <button onClick={onModeToggle} disabled={isChartLoading} style={{ padding: 8, cursor: 'pointer', backgroundColor: '#555', color: '#fff', border: 'none', opacity: isChartLoading ? 0.5 : 1 }}>현재 모드: {mode} (토글)</button>
    <select value={scale} onChange={e => onScaleChange(e.target.value as ChartScale)} disabled={isChartLoading} style={{ padding: 8, backgroundColor: '#333', color: '#fff', opacity: isChartLoading ? 0.5 : 1 }}>
      <option value="1m">1분 단위</option><option value="5m">5분 단위</option><option value="10m">10분 단위</option><option value="15m">15분 단위</option><option value="1h">1시간 단위</option>
    </select>
    <select value={selectedFacility} onChange={e => onFacilityChange(e.target.value ? Number(e.target.value) : '')} disabled={isChartLoading} style={{ padding: 8, backgroundColor: '#333', color: '#fff', opacity: isChartLoading ? 0.5 : 1 }}>
      <option value="">-- 시설 선택 --</option>
      {facilities.map(fac => <option key={fac.id} value={fac.id}>{fac.name}</option>)}
    </select>
    <select value={selectedRoom} onChange={e => onRoomChange(e.target.value ? Number(e.target.value) : '')} disabled={!selectedFacility || isChartLoading} style={{ padding: 8, backgroundColor: '#333', color: '#fff', opacity: isChartLoading ? 0.5 : 1 }}>
      <option value="">-- 호실 선택 --</option>
      {rooms.map(room => <option key={room.id} value={room.id}>{room.name}</option>)}
    </select>

    <div style={{ border: '1px solid #555', padding: 10, marginTop: 5, backgroundColor: '#222' }}>
      <div style={{ fontSize: 12, marginBottom: 8, color: '#aaa' }}>최근 시간 이동 (현재 기준)</div>
      <div style={{ display: 'flex', gap: 5, flexWrap: 'wrap' }}>
        {[{ label: '1H', h: 1 }, { label: '3H', h: 3 }, { label: '6H', h: 6 }, { label: '12H', h: 12 }, { label: '1D', h: 24 }, { label: '1W', h: 24 * 7 }].map(btn => (
          <button key={btn.label} onClick={() => onQuickTime(btn.h)} disabled={isChartLoading} style={{ flex: 1, padding: '6px 0', backgroundColor: '#444', color: '#fff', border: '1px solid #666', cursor: isChartLoading ? 'not-allowed' : 'pointer', fontSize: 12, opacity: isChartLoading ? 0.5 : 1 }}>{btn.label}</button>
        ))}
      </div>
    </div>
    <div style={{ border: '1px solid #555', padding: 10, backgroundColor: '#222' }}>
      <div style={{ fontSize: 12, marginBottom: 8, color: '#aaa' }}>최근 요일 이동</div>
      <div style={{ display: 'flex', gap: 5 }}>
        {['일', '월', '화', '수', '목', '금', '토'].map((dayStr, idx) => (
          <button key={dayStr} onClick={() => onQuickDay(idx)} disabled={isChartLoading} style={{ flex: 1, padding: '6px 0', backgroundColor: '#444', color: '#fff', border: '1px solid #666', cursor: isChartLoading ? 'not-allowed' : 'pointer', fontSize: 12, opacity: isChartLoading ? 0.5 : 1 }}>{dayStr}</button>
        ))}
      </div>
    </div>
  </div>
);