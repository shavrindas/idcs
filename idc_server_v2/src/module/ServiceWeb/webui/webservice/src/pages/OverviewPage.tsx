// 경로: src/module/ServiceWeb/webui/webservice/src/pages/OverviewPage.tsx
// 명세: 개괄 모니터링 — 내 시설의 모든 호실을 카드로 실시간 표시 (앱 '전체 현황'과 같은 화면)
import React, { useEffect, useMemo, useRef, useState } from 'react';
import { useNavigate } from 'react-router-dom';
import { apiService } from '../services/apiService';
import type { SessionUser } from '../types';

type Condition = 'normal' | 'drifting' | 'fault' | 'offline';

interface RoomStatus {
  condition: Condition;
  temp: number | null;
  setpoint: number | null;
  faultCount: number;
}

/** Off-setpoint distance that turns a card yellow. Same as the app (RoomStatus.driftThreshold). */
const DRIFT_THRESHOLD = 2.0;

/** Equipment booleans arrive as ON/OFF, 1/0 or 0.0. Unknown → null, so a value
 *  that never came is not drawn as "off". */
const asSwitch = (raw?: string): boolean | null => {
  const v = raw?.trim().toUpperCase();
  if (!v || v === 'NA' || v === '-') return null;
  if (v === 'ON' || v === 'TRUE') return true;
  if (v === 'OFF' || v === 'FALSE') return false;
  const n = Number(v);
  return Number.isNaN(n) ? null : n !== 0;
};

/** Port of the app's RoomStatus.from, so a room is the same colour on both. */
const statusOf = (values: Record<string, string>, alarmCount: number): RoomStatus => {
  const num = (k: string) => {
    const n = parseFloat(values[k] ?? '');
    return Number.isNaN(n) ? null : n;
  };
  const temp = num('temp_pv');
  const setpoint = num('temp_sv');
  const defrosting = asSwitch(values['deforest_def']) ?? false;
  const flags = Object.entries(values).filter(([k, v]) => k.startsWith('emergency_') && asSwitch(v)).length;
  const faultCount = flags + alarmCount;

  let condition: Condition;
  if (faultCount > 0) condition = 'fault';
  else if (temp == null) condition = 'offline';
  // Temperature rising during defrost is normal operation, not drift.
  else if (!defrosting && setpoint != null && Math.abs(temp - setpoint) >= DRIFT_THRESHOLD) condition = 'drifting';
  else condition = 'normal';

  return { condition, temp, setpoint, faultCount };
};

const COLOR: Record<Condition, string> = {
  normal: 'var(--success)',
  drifting: 'var(--warning)',
  fault: 'var(--error)',
  offline: 'var(--text-secondary)',
};

/** Same rule as the app's isAlarmActive. */
const isAlarmActive = (a: any) => {
  const end = a?.end_time ? new Date(a.end_time) : null;
  if (!end || Number.isNaN(end.getTime())) return a?.is_triggered === true;
  return end.getTime() > Date.now();
};

const liveUrl = (userId: number) =>
  `${location.protocol === 'https:' ? 'wss' : 'ws'}://${location.host}/api/v1/serviceweb/facilities/live/${userId}`;

