import asyncio
import websockets
import json
import time
from WriteList import DataLists as RD

uri = ""

async def send_periodic_data(ws, AdrMap):
    # 💡 무한 루프는 내부 비동기 태스크가 살아있는 동안만 유지되도록 설정
    while True:
        payload = {'datas': AdrMap}
        await ws.send(json.dumps(payload))
        #print(json.dumps(payload))
        await asyncio.sleep(1)  # 1초 주기

async def receive_server_commands(ws, sock):
    async for message in ws:
        packet = json.loads(message)
        
        if packet.get("type") == "WR":
            req_id = packet.get("req_id")
            req_val = packet.get("req_val")
            print(f"📩 사용자 요청 들어옴! [ID: {req_id, req_val}]")

            cmd_text = f"Wr\xFF{RD[req_id]}^{req_val}\n"
            cmd_bytes = cmd_text.encode('utf-8', errors='ignore')
            
            # 💡 TCP 소켓으로 데이터 전송 (비동기 루프 블로킹 방지)
            if sock:
                try:
                    await asyncio.to_thread(sock.sendall, cmd_bytes)
                    print(f"🚀 장비 소켓 전송 완료: {cmd_text.strip()}")
                except Exception as e:
                    print(f"❌ 장비 소켓 전송 실패: {e}")
            
            # 조회 결과를 서버로 즉시 응답
            response = {
                "type": "COMMAND_RESPONSE",
                "request_id": req_id,
                "request_val": req_val
            }
            await ws.send(json.dumps(response))

async def Ethernet_Loop(AdrMap, sock):
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
                    receive_server_commands(ws, sock)
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

def Ethernet_Run(AdrMap, sock):
    print(uri)
    asyncio.run(Ethernet_Loop(AdrMap, sock))