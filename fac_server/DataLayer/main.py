import threading
import time
import InitData as ID
from typing import Dict

import Command_Layer.Command as CM
import Machine_Layer.Machine_Transmission as MT
import Data_Layer.DataList as DL
import Mapping_Layer.Mapping as MP
import Ethernet_Layer.Ethernet as ET
import config 

#컨피그 설정 적용
#------------------------------------------------------------------------------------------
ET.uri = f"ws://127.0.0.1:8000/api/facilities/data/set/{config.facility_id}"
#------------------------------------------------------------------------------------------

ID.init()
DL.sort_LS_addresses()

comm_list = CM.separate_addr(DL.LS_addr_list)
print(comm_list)

data_list: Dict[str, int] = {}

framenum = 0
framelist: Dict[int, CM.LS_Command] = {}

#동적 값들 받는 루프
def Dynamic_EnQueue_Loop():
    global framenum
    while True:
        for i in comm_list:
            MT.send_queue.put((framenum, i.comm)) # A 명령어
            framelist[framenum] = i
            if framenum < 1000:
                framenum += 1
            else:
                framenum = 0

        # 수신 큐 확인
        try:
            while True:
                response_data = MT.recv_queue.get_nowait()
                frameind = int(response_data[0])
                MP.insert_data(framelist[frameind].addr, response_data[1])
        except MT.queue.Empty:
            pass

        time.sleep(1)

try:
    comm_thread = threading.Thread(target=MT.background_serial_worker, daemon=True)
    comm_thread.start()

    queue_thread = threading.Thread(target=Dynamic_EnQueue_Loop, daemon=True)
    queue_thread.start()

    ET.Ethernet_Run(AdrMap=MP.LabelMap)

    while True:
        time.sleep(1)

except KeyboardInterrupt:
    print("\n[Main] 종료 요청 감지")
    
finally:
    stop_communication = True
    comm_thread.join(timeout=2)
    if MT.ser.is_open:
        MT.ser.close()
    print("프로그램 완전히 종료됨")