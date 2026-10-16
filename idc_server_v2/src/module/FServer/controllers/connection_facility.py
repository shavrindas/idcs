# ===============================================================
# 경로 : src/module/FServer/controllers/Ethernet.py
# 명세 : FServer에서 시설 서버의 데이터를 인계받는 모듈
# ===============================================================

import src.module.FServer.config as config
import asyncio
import re
import src.module.Mapper.Ethernet_Mapper as EM
import src.module.Mapper.Label_Mapper as LM
from src.module.Mapper.Label_Mapper import DataFormat as Formats
from src.module.Mapper.categories import et_category as CT
import threading
from datetime import datetime, time, timedelta
import math
import json
from typing import Dict
import queue

class Ethernet:
    def __init__(self):
        self.payload_queue = queue.Queue()
        self.categorizedpayload = {}
        #스레드 동시성 제어를 위한 Lock 객체 및 설정
        self.data_lock = threading.Lock()
        self.buffer = ""
        self.cashed_data: Dict[str, Dict[str, Formats]] = {}
        self.reader = None
        self.writer = None
        self.to_Cserver = queue.Queue()
        self.device_response_event = None
        self.device_response_data = {"status": "FAIL", "raw_line": ""}
        self.loop = None
    async def to_facility_connect(self):
        # 실제 장비와의 연결부
        while True:
            try:
                self.reader, self.writer = await asyncio.open_connection('211.55.127.239', 4000)
                self.device_response_event = asyncio.Event()
                self.loop = asyncio.get_running_loop()
            except (ConnectionRefusedError, OSError):
                print("[FServer] 서버 연결 거부됨. 5초 후 재시도합니다...")
                await asyncio.sleep(5)
                continue
            except ConnectionResetError:
                print("[FServer] 상대방과의 연결이 강제로 끊겼습니다. 5초 후 재시도합니다...")
                await asyncio.sleep(5)
                continue
            
            print(f"[FServer] 인터넷 연결 완료")
    
            # 레거시 인증부        
            try:
                self.writer.write(config.init_data.encode())
                await self.writer.drain()
            except Exception as err:
                print(f"[FServer] 초기 데이터 송신 중 에러 발생: {err}")
                try:
                    self.writer.close()
                    await self.writer.wait_closed()
                except:
                    pass
                await asyncio.sleep(5)
                continue

            # 연결 루프부
            try:
                while True:
                    # 💡 1. 바이트로 읽기
                    data_bytes = await self.reader.read(4096)
                    
                    # 💡 2. 상대방이 연결을 끊었을 때 (EOF)
                    if not data_bytes:
                        print("[FServer] 상대방이 연결을 종료했습니다.")
                        break
                    
                    # 💡 3. 문자열로 디코딩 후 메시지 처리 함수로 전달
                    msg = data_bytes.decode('utf-8', errors='ignore')
                    await self.processmessage(msg)
                    
            except Exception as err:
                import traceback
                print(f"수신 처리 중 에러 발생: {err}")
                traceback.print_exc()

            # 연결 종료부
            finally:
                try:
                    self.writer.close()
                    await self.writer.wait_closed()
                except:
                    pass
            await asyncio.sleep(5)

    #들어온 메시지 처리
    async def processmessage(self, msg):
        if not msg:
            return
        
        self.buffer += msg
        #앞뒤 명령코드 분할
        while "\n" in self.buffer:
            line, self.buffer = self.buffer.split("\n", 1)
            
            data_parts = re.split(r"[ÿ|]", line)

            if len(data_parts) <= 1:
                continue

            #데이터 처리
            if "%" in data_parts[1]:
            #데이터일 경우
                recvdata = data_parts[1].split("%")
                if recvdata and recvdata[-1] == "":
                    recvdata.pop()
                
                with self.data_lock:
                    instant_payload = {}
                    for adr, deg, lab, cate in LM.DataLists:
                        #이더넷에서 온 인덱스 찾기
                        if not adr in EM.DataMaps:
                            continue
                        idx = EM.DataMaps[adr]
                        
                        if not idx < len(recvdata):
                            print(f"인덱스 초과 에러 - 주소: {adr}, 지시 인덱스: {idx}, 수신 개수: {len(recvdata)}")
                            continue

                        try:
                            raw_val = int(recvdata[idx])
                            deg_str = str(deg)
                            decimals = len(deg_str.split('.')[1]) if '.' in deg_str else 0
                            tmp = round(raw_val * deg, decimals)

                            # 💡 카테고리 / 라벨 키 존재 여부 안전 검사 및 초기화
                            if cate not in self.categorizedpayload:
                                self.categorizedpayload[cate] = {}
                            
                            if lab not in self.categorizedpayload[cate]:
                                # 최초 수신 시 Formats 인스턴스 생성
                                self.categorizedpayload[cate][lab] = Formats()

                            # 통계 데이터 누적
                            target = self.categorizedpayload[cate][lab]
                            target.vals.append(tmp)
                            target.val_sum += tmp
                            target.count += 1

                            if target.val_max < tmp:
                                target.val_max = tmp
                            if target.val_min > tmp:
                                target.val_min = tmp

                            instant_payload[lab] = tmp
                        except ValueError:
                            pass
                    
                    if instant_payload:
                        self.payload_queue.put({"datas": instant_payload})
                
                #print(self.payload)

            if "AWr" in data_parts[0]:
                print(f"🎯 장비로부터 AWr 응답 감지: {line.strip()}")
                
                self.device_response_data["status"] = "SUCCESS"
                self.device_response_data["raw_line"] = line
                
                self.loop.call_soon_threadsafe(self.device_response_event.set)
                continue

    async def send_to_facility(self, msg, req_id, req_val):
        self.device_response_data = {"status": "FAIL", "raw_line": ""}
        if self.writer and msg:
            try:
                # 1. 이벤트 및 데이터 초기화
                self.device_response_event.clear()
                self.device_response_data["status"] = "FAIL"
                self.device_response_data["raw_line"] = ""
                
                # 2. TCP 소켓으로 데이터 전송
                self.writer.write(msg)
                await self.writer.drain()
        
                # 3. 메인 루프에서 'AWr'을 찾아서 이벤트를 깨울 때까지 대기 (최대 3초 타임아웃)
                await asyncio.wait_for(self.device_response_event.wait(), timeout=3.0)
                
                print(f"🚀 응답 신호 매칭 완료! 이어서 진행합니다.")

                response = {
                    "type": "COMMAND_RESPONSE",
                    "request_id": req_id,
                    "request_val": req_val,
                    "status": self.device_response_data["status"],
                    "raw_response": self.device_response_data["raw_line"].strip()
                }

                self.payload_queue.put(response)
                
            except asyncio.TimeoutError:
                print("❌ 장비 응답 타임아웃: 3초 동안 AWr이 들어오지 않았습니다.")
            except Exception as e:
                print(f"❌ 장비 소켓 전송 에러: {e}")


    #저장된 페이로드 반환
    async def get_current_payload(self):
        if not self.payload_queue.empty():
            tmp = self.payload_queue.get()

            self.payload_queue.task_done()
            
            return tmp
        else:
            return {}

    async def calculate_periodic_stats(self):
        print("⏰ 통계 타이머 스레드가 동기화를 시작합니다.")
        
        while True:
            next_minute = datetime.now() + timedelta(minutes=1)
            remaining_seconds = (next_minute - datetime.now()).total_seconds()
            
            await asyncio.sleep(remaining_seconds)
            
            with self.data_lock:
                current_time_str = datetime.now().strftime("%H:%M:%S")
                print(f"\n📊 [{current_time_str} - 통계 집계 시작]")
                json_ready_data = {}
                
                for cate, lab_dict in self.categorizedpayload.items():
                    json_ready_data[cate] = {}
                    if cate == CT.bool_logs or cate == CT.real_static_logs:
                        for lab, fmt in lab_dict.items():
                            if fmt.vals: # 데이터가 있을 때만 처리
                                print(f"[{cate} > {lab}] 값: {fmt.vals[-1]}")
                                tmpval = fmt.to_dict(is_bool=True)
    
                                # 기존 캐시된 값 확인 (없으면 None)
                                cached_val = self.cashed_data.get(cate, {}).get(lab)

                                # 값이 다를 경우에만(또는 데이터가 아예 없을 경우에만) 업데이트
                                if cached_val != tmpval:
                                    # json_ready_data에 안전하게 키 생성 및 값 할당
                                    if cate not in json_ready_data:
                                        json_ready_data[cate] = {}
                                    json_ready_data[cate][lab] = tmpval

                                    # cashed_data에 안전하게 키 생성 및 값 할당
                                    if cate not in self.cashed_data:
                                        self.cashed_data[cate] = {}
                                    self.cashed_data[cate][lab] = tmpval
                                
                                fmt.vals.clear()
                            else:
    
                                fmt.vals.clear()
                    else:
                        for lab, fmt in lab_dict.items():
                            n = fmt.count
                            if n > 0:
                                mean_val = fmt.val_sum / n
                                variance = sum((x - mean_val) ** 2 for x in fmt.vals) / n
                            
                                fmt.val_mean = round(mean_val, 2)
                                fmt.val_var = round(variance, 4)
                            
                                fmt.val_std = round(math.sqrt(variance), 4)
    
                                print(f"[{cate} > {lab}] 개수:{n} | 평균:{fmt.val_mean} | 분산:{fmt.val_var} | 최소:{fmt.val_min} | 최대:{fmt.val_max}")
    
                                json_ready_data[cate][lab] = fmt.to_dict(is_bool=False)
    
                                fmt.vals.clear()
                                fmt.val_sum = 0.0
                                fmt.count = 0
                                fmt.val_max = float('-inf')
                                fmt.val_min = float('inf')
    
                print(f"✅ [{current_time_str} - 1분 통계 집계 완료]\n")
    
                json_ready_data["time"] = datetime.now().strftime("%Y-%m-%d %H:%M:%S")
    
                json_string = json.dumps(json_ready_data, ensure_ascii=False)

                self.payload_queue.put(json_string)


facility_ethernet = Ethernet()