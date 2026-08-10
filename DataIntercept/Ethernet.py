import asyncio
import websockets
import json
import time
from WriteList import DataLists as RD

# 💡 스레드 간 신호 공유를 위해 전역 변수로 유지하되 초기화는 내부에서 수행
device_response_event = None
device_response_data = {"status": "FAIL", "raw_line": ""}
loop = None  # 메인 비동기 루프 참조 객체

uri = ""

async def send_periodic_data(ws, AdrMap):
    while True:
        payload = {'datas': AdrMap}
        await ws.send(json.dumps(payload))
        await asyncio.sleep(1)  # 1초 주기

async def receive_server_commands(ws, sock):
    global device_response_event, device_response_data
    
    async for message in ws:
        packet = json.loads(message)
        
        if packet.get("type") == "WR":
            req_id = packet.get("req_id")
            req_val = packet.get("req_val")
            print(f"📩 사용자 요청 들어옴! [ID: {req_id}, Val: {req_val}]")

            cmd_text = f"Wr\xFF{RD[req_id]}^{req_val}\n"
            cmd_bytes = cmd_text.encode('utf-8', errors='ignore')
            
            if sock:
                try:
                    # 1. 이벤트 및 데이터 초기화
                    device_response_event.clear()
                    device_response_data["status"] = "FAIL"
                    device_response_data["raw_line"] = ""
                    
                    # 2. TCP 소켓으로 데이터 전송
                    await asyncio.to_thread(sock.sendall, cmd_bytes)
                    print(f"🚀 장비 소켓 전송 완료: {cmd_text.strip()}")
                    
                    # 3. 메인 루프에서 'AWr'을 찾아서 이벤트를 깨울 때까지 대기 (최대 3초 타임아웃)
                    await asyncio.wait_for(device_response_event.wait(), timeout=3.0)
                    
                    print(f"🚀 응답 신호 매칭 완료! 이어서 진행합니다.")
                    
                except asyncio.TimeoutError:
                    print("❌ 장비 응답 타임아웃: 3초 동안 AWr이 들어오지 않았습니다.")
                except Exception as e:
                    print(f"❌ 장비 소켓 전송 에러: {e}")
            
            # 4. 기다림이 끝난 후 최종 결과를 서버로 즉시 응답
            response = {
                "type": "COMMAND_RESPONSE",
                "request_id": req_id,
                "request_val": req_val,
                "status": device_response_data["status"],
                "raw_response": device_response_data["raw_line"].strip()
            }
            await ws.send(json.dumps(response))

async def Ethernet_Loop(AdrMap, sock):
    global device_response_event, loop
    
    # 💡 [핵심 해결책] 이 함수가 실행되는 시점은 asyncio.run()에 의해 
    # 비동기 이벤트 루프가 완벽히 생성된 이후이므로, 여기서 안전하게 취득합니다.
    loop = asyncio.get_running_loop()
    device_response_event = asyncio.Event()
    
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
            print(f"❌ 웹소켓 연결 유실 또는 실패: {e}")
            print("⏳ 3초 후 재연결을 시도합니다...")
            await asyncio.sleep(3)
            
        except Exception as e:
            print(f"⚠️ 예상치 못한 에러 발생: {e}")
            await asyncio.sleep(3)

def Ethernet_Run(AdrMap, sock):
    print(uri)
    asyncio.run(Ethernet_Loop(AdrMap, sock))