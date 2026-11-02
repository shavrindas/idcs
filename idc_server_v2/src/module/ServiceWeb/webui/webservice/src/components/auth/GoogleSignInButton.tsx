// 경로: src/components/auth/GoogleSignInButton.tsx
// 명세: 구글 로그인 버튼 (Google Identity Services)
import React, { useEffect, useRef, useState } from 'react';

/**
 * Web OAuth client. The app signs in against the same client (its
 * serverClientId), so the Google account id it stored matches this one.
 * Its "Authorized JavaScript origins" in Google Cloud must list every address
 * the console is opened from (http://localhost:5173, the server's address…),
 * or Google refuses to render the button.
 */
const GOOGLE_CLIENT_ID =
  import.meta.env.VITE_GOOGLE_CLIENT_ID ||
  '415636031627-asr8rncpbq4c5jkn3r44d0u65cf64lvb.apps.googleusercontent.com';

const GIS_SRC = 'https://accounts.google.com/gsi/client';

declare global {
  interface Window {
    google?: any;
  }
}

let gisLoading: Promise<void> | null = null;

/** Load Google's script once, however many times the login page mounts. */
const loadGis = () => {
  if (window.google?.accounts?.id) return Promise.resolve();
  gisLoading ??= new Promise<void>((resolve, reject) => {
    const script = document.createElement('script');
    script.src = GIS_SRC;
    script.async = true;
    script.onload = () => resolve();
    script.onerror = () => {
      gisLoading = null;
      reject(new Error('구글 로그인 스크립트를 불러오지 못했습니다.'));
    };
    document.head.appendChild(script);
  });
  return gisLoading;
};

interface Props {
  /** Called with Google's signed ID token; the server verifies it. */
  onCredential: (credential: string) => void;
  width?: number;
}

export const GoogleSignInButton: React.FC<Props> = ({ onCredential, width = 320 }) => {
  const host = useRef<HTMLDivElement>(null);
  const callback = useRef(onCredential);
  callback.current = onCredential;
  const [failed, setFailed] = useState(false);

  useEffect(() => {
    let cancelled = false;
    loadGis()
      .then(() => {
        if (cancelled || !host.current) return;
        window.google.accounts.id.initialize({
          client_id: GOOGLE_CLIENT_ID,
          callback: (res: { credential?: string }) => {
            if (res.credential) callback.current(res.credential);
          },
        });
        const dark = document.documentElement.dataset.theme === 'dark'
          || (!document.documentElement.dataset.theme && window.matchMedia('(prefers-color-scheme: dark)').matches);
        window.google.accounts.id.renderButton(host.current, {
          type: 'standard',
          theme: dark ? 'filled_black' : 'outline',
          size: 'large',
          text: 'signin_with',
          shape: 'rectangular',
          width,
          locale: 'ko',
        });
      })
      .catch(() => !cancelled && setFailed(true));
    return () => { cancelled = true; };
  }, [width]);

  if (failed) {
    return (
      <p style={{ fontSize: 12, color: 'var(--text-secondary)', margin: 0, textAlign: 'center' }}>
        구글 로그인을 불러오지 못했습니다. 인터넷 연결을 확인해주세요.
      </p>
    );
  }
  return <div ref={host} style={{ display: 'flex', justifyContent: 'center', minHeight: 44 }} />;
};