export const OverviewPage: React.FC<{ user: SessionUser }> = ({ user }) => {
  const navigate = useNavigate();
  const [facilities, setFacilities] = useState<any[]>([]);
  const [roomsByFacility, setRoomsByFacility] = useState<Record<number, any[]>>({});
  const [alarmCounts, setAlarmCounts] = useState<Record<number, number>>({});
  const [live, setLive] = useState<Record<number, Record<string, string>>>({});
  const [loading, setLoading] = useState(true);
  const [connected, setConnected] = useState(false);
  const [query, setQuery] = useState('');
  const [ledDigits, setLedDigits] = useState(true);

  // Load facilities, their rooms and open alarms once.
  useEffect(() => {
    let cancelled = false;
    (async () => {
      setLoading(true);
      try {
        const facs: any[] = (await apiService.getUserFacilities(user.id)).facilities || [];
        const [rooms, alarms] = await Promise.all([
          Promise.all(facs.map(f => apiService.getRooms(f.id).then(r => r.rooms || []).catch(() => []))),
          Promise.all(facs.map(f => apiService.getFacilityAlarms(f.id).catch(() => []))),
        ]);
        if (cancelled) return;
        const byFac: Record<number, any[]> = {};
        facs.forEach((f, i) => { byFac[f.id] = rooms[i]; });
        const counts: Record<number, number> = {};
        alarms.flat().filter(isAlarmActive).forEach((a: any) => {
          if (typeof a.room_id === 'number') counts[a.room_id] = (counts[a.room_id] ?? 0) + 1;
        });
        setFacilities(facs);
        setRoomsByFacility(byFac);
        setAlarmCounts(counts);
      } finally {
        if (!cancelled) setLoading(false);
      }
    })();
    return () => { cancelled = true; };
  }, [user.id]);

  // Live values. Keys arrive as "roomId.field"; reconnect with a short backoff.
  const pending = useRef<Record<number, Record<string, string>>>({});
  useEffect(() => {
    let ws: WebSocket | null = null;
    let retry: number | undefined;
    let closed = false;

    // Frames come once a second per facility; batch them into one render.
    const flush = window.setInterval(() => {
      const batch = pending.current;
      if (Object.keys(batch).length === 0) return;
      pending.current = {};
      setLive(prev => {
        const next = { ...prev };
        for (const [roomId, fields] of Object.entries(batch)) {
          next[Number(roomId)] = { ...(next[Number(roomId)] ?? {}), ...fields };
        }
        return next;
      });
    }, 500);

    const connect = () => {
      ws = new WebSocket(liveUrl(user.id));
      ws.onopen = () => setConnected(true);
      ws.onmessage = (ev) => {
        try {
          const msg = JSON.parse(ev.data);
          const datas = msg?.datas ?? msg;
          if (!datas || typeof datas !== 'object') return;
          for (const [key, val] of Object.entries(datas)) {
            const [roomPart, field] = key.split('.');
            const roomId = Number(roomPart);
            if (!field || Number.isNaN(roomId)) continue;
            (pending.current[roomId] ??= {})[field] = String(val);
          }
        } catch {
          // One broken frame must not stop the screen.
        }
      };
      ws.onclose = () => {
        setConnected(false);
        if (!closed) retry = window.setTimeout(connect, 3000);
      };
      ws.onerror = () => ws?.close();
    };
    connect();

    return () => {
      closed = true;
      window.clearInterval(flush);
      window.clearTimeout(retry);
      ws?.close();
    };
  }, [user.id]);

  const statuses = useMemo(() => {
    const out: Record<number, RoomStatus> = {};
    for (const rooms of Object.values(roomsByFacility)) {
      for (const r of rooms) out[r.id] = statusOf(live[r.id] ?? {}, alarmCounts[r.id] ?? 0);
    }
    return out;
  }, [roomsByFacility, live, alarmCounts]);

  const hasData = (roomId: number) => Object.keys(live[roomId] ?? {}).length > 0;

  // Reporting facilities first; stable inside each group.
  const shown = useMemo(() => {
    const q = query.trim().toLowerCase();
    const matched = facilities.filter(f => !q || String(f.name ?? '').toLowerCase().includes(q));
    const reporting = (f: any) => (roomsByFacility[f.id] ?? []).some(r => hasData(r.id));
    return [...matched.filter(reporting), ...matched.filter(f => !reporting(f))];
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [facilities, roomsByFacility, live, query]);

  const counts = useMemo(() => {
    const c: Record<Condition, number> = { normal: 0, drifting: 0, fault: 0, offline: 0 };
    Object.values(statuses).forEach(s => { c[s.condition] += 1; });
    return c;
  }, [statuses]);

  return (
    <div style={{ padding: 24, display: 'flex', flexDirection: 'column', gap: 16, maxWidth: 1400, width: '100%', margin: '0 auto', boxSizing: 'border-box' }}>
      <div style={{ display: 'flex', alignItems: 'center', gap: 16, flexWrap: 'wrap' }}>
        <h2 style={{ margin: 0, fontSize: 20 }}>전체 현황</h2>
        <SummaryRow counts={counts} />
        <div style={{ marginLeft: 'auto', display: 'flex', alignItems: 'center', gap: 12 }}>
          <span style={{ fontSize: 12, color: connected ? 'var(--success)' : 'var(--text-secondary)', display: 'inline-flex', alignItems: 'center', gap: 6 }}>
            <span style={{ width: 7, height: 7, borderRadius: '50%', background: 'currentColor' }} />
            {connected ? '실시간 연결됨' : '연결 중…'}
          </span>
          <label style={{ fontSize: 12, color: 'var(--text-secondary)', display: 'inline-flex', alignItems: 'center', gap: 6, cursor: 'pointer' }}>
            <input type="checkbox" checked={ledDigits} onChange={e => setLedDigits(e.target.checked)} /> LED 숫자
          </label>
          <input
            className="input"
            placeholder="시설 이름으로 찾기"
            value={query}
            onChange={e => setQuery(e.target.value)}
            style={{ width: 200 }}
          />
        </div>
      </div>

      {loading ? (
        <p style={{ color: 'var(--text-secondary)', fontSize: 13 }}>불러오는 중…</p>
      ) : shown.length === 0 ? (
        <p style={{ color: 'var(--text-secondary)', fontSize: 13 }}>{query ? '검색 결과가 없습니다.' : '등록된 시설이 없습니다.'}</p>
      ) : (
        shown.map(f => (
          <FacilitySection
            key={f.id}
            name={f.name}
            rooms={roomsByFacility[f.id] ?? []}
            statuses={statuses}
            live={live}
            hasData={hasData}
            ledDigits={ledDigits}
            onOpen={(roomId) => navigate(`/viewer?facility=${f.id}&room=${roomId}`)}
          />
        ))
      )}
    </div>
  );
};

const SummaryRow: React.FC<{ counts: Record<Condition, number> }> = ({ counts }) => {
  const items: [string, Condition, boolean][] = [
    ['정상', 'normal', true],
    ['이탈', 'drifting', true],
    ['이상', 'fault', true],
    ['값 없음', 'offline', false],
  ];
  return (
    <div style={{ display: 'flex', gap: 14, flexWrap: 'wrap' }}>
      {items.map(([label, c, filled]) => (
        // Zero counts fade instead of disappearing, so a new fault shows up
        // in a place the eye already knows.
        <span key={c} style={{ display: 'inline-flex', alignItems: 'center', gap: 5, opacity: counts[c] === 0 ? 0.45 : 1 }}>
          <span style={{ width: 8, height: 8, borderRadius: '50%', background: filled ? COLOR[c] : 'transparent', border: filled ? 'none' : `1.5px solid ${COLOR[c]}` }} />
          <span style={{ fontSize: 12, fontWeight: 600, color: 'var(--text-secondary)' }}>{label}</span>
          <span style={{ fontSize: 13, fontWeight: 800, fontVariantNumeric: 'tabular-nums', color: counts[c] > 0 && (c === 'drifting' || c === 'fault') ? COLOR[c] : 'var(--text)' }}>
            {counts[c]}
          </span>
        </span>
      ))}
    </div>
  );
};

interface SectionProps {
  name: string;
  rooms: any[];
  statuses: Record<number, RoomStatus>;
  live: Record<number, Record<string, string>>;
  hasData: (roomId: number) => boolean;
  ledDigits: boolean;
  onOpen: (roomId: number) => void;
}

/** One facility. Reporting rooms first, silent rooms folded behind a button. */
const FacilitySection: React.FC<SectionProps> = ({ name, rooms, statuses, live, hasData, ledDigits, onOpen }) => {
  const [showEmpty, setShowEmpty] = useState(false);
  const withData = rooms.filter(r => hasData(r.id));
  const empty = rooms.filter(r => !hasData(r.id));
  const attention = rooms.filter(r => ['fault', 'drifting'].includes(statuses[r.id]?.condition)).length;

  const card = (r: any, i: number) => (
    <RoomCard key={r.id} index={i} name={r.name} values={live[r.id] ?? {}} status={statuses[r.id]} ledDigits={ledDigits} onClick={() => onOpen(r.id)} />
  );

  return (
    <section style={{ display: 'flex', flexDirection: 'column', gap: 10 }}>
      <div style={{ display: 'flex', alignItems: 'center', gap: 8 }}>
        <h3 style={{ margin: 0, fontSize: 15, fontWeight: 800 }}>{name}</h3>
        {attention > 0 ? (
          <span style={{ fontSize: 11, fontWeight: 800, color: 'var(--error)', background: 'var(--error-bg)', borderRadius: 6, padding: '2px 7px' }}>{attention}</span>
        ) : (
          <span style={{ fontSize: 12, color: 'var(--text-secondary)' }}>호실 {rooms.length}곳</span>
        )}
      </div>
      {withData.length > 0 && <div className="ov-grid">{withData.map(card)}</div>}
      {empty.length > 0 && (
        <>
          <button className="btn btn-ghost btn-sm" style={{ alignSelf: 'flex-start' }} onClick={() => setShowEmpty(v => !v)}>
            {showEmpty ? '▴ 값 없는 호실 접기' : `▾ 값 없는 호실 ${empty.length}곳 보기`}
          </button>
          {showEmpty && <div className="ov-grid">{empty.map(card)}</div>}
        </>
      )}
    </section>
  );
};

interface CardProps {
  index: number;
  name: string;
  values: Record<string, string>;
  status?: RoomStatus;
  ledDigits: boolean;
  onClick: () => void;
}

const LAMPS: [string, string, boolean][] = [
  ['deforest_def', '제상', false],
  ['temp_comp', '콤프', false],
  ['emergency_emg', '이상', true],
  ['emergency_cint', 'CINT', true],
  ['emergency_high', 'HIGH', true],
];

const RoomCard: React.FC<CardProps> = ({ index, name, values, status, ledDigits, onClick }) => {
  const s = status ?? { condition: 'offline' as Condition, temp: null, setpoint: null, faultCount: 0 };
  const color = s.condition === 'offline' ? 'var(--text)' : COLOR[s.condition];
  const deviation = s.temp != null && s.setpoint != null ? s.temp - s.setpoint : null;
  const lamps = LAMPS.map(([key, label, danger]) => ({ label, danger, on: asSwitch(values[key]) })).filter(l => l.on != null);
  const rule = <div style={{ height: 1, background: 'color-mix(in srgb, var(--text-secondary) 35%, transparent)' }} />;

  return (
    <button className={`ov-card${s.condition === 'fault' ? ' fault' : ''}`} onClick={onClick} title="차트에서 보기">
      <div style={{ padding: '10px 12px 8px', display: 'flex', flexDirection: 'column', gap: 4, flex: 1 }}>
        <div style={{ display: 'flex', alignItems: 'center', gap: 6 }}>
          <span style={{ flex: 1, fontSize: 13, fontWeight: 700, overflow: 'hidden', textOverflow: 'ellipsis', whiteSpace: 'nowrap' }}>{name}</span>
          {s.faultCount > 0 && (
            <span style={{ fontSize: 11, fontWeight: 800, color: 'var(--error)', background: 'var(--error-bg)', borderRadius: 5, padding: '1px 6px' }}>{s.faultCount}</span>
          )}
        </div>

        {/* Ruled off from the numbers around it — clients were losing the
            reading among the setpoint, delta and lamp labels. */}
        {rule}
        {/* Top-aligned so °C sits by the top of the digits, like a panel readout. */}
        <div style={{ display: 'flex', justifyContent: 'flex-end', alignItems: 'flex-start', gap: 2, paddingRight: 10 }}>
          {s.temp != null && (
            // The minus keeps its own slot like an LED segment: lit below
            // zero, faint above, so digits stay in the same place.
            <span style={{ width: 12, height: 3, borderRadius: 2, marginTop: 12, background: color, opacity: s.temp < 0 ? 1 : 0.1 }} />
          )}
          <span style={{
            fontSize: 28, lineHeight: 1, fontWeight: 700, color,
            fontFamily: s.temp != null && ledDigits ? "'DSEG7', monospace" : undefined,
            fontVariantNumeric: 'tabular-nums', letterSpacing: s.temp != null && ledDigits ? 1 : undefined,
          }}>
            {s.temp == null ? '—' : Math.abs(s.temp).toFixed(1)}
          </span>
          {s.temp != null && <span style={{ fontSize: 11, fontWeight: 700, color: 'var(--text-secondary)', lineHeight: 1 }}>°C</span>}
        </div>
        {rule}

        <div style={{ display: 'flex', gap: 6, fontSize: 11, fontWeight: 600, color: 'var(--text-secondary)' }}>
          {s.setpoint != null && <span>목표 {s.setpoint.toFixed(1)}</span>}
          {deviation != null && (
            <span style={{ fontWeight: 800, color: s.condition === 'drifting' ? 'var(--warning)' : undefined }}>
              Δ {deviation >= 0 ? '+' : ''}{deviation.toFixed(1)}
            </span>
          )}
        </div>

        {lamps.length > 0 && (
          <div style={{ display: 'flex', flexWrap: 'wrap', gap: 4, marginTop: 2 }}>
            {lamps.map(l => (
              <span key={l.label} className={`ov-lamp${l.on ? ' on' : ''}${l.danger ? ' danger' : ''}`}>
                <span className="dot" />{l.label}
              </span>
            ))}
          </div>
        )}
      </div>
      <div
        className="ov-rail"
        style={{
          background: COLOR[s.condition],
          opacity: s.condition === 'offline' ? 0.25 : 1,
          // Stagger so a grid of cards sweeps top to bottom instead of all at once.
          animationDelay: `${Math.min(index * 55, 420)}ms`,
        }}
      />
    </button>
  );
};
