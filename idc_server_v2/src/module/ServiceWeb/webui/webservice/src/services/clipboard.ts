// src/services/clipboard.ts

/**
 * 텍스트를 클립보드에 넣는다. 성공하면 true.
 *
 * navigator.clipboard 는 보안 컨텍스트(https 또는 localhost)에서만 존재한다.
 * 이 콘솔은 백엔드가 http 로 서빙하므로 사내 IP 로 열면 그 API 자체가 없고,
 * 바로 부르면 TypeError 가 난다. 그래서 있으면 그걸 쓰고, 없으면 화면 밖에
 * 숨긴 textarea 를 거쳐 execCommand 로 떨어진다 — 오래된 방법이지만 http
 * 에서도 동작한다.
 */
export const copyToClipboard = async (text: string): Promise<boolean> => {
  if (navigator.clipboard && window.isSecureContext) {
    try {
      await navigator.clipboard.writeText(text);
      return true;
    } catch {
      // 권한이 막힌 경우. 아래 방법으로 한 번 더 시도한다.
    }
  }

  try {
    const area = document.createElement('textarea');
    area.value = text;
    area.setAttribute('readonly', '');
    area.style.position = 'fixed';
    area.style.top = '-1000px';
    document.body.appendChild(area);
    area.select();
    const ok = document.execCommand('copy');
    document.body.removeChild(area);
    return ok;
  } catch {
    return false;
  }
};
