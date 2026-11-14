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
 * 다른 화면(맵핑 요약 등)에서도 '다중 항목 보기' · '단일 항목 보기' 로
 * 부르는 그 구분이다 — 이름을 맞춰 둔다.
 */
const MODE_CHOICES: { value: ChartMode; label: string }[] = [
  { value: 'DEFAULT', label: '다중 항목' },
  { value: 'EXTENT', label: '단일 항목' },
];

/** 1시간·3시간 ⋯ 1주 — 항상 3열 2행으로 고정한다. flex-wrap 은 칸 너비에
 *  따라 2+2+2 나 5+1 처럼 줄이 들쭉날쭉해질 수 있어, grid 로 줄 수를 못박는다. */
const QUICK_TIME_CHOICES: { label: string; h: number }[] = [
  { label: '1H', h: 1 }, { label: '3H', h: 3 }, { label: '6H', h: 6 },
  { label: '12H', h: 12 }, { label: '1D', h: 24 }, { label: '1W', h: 24 * 7 },
];

const WEEKDAYS = ['일', '월', '화', '수', '목', '금', '토'];

export const ScopingPanel: React.FC<Props> = ({ mode, scale, facilities, rooms, selectedFacility, selectedRoom, isChartLoading, onModeToggle, onScaleChange, onFacilityChange, onRoomChange, onQuickTime, onQuickDay }) => {
  // 어느 걸 눌렀는지 — 버튼 자체는 '그 순간 그 동작을 실행'할 뿐 차트가
  // 지금 그 구간을 보고 있다는 보장은 없지만, 방금 누른 게 어느 것인지도
  // 안 보이면 눌렀는지조차 알 길이 없었다. 마지막으로 누른 것만 표시한다.
  const [activeQuickTime, setActiveQuickTime] = React.useState<number | null>(null);
  const [activeQuickDay, setActiveQuickDay] = React.useState<number | null>(null);

  return (
  <div className="card" style={{ padding: 15, display: 'flex', flexDirection: 'column', gap: 12 }}>
    <h4 style={{ textAlign: 'center', fontSize: 14 }}>조회 범위 설정</h4>

    {/* 고르는 차례대로 — 시설, 그 다음 호실. 나란히 둬도 순서는 왼쪽에서
        오른쪽으로 그대로 읽힌다. 세로로 쌓느라 쓰던 칸 하나를 아낀다. */}
    <div style={{ display: 'flex', gap: 10 }}>
      <div style={{ flex: 1, display: 'flex', flexDirection: 'column', gap: 6, minWidth: 0 }}>
        <span className="label">시설</span>
        <select value={selectedFacility} onChange={e => onFacilityChange(e.target.value ? Number(e.target.value) : '')} disabled={isChartLoading} className="input">
          <option value="">시설을 고르세요</option>
          {facilities.map(fac => <option key={fac.id} value={fac.id}>{fac.name}</option>)}
        </select>
      </div>
      <div style={{ flex: 1, display: 'flex', flexDirection: 'column', gap: 6, minWidth: 0 }}>
        <span className="label">호실</span>
        <select value={selectedRoom} onChange={e => onRoomChange(e.target.value ? Number(e.target.value) : '')} disabled={!selectedFacility || isChartLoading} className="input">
          <option value="">{selectedFacility ? '호실을 고르세요' : '시설을 먼저 고르세요'}</option>
          {rooms.map(room => <option key={room.id} value={room.id}>{room.name}</option>)}
        </select>
      </div>
    </div>

    <div style={{ height: 1, background: 'var(--border)' }} />

    <div style={{ display: 'flex', flexDirection: 'column', gap: 6 }}>
      <span className="label">표시 형식</span>
      <div style={{ display: 'flex', gap: 6 }}>
        {MODE_CHOICES.map(choice => (
          <button
            key={choice.value}
            onClick={() => { if (choice.value !== mode) onModeToggle(); }}
            disabled={isChartLoading}
            aria-pressed={choice.value === mode}
            className={`btn btn-sm btn-toggle${choice.value === mode ? ' on' : ''}`}
            style={{ flex: 1 }}
          >
            {choice.label}
          </button>
        ))}
      </div>
    </div>

    <div style={{ display: 'flex', flexDirection: 'column', gap: 6 }}>
      <span className="label">점 간격</span>
      <select value={scale} onChange={e => onScaleChange(e.target.value as ChartScale)} disabled={isChartLoading} className="input">
        <option value="1m">1분마다</option><option value="5m">5분마다</option><option value="10m">10분마다</option><option value="30m">30분마다</option><option value="1h">1시간마다</option>
      </select>
    </div>

    {/* 최근 시각 — 항상 3열 2행. 칸이 좁아져도 6개가 한 줄에 몰리거나
        5+1 처럼 어색하게 쪼개지지 않는다. */}
    <div style={{ display: 'flex', flexDirection: 'column', gap: 6 }}>
      <span className="label">최근 시각</span>
      <div style={{ display: 'grid', gridTemplateColumns: 'repeat(3, 1fr)', gap: 5 }}>
        {QUICK_TIME_CHOICES.map(btn => (
          <button
            key={btn.label}
            onClick={() => { setActiveQuickTime(btn.h); onQuickTime(btn.h); }}
            disabled={isChartLoading}
            aria-pressed={activeQuickTime === btn.h}
            className={`btn btn-toggle btn-sm${activeQuickTime === btn.h ? ' on' : ''}`}
            style={{ padding: '0 4px' }}
          >
            {btn.label}
          </button>
        ))}
      </div>
    </div>

    {/* 최근 요일 — 일곱 개를 한 줄에 그대로 둔다. 간격과 안쪽 여백을 줄여
        칸 너비 안에서 줄바꿈 없이 들어가게 한다. */}
    <div style={{ display: 'flex', flexDirection: 'column', gap: 6 }}>
      <span className="label">최근 요일</span>
      <div style={{ display: 'flex', gap: 3 }}>
        {WEEKDAYS.map((dayStr, idx) => (
          <button
            key={dayStr}
            onClick={() => { setActiveQuickDay(idx); onQuickDay(idx); }}
            disabled={isChartLoading}
            aria-pressed={activeQuickDay === idx}
            className={`btn btn-toggle btn-sm${activeQuickDay === idx ? ' on' : ''}`}
            style={{ flex: 1, minWidth: 0, padding: 0 }}
          >
            {dayStr}
          </button>
        ))}
      </div>
    </div>
  </div>
  );
};
