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


def send_email(to_email: str, subject: str, body: str) -> None:
    """실패해도 호출부의 흐름(코드 발급 자체)을 막지 않도록 예외를 삼키고 로그만 남긴다."""
    if not is_email_configured():
        _safe_print(f"LOG[EMAIL] : SMTP not configured, printing instead of sending.\n  to={to_email}\n  subject={subject}\n  body={body}")
        return

    msg = EmailMessage()
    msg["Subject"] = subject
    msg["From"] = SMTP_FROM
    msg["To"] = to_email
    msg.set_content(body)

    try:
        context = ssl.create_default_context()
        with smtplib.SMTP(SMTP_HOST, SMTP_PORT) as server:
            server.starttls(context=context)
            server.login(SMTP_USER, SMTP_PASSWORD)
            server.send_message(msg)
    except Exception as e:
        _safe_print(f"LOG[EMAIL] : send failed ({to_email}): {e}")
