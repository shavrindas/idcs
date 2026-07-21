import asyncio
import websockets
import json
import time

uri = ""

async def send_periodic_data(ws, AdrMap):
    # 💡 무한 루프는 내부 비동기 태스크가 살아있는 동안만 유지되도록 설정
    while True:
        payload = AdrMap
        await ws.send(json.dumps(payload))
        await asyncio.sleep(1)  # 1초 주기

async def receive_server_commands(ws):
    async for message in ws:
        packet = json.loads(message)
        
        if packet.get("type") == "COMMAND_REQUEST":
            req_id = packet.get("request_id")
            print(f"📩 사용자 요청 들어옴! [ID: {req_id}]")
            
            # 조회 결과를 서버로 즉시 응답
            response = {
                "type": "COMMAND_RESPONSE",
                "request_id": req_id,
                "data": {"40005": 1024}
            }
            await ws.send(json.dumps(response))

async def Ethernet_Loop(AdrMap):
    # 💡 [핵심] 연결 끊김을 감지하고 무한히 재시도하는 루프
    while True:
        try:
            print(f"🔄 서버 웹소켓 연결 시도 중... ({uri})")
            
            async with websockets.connect(
                uri, 
                ping_interval=None, 
                ping_timeout=None
            ) as ws:
                print("✅ 서버 웹소켓 연결 완료")
                await asyncio.gather(
                    send_periodic_data(ws, AdrMap),
                    receive_server_commands(ws)
                )
                
        except (websockets.exceptions.ConnectionClosed, ConnectionRefusedError, OSError) as e:
            # 서버가 꺼져있거나(Refused), 네트워크가 단선되었을 때(OSError) 잡히는 예외구간
            print(f"❌ 웹소켓 연결 유실 또는 실패: {e}")
            print("⏳ 3초 후 재연결을 시도합니다...")
            await asyncio.sleep(3)  # 3초간 비동기 대기 후 while문 처음으로 돌아가 재연결 실행
            
        except Exception as e:
            # 기타 예상치 못한 에러가 나더라도 루프가 완전히 죽지 않도록 방어
            print(f"⚠️ 예상치 못한 에러 발생: {e}")
            await asyncio.sleep(3)

def Ethernet_Run(AdrMap):
    print(uri)
    asyncio.run(Ethernet_Loop(AdrMap))