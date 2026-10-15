# ===============================================================
# 경로 : src/module/FServer/controllers/connection_manager.py
# 명세 : FServer에서 중앙 CServer와의 연결을 관리하는 모듈
# ===============================================================

import asyncio
import aiohttp
import websockets
import json
import os
from src.module.FServer.controllers.connection_facility import facility_ethernet as facilityconn
from src.module.Mapper.WriteList import DataLists as RD
import queue

CENTER_API_URL = os.getenv("CENTER_API_URL", "http://127.0.0.1:8900/api/v1/cserver/sys-auth/login")
CENTER_WS_URL = os.getenv("CENTER_WS_URL", "ws://127.0.0.1:8900/api/v1/cserver/data-stream")
NODE_CODE = os.getenv("NODE_CODE", "NODE_001")
API_KEY = os.getenv("API_KEY", "dummy_api_key_123")

class FacilityConnectionManager:
    def __init__(self):
        self.token = None
        self.facility_id = None
        self.is_connected = False
        self.active_ws = None
        
    async def authenticate(self):
        async with aiohttp.ClientSession() as session:
            try:
                print(f"[FServer] 중앙 계정 시스템 인증 시도... ({NODE_CODE})")
                async with session.post(CENTER_API_URL, json={
                    "node_code": NODE_CODE,
                    "api_key": API_KEY
                }) as resp:
                    if resp.status == 200:
                        data = await resp.json()
                        self.token = data["access_token"]
                        self.facility_id = data["facility_id"]
                        print(f"[FServer] 시스템 인증 완료! 위임 토큰 발급됨 (Facility ID: {self.facility_id})")
                        return True
                    else:
                        print(f"[FServer] 인증 실패: HTTP {resp.status}")
                        return False
            except Exception as e:
                print(f"[FServer] 인증 서버 접근 불가: {e}")
                return False

    async def maintain_connection(self):
        while True:
            if not self.token:
                success = await self.authenticate()
                if not success:
                    await asyncio.sleep(3)
                    continue

            headers = {"X-System-Token": self.token}
            ws_url = f"{CENTER_WS_URL}/{self.facility_id}?token={self.token}"
            recv_task = None

            try:
                print(f"🔄 [FServer] 중앙 데이터 스트리밍 연결 시도 중... ({ws_url})")
                try:
                    ws_ctx = websockets.connect(ws_url, additional_headers=headers)
                except TypeError:
                    ws_ctx = websockets.connect(ws_url, extra_headers=headers)

                async with ws_ctx as ws:
                    static_task = asyncio.create_task(facilityconn.calculate_periodic_stats())
                    recv_task = asyncio.create_task(self.receive_loop(ws))
                    self.active_ws = ws
                    self.is_connected = True
                    print(f"[FServer] 중앙 시스템과 데이터 연결 확립 (Facility ID: {self.facility_id})")
                    
                    while True:
                        payload = json.dumps(await facilityconn.get_current_payload())
                        if payload:
                            await ws.send(payload)
                        
                        await asyncio.sleep(0.5)
                        
            except websockets.exceptions.ConnectionClosed as e:
                self.is_connected = False
                self.active_ws = None
                print(f"[FServer] 통신 단절 (Code: {e.code}, Reason: {e.reason})")
                if e.code == 4001:
                    print("[FServer] 시스템 토큰 만료됨. 재인증을 요청합니다.")
                    self.token = None 
            except asyncio.CancelledError:
                # Lifespan 종료 시 호출
                await self.graceful_shutdown()
                break
            except Exception as e:
                self.is_connected = False
                self.active_ws = None
                print(f"[FServer] 예상치 못한 네트워크 에러: {e}")
            finally:
                # 연결이 끊겼을 때(에러나 정상 종료 포함) 백그라운드 수신 태스크도 확실히 종료시킴
                if recv_task and not recv_task.done():
                    recv_task.cancel()
                if static_task and not static_task.done():
                    static_task.cancel()
            
            await asyncio.sleep(3)

    #명령 받기용 루프
    async def receive_loop(self, ws):
        while True:
            try:
                # 데이터가 올 때까지 비동기로 대기하다가 받음
                message = await ws.recv()

                packet = json.loads(message)

                if packet.get("type") == "WR":
                    req_id = packet.get("req_id")
                    req_val = packet.get("req_val")
                    print(f"📩 사용자 요청 들어옴! [ID: {req_id}, Val: {req_val}]")

                    cmd_text = f"Wr\xFF{RD[req_id]}^{req_val}\n"
                    cmd_bytes = cmd_text.encode('utf-8', errors='ignore')

                    await facilityconn.send_to_facility(cmd_bytes, req_id, req_val)
                    
            except Exception as e:
                print(f"수신 에러: {e}")
                await asyncio.sleep(1)

    async def graceful_shutdown(self):
        """프로세스 종료 시 중앙에 정상 종료를 알림"""
        if self.active_ws and not self.active_ws.closed:
            try:
                print("[FServer] 중앙 서버에 정상 종료 통보 전송 중...")
                await self.active_ws.send("__SHUTDOWN__")
                await self.active_ws.close()
            except Exception:
                pass
        self.is_connected = False

fserver_conn_manager = FacilityConnectionManager()