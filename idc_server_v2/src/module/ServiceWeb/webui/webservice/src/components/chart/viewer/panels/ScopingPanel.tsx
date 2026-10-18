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

/**
 * 모드 이름이 그대로 단추에 적혀 있었다 — '현재 모드: DEFAULT (토글)'.
 * DEFAULT 와 EXTENT 가 무엇인지는 코드를 봐야 알 수 있고, 게다가 '토글' 이라
 * 지금 어느 쪽인지는 알려 줘도 누르면 어디로 가는지는 알려 주지 않는다.
 *
 * 실제로 둘을 가르는 것은 '한 번에 몇 가지를, 얼마나 긴 기간으로 보는가' 다.
 * 그래서 두 칸을 나란히 두고 하는 일로 적는다. 지금 어느 쪽인지도, 다른 쪽이
 * 무엇인지도 한눈에 보인다.
 */
const MODE_CHOICES: { value: ChartMode; label: string; hint: string }[] = [
  { value: 'DEFAULT', label: '여러 항목', hint: '여러 수치를 한 차트에 겹쳐 봅니다. 기간은 짧습니다.' },
  { value: 'EXTENT', label: '길게 하나', hint: '수치 하나만 고르는 대신 훨씬 긴 기간을 봅니다.' },
];

export const ScopingPanel: React.FC<Props> = ({ mode, scale, facilities, rooms, selectedFacility, selectedRoom, isChartLoading, onModeToggle, onScaleChange, onFacilityChange, onRoomChange, onQuickTime, onQuickDay }) => (
  <div className="card" style={{ padding: 15, display: 'flex', flexDirection: 'column', gap: 12 }}>
    <h4 style={{ textAlign: 'center', fontSize: 14 }}>조회 범위 설정</h4>

    {/* 고르는 차례대로 — 시설, 그 다음 호실. 위에 둬야 먼저 눈에 든다. */}
    <div style={{ display: 'flex', flexDirection: 'column', gap: 6 }}>
      <span className="label">시설</span>
      <select value={selectedFacility} onChange={e => onFacilityChange(e.target.value ? Number(e.target.value) : '')} disabled={isChartLoading} className="input">
        <option value="">시설을 고르세요</option>
        {facilities.map(fac => <option key={fac.id} value={fac.id}>{fac.name}</option>)}
      </select>
    </div>
    <div style={{ display: 'flex', flexDirection: 'column', gap: 6 }}>
      <span className="label">호실</span>
      <select value={selectedRoom} onChange={e => onRoomChange(e.target.value ? Number(e.target.value) : '')} disabled={!selectedFacility || isChartLoading} className="input">
        <option value="">{selectedFacility ? '호실을 고르세요' : '시설을 먼저 고르세요'}</option>
        {rooms.map(room => <option key={room.id} value={room.id}>{room.name}</option>)}
      </select>
    </div>

    <div style={{ height: 1, background: 'var(--border)' }} />

    <div style={{ display: 'flex', flexDirection: 'column', gap: 6 }}>
      <span className="label">보는 방식</span>
      <div style={{ display: 'flex', gap: 6 }}>
        {MODE_CHOICES.map(choice => (
          <button
            key={choice.value}
            onClick={() => { if (choice.value !== mode) onModeToggle(); }}
            disabled={isChartLoading}
            aria-pressed={choice.value === mode}
            title={choice.hint}
            className={`btn btn-sm btn-toggle${choice.value === mode ? ' on' : ''}`}
            style={{ flex: 1 }}
          >
            {choice.label}
          </button>
        ))}
      </div>
      <p style={{ fontSize: 11, color: 'var(--text-secondary)', lineHeight: 1.45 }}>
        {MODE_CHOICES.find(c => c.value === mode)?.hint}
      </p>
    </div>

    <div style={{ display: 'flex', flexDirection: 'column', gap: 6 }}>
      <span className="label">점 간격</span>
      <select value={scale} onChange={e => onScaleChange(e.target.value as ChartScale)} disabled={isChartLoading} className="input">
        <option value="1m">1분마다</option><option value="5m">5분마다</option><option value="10m">10분마다</option><option value="15m">15분마다</option><option value="1h">1시간마다</option>
      </select>
    </div>

    <div style={{ border: '1px solid var(--border)', borderRadius: 12, padding: 10 }}>
      <div className="label" style={{ marginBottom: 8 }}>지금부터 거슬러</div>
      <div style={{ display: 'flex', gap: 5, flexWrap: 'wrap' }}>
        {[{ label: '1H', h: 1 }, { label: '3H', h: 3 }, { label: '6H', h: 6 }, { label: '12H', h: 12 }, { label: '1D', h: 24 }, { label: '1W', h: 24 * 7 }].map(btn => (
          <button key={btn.label} onClick={() => onQuickTime(btn.h)} disabled={isChartLoading} className="btn btn-ghost btn-sm" style={{ flex: 1 }}>{btn.label}</button>
        ))}
      </div>
    </div>
    <div style={{ border: '1px solid var(--border)', borderRadius: 12, padding: 10 }}>
      <div className="label" style={{ marginBottom: 8 }}>가장 가까운 요일로</div>
      <div style={{ display: 'flex', gap: 5 }}>
        {['일', '월', '화', '수', '목', '금', '토'].map((dayStr, idx) => (
          <button key={dayStr} onClick={() => onQuickDay(idx)} disabled={isChartLoading} className="btn btn-ghost btn-sm" style={{ flex: 1 }}>{dayStr}</button>
        ))}
      </div>
    </div>
  </div>
);
