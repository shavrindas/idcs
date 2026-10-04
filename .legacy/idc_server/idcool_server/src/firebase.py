import asyncio
from firebase_admin import messaging

async def send_multicast_fcm(tokens: list[str], title: str, body: str):
    if not tokens:
        return

    message = messaging.MulticastMessage(
        data={
            "title": str(title),
            "body": str(body),
        },
        tokens=tokens,
        android=messaging.AndroidConfig(
            priority='high',
        ),
    )
    
    response = await asyncio.to_thread(messaging.send_each_for_multicast, message)
    print(f"[FCM 다중 전송] 성공: {response.success_count}건, 실패: {response.failure_count}건")