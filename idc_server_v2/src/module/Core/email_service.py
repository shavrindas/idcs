# =================================================
#  경로 : src/module/Core/email_service.py
#  설명 : SMTP 이메일 발송 공통 유틸리티.
#
#  SMTP_* 환경 변수가 아직 설정되지 않은 동안에는(팀에서 Gmail 앱 비밀번호를
#  준비하는 중일 수 있다) 실제로 보내는 대신 콘솔에 찍어 둔다 — 그래야 그
#  설정이 끝나기 전에도 비밀번호 재설정 같은 기능 자체는 끝까지 테스트할 수
#  있다. 나중에 .env에 SMTP_HOST/PORT/USER/PASSWORD/FROM만 채우면 코드
#  변경 없이 바로 실제 발송으로 전환된다.
# =================================================

import os
import smtplib
import ssl
from email.message import EmailMessage

SMTP_HOST = os.getenv("SMTP_HOST")
SMTP_PORT = int(os.getenv("SMTP_PORT", "587"))
SMTP_USER = os.getenv("SMTP_USER")
SMTP_PASSWORD = os.getenv("SMTP_PASSWORD")
SMTP_FROM = os.getenv("SMTP_FROM", SMTP_USER)


def is_email_configured() -> bool:
    return bool(SMTP_HOST and SMTP_USER and SMTP_PASSWORD)


def _safe_print(message: str) -> None:
    """Windows 콘솔/리다이렉트 출력은 cp1252라, 메일 제목·본문에 들어간 한글을
    그대로 print()하면 UnicodeEncodeError로 요청 전체가 죽는다 (서버가 500을
    돌려줘 버림). 그 경우 한글을 '?'로 바꿔서라도 로그 자체는 남긴다."""
    try:
        print(message)
    except UnicodeEncodeError:
        print(message.encode("ascii", errors="replace").decode("ascii"))


def send_email(to_email: str, subject: str, body: str, html_body: str | None = None) -> None:
    """실패해도 호출부의 흐름(코드 발급 자체)을 막지 않도록 예외를 삼키고 로그만 남긴다.
    html_body를 같이 주면 HTML로도 보내고(멀티파트), 안 주면 평문(body)만 보낸다."""
    if not is_email_configured():
        _safe_print(f"LOG[EMAIL] : SMTP not configured, printing instead of sending.\n  to={to_email}\n  subject={subject}\n  body={body}")
        return

    msg = EmailMessage()
    msg["Subject"] = subject
    msg["From"] = SMTP_FROM
    msg["To"] = to_email
    msg.set_content(body)
    if html_body:
        msg.add_alternative(html_body, subtype="html")

    try:
        context = ssl.create_default_context()
        with smtplib.SMTP(SMTP_HOST, SMTP_PORT) as server:
            server.starttls(context=context)
            server.login(SMTP_USER, SMTP_PASSWORD)
            server.send_message(msg)
    except Exception as e:
        _safe_print(f"LOG[EMAIL] : send failed ({to_email}): {e}")


def build_verification_code_email(code: str, expire_minutes: int) -> str:
    """인증코드 메일용 HTML. 연령대가 높은 사용자도 한눈에 알아보도록
    글자를 크게 하고, 설명은 핵심만 한두 문장으로 줄인다."""
    return f"""\
<!DOCTYPE html>
<html lang="ko">
  <body style="margin:0; padding:32px 16px; background-color:#f4f5f7;
               font-family:'Apple SD Gothic Neo','Malgun Gothic',Arial,sans-serif;">
    <table role="presentation" width="100%" cellpadding="0" cellspacing="0">
      <tr>
        <td align="center">
          <table role="presentation" width="100%" style="max-width:420px;" cellpadding="0" cellspacing="0">
            <tr>
              <td style="background-color:#ffffff; border-radius:16px; padding:36px 28px; text-align:center;">
                <p style="margin:0 0 8px; font-size:17px; color:#333333;">
                  비밀번호를 다시 만들기 위한 번호예요.
                </p>
                <p style="margin:0 0 28px; font-size:17px; color:#333333;">
                  아래 숫자 6자리를 앱에 그대로 입력해 주세요.
                </p>
                <div style="background-color:#eef3ff; border-radius:12px; padding:20px 12px; margin-bottom:24px;">
                  <span style="font-size:40px; font-weight:700; letter-spacing:8px; color:#1a56db;">
                    {code}
                  </span>
                </div>
                <p style="margin:0; font-size:15px; color:#888888;">
                  {expire_minutes}분이 지나면 이 번호는 사용할 수 없어요.<br>
                  시간이 지났다면 앱에서 다시 요청해 주세요.
                </p>
              </td>
            </tr>
            <tr>
              <td style="padding:20px 8px 0; text-align:center;">
                <p style="margin:0; font-size:13px; color:#aaaaaa;">
                  본인이 요청하지 않았다면 이 메일은 그냥 무시해 주세요.<br>
                  IDCool Systems
                </p>
              </td>
            </tr>
          </table>
        </td>
      </tr>
    </table>
  </body>
</html>
"""
