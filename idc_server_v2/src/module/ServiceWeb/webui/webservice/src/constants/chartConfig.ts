// src/constants/chartConfig.ts
export type ChartMode = 'DEFAULT' | 'EXTENT';
export type ChartScale = '1m' | '5m' | '10m' | '30m' | '1h';

interface ScaleConfig {
  maxRange: number; // MS 기준 (표시 안됨, 참고용)
  chunkSize: number; // MS 기준 (데이터 패치 단위)
  maxChunks: number; // 유지할 최대 청크 수 (기본+5 또는 EXTENT+10)
}

// 요구사항 RQ-2.1 기반 설정값 (ms 단위 환산)
const HOUR = 60 * 60 * 1000;
const DAY = 24 * HOUR;

export const CHART_SCOPING_CONFIG: Record<ChartMode, Record<ChartScale, ScaleConfig>> = {
  DEFAULT: {
    '1m': { maxRange: 5 * DAY, chunkSize: 4 * HOUR, maxChunks: 5 },
    '5m': { maxRange: 15 * DAY, chunkSize: 1 * DAY, maxChunks: 5 },
    '10m': { maxRange: 30 * DAY, chunkSize: 3 * DAY, maxChunks: 5 },
    '30m': { maxRange: 90 * DAY, chunkSize: 7 * DAY, maxChunks: 5 },
    '1h': { maxRange: 180 * DAY, chunkSize: 10 * DAY, maxChunks: 5 },
  },
  EXTENT: {
    '1m': { maxRange: 20 * DAY, chunkSize: 1 * DAY, maxChunks: 10 },
    '5m': { maxRange: 60 * DAY, chunkSize: 3 * DAY, maxChunks: 10 },
    '10m': { maxRange: 120 * DAY, chunkSize: 5 * DAY, maxChunks: 10 },
    '30m': { maxRange: 360 * DAY, chunkSize: 12 * DAY, maxChunks: 10 },
    '1h': { maxRange: 720 * DAY, chunkSize: 15 * DAY, maxChunks: 10 },
  }
};