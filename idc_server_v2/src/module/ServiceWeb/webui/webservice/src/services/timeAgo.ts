// src/services/timeAgo.ts

/**
 * 마지막 신호가 얼마나 지났는지.
 *
 * 노드 현황표는 '살아 있는가'를 보는 곳인데 시각만 찍혀 있었다
 * (3:21:22 PM). 사흘 전 3시 21분과 3분 전 3시 21분이 같아 보인다.
 * 지난 시간을 앞에 세우고, 날짜·시각은 뒤에 붙인다.
 */
export const describeSignalAge = (raw: string | null | undefined): string => {
  if (!raw) return '-';

  const at = new Date(raw);
  if (Number.isNaN(at.getTime())) return String(raw);

  const seconds = Math.max(0, Math.floor((Date.now() - at.getTime()) / 1000));
  const stamp = at.toLocaleString(undefined, {
    month: '2-digit', day: '2-digit', hour: '2-digit', minute: '2-digit',
  });

  if (seconds < 60) return `방금 (${stamp})`;
  if (seconds < 3600) return `${Math.floor(seconds / 60)}분 전 (${stamp})`;
  if (seconds < 86400) return `${Math.floor(seconds / 3600)}시간 전 (${stamp})`;
  return `${Math.floor(seconds / 86400)}일 전 (${stamp})`;
};
