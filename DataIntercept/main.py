import socket
import config as config
import DataMap as DM
import DataList as DL
from typing import Dict
import Ethernet as ET
import re
import threading

# 컨피그 설정 적용
ET.uri = f"ws://{config.endpoint}/api/facilities/data/set/{config.facility_id}"

client_socket = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
server_address = ('211.55.127.239', 4000)

# 서버 소켓 접속
client_socket.connect(server_address)

init_data = f"LGI\xFFjsm\xFF9502\xFFFalse\n"
labled_data: Dict[str, int] = {}

try:
    client_socket.send(init_data.encode())
except Exception as err:
    print(f"초기 데이터 송신 중 에러 발생: {err}")

def start_ethernet_thread():
    # 백그라운드 스레드 시작
    ET.Ethernet_Run(AdrMap=labled_data, sock=client_socket)

eth_thread = threading.Thread(target=start_ethernet_thread, daemon=True)
eth_thread.start()

# DataMaps 누락 확인 디버깅
for adr, deg, lab in DL.DataLists:
    if adr not in DM.DataMaps:
        print("DataMaps 키 없음:", adr)

# 버퍼 기반 수신 함수 (4096을 고정 대기하지 않고 받은 만큼 즉시 처리)
buffer = ""

while True:
    try:
        # 1024~4096 바이트 단위로 소켓 버퍼에서 있는 만큼 가져옴
        chunk = client_socket.recv(4096)
        
        if not chunk:
            print("상대방(서버)이 연결을 종료했습니다.")
            break

        # 수신 데이터를 버퍼에 누적
        buffer += chunk.decode('utf-8', errors='ignore')

        # 개행문자(\n) 단위로 완결된 데이터 패킷을 분리
        while "\n" in buffer:
            line, buffer = buffer.split("\n", 1)
            
            # 파싱 및 정제
            data_parts = re.split(r"[ÿ|]", line)

            if len(data_parts) > 1 and "%" in data_parts[1]:
                recvdata = data_parts[1].split("%")
                # 끝에 빈 문자열이 생기는 경우 제거
                if recvdata and recvdata[-1] == "":
                    recvdata.pop()

                # 데이터 매핑 및 가공
                for adr, deg, lab in DL.DataLists:
                    if adr in DM.DataMaps:
                        idx = DM.DataMaps[adr]
                        
                        # 인덱스 범위 안전 검사
                        if idx < len(recvdata):
                            try:
                                raw_val = int(recvdata[idx])
                                deg_str = str(deg)
                                decimals = len(deg_str.split('.')[1]) if '.' in deg_str else 0
                                labled_data[lab] = round(raw_val * deg, decimals)
                            except ValueError:
                                pass
                        else:
                            print(f"인덱스 초과 에러 - 주소: {adr}, 지시 인덱스: {idx}, 수신 개수: {len(recvdata)}")

    except ConnectionResetError:
        print("상대방과의 연결이 강제로 끊겼습니다.")
        break
    except Exception as err:
        print(f"수신 처리 중 에러 발생: {err}")

client_socket.close()