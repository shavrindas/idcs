// src/services/session.ts
import type { SessionUser } from '../types';

const KEY = 'idcool.webui.user';

/**
 * 로그인한 사용자를 브라우저에 맡겨 둔다.
 *
 * localStorage를 쓴다 — 브라우저를 아예 닫았다 다시 열어도 로그인 상태가
 * 남는다. 대신 언제까지나 유효하지는 않도록 만료 시각을 같이 적어 두고,
 * 지난 값은 꺼내는 순간 지운다. 비밀번호는 담지 않는다(id·이름·권한뿐).
 * 권한 판정은 어차피 서버가 하고, 여기 값은 화면을 그리기 위한 것이다.
 */
interface StoredSession {
  user: SessionUser;
  expiresAt: number;
}

const DAY_MS = 24 * 60 * 60 * 1000;

/** 서버가 돌려주는 expiry_policy ("30days" | "1day" 등)를 밀리초로 바꾼다. */
const expiryMsFor = (policy?: string): number => {
  if (policy === '30days') return 30 * DAY_MS;
  return DAY_MS;
};

export const loadSession = (): SessionUser | null => {
  try {
    const raw = localStorage.getItem(KEY);
    if (!raw) return null;
    const parsed = JSON.parse(raw) as Partial<StoredSession>;
    if (typeof parsed?.user?.id !== 'number' || typeof parsed.expiresAt !== 'number') return null;
    if (Date.now() > parsed.expiresAt) {
      localStorage.removeItem(KEY);
      return null;
    }
    return parsed.user;
  } catch {
    // 저장소를 막아 둔 브라우저이거나 값이 깨진 경우. 로그인 화면으로 보낸다.
    return null;
  }
};

export const saveSession = (user: SessionUser | null, expiryPolicy?: string) => {
  try {
    if (user) {
      const stored: StoredSession = { user, expiresAt: Date.now() + expiryMsFor(expiryPolicy) };
      localStorage.setItem(KEY, JSON.stringify(stored));
    } else {
      localStorage.removeItem(KEY);
    }
  } catch {
    // 저장이 안 돼도 이번 세션은 메모리로 계속 쓸 수 있다.
  }
};
