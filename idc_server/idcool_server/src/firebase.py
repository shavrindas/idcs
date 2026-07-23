import asyncio
from firebase_admin import messaging

async def send_multicast_fcm(tokens: list[str], title: str, body: str):
    if not tokens:
        return

    message = messaging.MulticastMessage(
        notification=messaging.Notification(title=title, body=body),
        tokens=tokens, # 토큰 리스트 [token1, token2, ...]
    )
    
    # 한번에 최대 500개 토큰까지 전송 가능
    response = await asyncio.to_thread(messaging.send_each_for_multicast, message)
    print(f"[FCM 다중 전송] 성공: {response.success_count}건, 실패: {response.failure_count}건")