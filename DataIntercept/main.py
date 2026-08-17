import asyncio
import socket
import config as config
import DataMap as DM
import DataList as DL
from typing import Dict
import Ethernet as ET
import re
import threading
import time, json
from DataList import DataFormat as Formats
import math
from datetime import datetime, timedelta
from categories import category as CT

# ---------------------------------------------------------
# 1. 스레드 동시성 제어를 위한 Lock 객체 및 설정
# ---------------------------------------------------------
data_lock = threading.Lock()

# 컨피그 설정 적용
ET.uri = f"ws://{config.endpoint}/api/facilities/data/set/{config.facility_id}"

client_socket = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
server_address = ('211.55.127.239', 4000)

# 서버 소켓 접속
client_socket.connect(server_address)

init_data = f"LGI\xFFjsm\xFF9502\xFFFalse\n"
categorized_data: Dict[str, Dict[str, Formats]] = {}
labled_data: Dict[str, int] = {}
cashed_data: Dict[str, Dict[str, Formats]] = {}

try:
    client_socket.send(init_data.encode())
except Exception as err:
    print(f"초기 데이터 송신 중 에러 발생: {err}")

def start_ethernet_thread():
    # 백그라운드 스레드 시작
    ET.Ethernet_Run(AdrMap=labled_data, sock=client_socket)

eth_thread = threading.Thread(target=start_ethernet_thread, daemon=True)
eth_thread.start()

def calculate_periodic_stats():
    print("⏰ 통계 타이머 스레드가 동기화를 시작합니다.")
    
    while True:
        next_minute = datetime.now() + timedelta(minutes=0.1)
        remaining_seconds = (next_minute - datetime.now()).total_seconds()
        
        time.sleep(remaining_seconds)
        
        with data_lock:
            current_time_str = datetime.now().strftime("%H:%M:%S")
            print(f"\n📊 [{current_time_str} - 통계 집계 시작]")
            json_ready_data = {}
            
            for cate, lab_dict in categorized_data.items():
                json_ready_data[cate] = {}
                if cate == CT.bool_logs or cate == CT.real_static_logs:
                    for lab, fmt in lab_dict.items():
                        if fmt.vals: # 데이터가 있을 때만 처리
                            print(f"[{cate} > {lab}] 값: {fmt.vals[-1]}")
                            tmpval = fmt.to_dict(is_bool=True)

                            if cate in cashed_data and lab in cashed_data[cate]:
                                if cashed_data[cate][lab] != tmpval:
                                    json_ready_data[cate][lab] = tmpval
                                    if not cate in cashed_data:
                                        cashed_data[cate] = {}
                                    cashed_data[cate][lab] = tmpval
                            else:
                                json_ready_data[cate][lab] = tmpval
                                if not cate in cashed_data:
                                    cashed_data[cate] = {}
                                cashed_data[cate][lab] = tmpval
                            
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
            ET.send_queue.put(json_string)

# 통계 계산 스레드 시작 (데몬 스레드로 지정하여 메인 종료시 함께 종료)
stats_thread = threading.Thread(target=calculate_periodic_stats, daemon=True)
stats_thread.start()


# DataMaps 누락 확인 디버깅
for adr, deg, lab, _ in DL.DataLists:
    if adr not in DM.DataMaps:
        print("DataMaps 키 없음:", adr)

# 버퍼 기반 수신 함수
buffer = ""

while True:
    try:
        chunk = client_socket.recv(4096)
        
        if not chunk:
            print("상대방(서버)이 연결을 종료했습니다.")
            break

        buffer += chunk.decode('utf-8', errors='ignore')

        while "\n" in buffer:
            line, buffer = buffer.split("\n", 1)
            
            data_parts = re.split(r"[ÿ|]", line)

            if len(data_parts) > 1:
                if "%" in data_parts[1]:
                    recvdata = data_parts[1].split("%")
                    if recvdata and recvdata[-1] == "":
                        recvdata.pop()

                    # 데이터 매핑 및 가공 (Lock으로 수신 데이터 안전하게 작성)
                    with data_lock:
                        for adr, deg, lab, cate in DL.DataLists:
                            if adr in DM.DataMaps:
                                idx = DM.DataMaps[adr]
                            
                                if idx < len(recvdata):
                                    try:
                                        raw_val = int(recvdata[idx])
                                        deg_str = str(deg)
                                        decimals = len(deg_str.split('.')[1]) if '.' in deg_str else 0
                                        tmp = round(raw_val * deg, decimals)

                                        # 💡 카테고리 / 라벨 키 존재 여부 안전 검사 및 초기화
                                        if cate not in categorized_data:
                                            categorized_data[cate] = {}
                                        
                                        if lab not in categorized_data[cate]:
                                            # 최초 수신 시 Formats 인스턴스 생성
                                            categorized_data[cate][lab] = Formats()

                                        # 통계 데이터 누적
                                        target = categorized_data[cate][lab]
                                        target.vals.append(tmp)
                                        target.val_sum += tmp
                                        target.count += 1

                                        if target.val_max < tmp:
                                            target.val_max = tmp
                                        if target.val_min > tmp:
                                            target.val_min = tmp

                                        labled_data[lab] = tmp
                                    except ValueError:
                                        pass
                                else:
                                    print(f"인덱스 초과 에러 - 주소: {adr}, 지시 인덱스: {idx}, 수신 개수: {len(recvdata)}")

                if "AWr" in data_parts[0]:
                    print(f"🎯 장비로부터 AWr 응답 감지: {line.strip()}")
                
                    ET.device_response_data["status"] = "SUCCESS"
                    ET.device_response_data["raw_line"] = line
                
                    ET.loop.call_soon_threadsafe(ET.device_response_event.set)
                    continue

    except ConnectionResetError:
        print("상대방과의 연결이 강제로 끊겼습니다.")
        break
    except Exception as err:
        import traceback
        print(f"수신 처리 중 에러 발생: {err}")
        traceback.print_exc()

client_socket.close()