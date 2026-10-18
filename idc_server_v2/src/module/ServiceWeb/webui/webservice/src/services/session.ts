// src/services/session.ts
import type { SessionUser } from '../types';

const KEY = 'idcool.webui.user';

/**
 * 로그인한 사용자를 브라우저에 잠깐 맡겨 둔다.
 *
 * 예전에는 App 의 useState 에만 있어서, 새로고침하거나 주소를 직접 치면 그대로
 * 로그아웃됐다. 화면을 북마크해 둘 수도, F5 를 누를 수도 없었다는 뜻이다.
 *
 * sessionStorage 를 쓴다 — 탭을 닫으면 지워지므로 공용 PC 에 남지 않고,
 * 새로고침과 주소 직접 입력은 버틴다. 비밀번호는 담지 않는다(id·이름·권한뿐).
 * 권한 판정은 어차피 서버가 하고, 여기 값은 화면을 그리기 위한 것이다.
 */
export const loadSession = (): SessionUser | null => {
  try {
    const raw = sessionStorage.getItem(KEY);
    if (!raw) return null;
    const parsed = JSON.parse(raw);
    return typeof parsed?.id === 'number' ? (parsed as SessionUser) : null;
  } catch {
    // 저장소를 막아 둔 브라우저이거나 값이 깨진 경우. 로그인 화면으로 보낸다.
    return null;
  }
};

export const saveSession = (user: SessionUser | null) => {
  try {
    if (user) sessionStorage.setItem(KEY, JSON.stringify(user));
    else sessionStorage.removeItem(KEY);
  } catch {
    // 저장이 안 돼도 이번 세션은 메모리로 계속 쓸 수 있다.
  }
};
