import React, { createContext, useContext, useEffect, useState } from 'react';

/**
 * 밝게 볼지 어둡게 볼지.
 *
 * 'system' 이 기본이다. 냉동 창고를 보는 사람은 낮에는 사무실, 밤에는 당직실
 * 에서 같은 화면을 여는데, 그때마다 설정을 찾아 들어가게 할 이유가 없다.
 * 운영체제가 이미 알고 있는 것을 따라간다. 직접 고르면 그쪽이 이긴다.
 */
export type ThemeMode = 'system' | 'light' | 'dark';

/** 실제로 화면에 칠해지는 것은 둘 중 하나다. */
export type ResolvedTheme = 'light' | 'dark';

const KEY = 'idcool.webui.theme';

const loadMode = (): ThemeMode => {
  try {
    const raw = localStorage.getItem(KEY);
    return raw === 'light' || raw === 'dark' ? raw : 'system';
  } catch {
    // 저장소를 막아 둔 브라우저. 이번 방문만 운영체제를 따른다.
    return 'system';
  }
};

const saveMode = (mode: ThemeMode) => {
  try {
    if (mode === 'system') localStorage.removeItem(KEY);
    else localStorage.setItem(KEY, mode);
  } catch {
    // 저장이 안 돼도 이번 세션은 그대로 쓴다.
  }
};

const systemPrefersDark = () =>
  typeof window.matchMedia === 'function' && window.matchMedia('(prefers-color-scheme: dark)').matches;

const resolve = (mode: ThemeMode): ResolvedTheme =>
  mode === 'system' ? (systemPrefersDark() ? 'dark' : 'light') : mode;

interface ThemeContextValue {
  mode: ThemeMode;
  resolved: ResolvedTheme;
  setMode: (next: ThemeMode) => void;
}

const ThemeContext = createContext<ThemeContextValue>({
  mode: 'system',
  resolved: 'light',
  setMode: () => {},
});

/**
 * 차트는 CSS 를 쓰지 않고 캔버스에 직접 그리므로, 색이 바뀌었다는 것을
 * 스스로는 알 수 없다. 이 값을 읽는 컴포넌트는 테마가 바뀔 때 다시 그려진다 —
 * 차트가 색을 다시 집어 가는 길이 이것뿐이다.
 */
export const useTheme = () => useContext(ThemeContext);

export const ThemeProvider: React.FC<{ children: React.ReactNode }> = ({ children }) => {
  const [mode, setModeState] = useState<ThemeMode>(loadMode);
  const [resolved, setResolved] = useState<ResolvedTheme>(() => resolve(loadMode()));

  useEffect(() => {
    const next = resolve(mode);
    setResolved(next);

    // 'system' 일 때는 속성을 아예 지운다. 남겨 두면 CSS 의
    // :root:not([data-theme="light"]) 규칙이 운영체제 설정을 못 따라간다.
    if (mode === 'system') delete document.documentElement.dataset.theme;
    else document.documentElement.dataset.theme = mode;
  }, [mode]);

  // 운영체제를 따라가는 중이라면, 사용자가 OS 설정을 바꾼 순간 같이 바뀌어야
  // 한다. 새로고침해야 반영되면 '따라간다'고 할 수 없다.
  useEffect(() => {
    if (mode !== 'system' || typeof window.matchMedia !== 'function') return;
    const mq = window.matchMedia('(prefers-color-scheme: dark)');
    const onChange = () => setResolved(mq.matches ? 'dark' : 'light');
    mq.addEventListener('change', onChange);
    return () => mq.removeEventListener('change', onChange);
  }, [mode]);

  const setMode = (next: ThemeMode) => {
    saveMode(next);
    setModeState(next);
  };

  return (
    <ThemeContext.Provider value={{ mode, resolved, setMode }}>
      {children}
    </ThemeContext.Provider>
  );
};

/** 머리글의 테마 단추. 밝게 → 어둡게 → 시스템 순으로 돈다. */
export const ThemeToggle: React.FC = () => {
  const { mode, resolved, setMode } = useTheme();

  const next: ThemeMode = mode === 'light' ? 'dark' : mode === 'dark' ? 'system' : 'light';
  const label = mode === 'system' ? `시스템 설정 (지금 ${resolved === 'dark' ? '어둡게' : '밝게'})` : mode === 'dark' ? '어둡게' : '밝게';

  return (
    <button
      onClick={() => setMode(next)}
      className="btn btn-ghost btn-sm"
      title={`화면 밝기: ${label} — 눌러서 바꿉니다`}
      aria-label={`화면 밝기: ${label}`}
    >
      {mode === 'system' ? (
        <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.8" strokeLinecap="round" strokeLinejoin="round" aria-hidden="true">
          <rect x="2" y="3" width="20" height="14" rx="2" />
          <path d="M8 21h8M12 17v4" />
        </svg>
      ) : resolved === 'dark' ? (
        <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.8" strokeLinecap="round" strokeLinejoin="round" aria-hidden="true">
          <path d="M21 12.8A9 9 0 1 1 11.2 3a7 7 0 0 0 9.8 9.8z" />
        </svg>
      ) : (
        <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.8" strokeLinecap="round" strokeLinejoin="round" aria-hidden="true">
          <circle cx="12" cy="12" r="4" />
          <path d="M12 2v2M12 20v2M4.9 4.9l1.4 1.4M17.7 17.7l1.4 1.4M2 12h2M20 12h2M4.9 19.1l1.4-1.4M17.7 6.3l1.4-1.4" />
        </svg>
      )}
    </button>
  );
};
