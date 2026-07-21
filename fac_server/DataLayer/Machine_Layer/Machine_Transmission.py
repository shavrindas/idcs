import serial
import time
import queue

# 스레드 안전한 FIFO 큐 생성
send_queue = queue.Queue(maxsize=200)
recv_queue = queue.Queue(maxsize=200)

# 시리얼 포트 설정
ser = serial.Serial(
    port='COM3',          
    baudrate=115200,        
    bytesize=serial.EIGHTBITS,
    parity=serial.PARITY_NONE,
    stopbits=serial.STOPBITS_ONE,
    timeout=1             
)

stop_communication = False

#RS485통신 루프(메시지 큐 방식)
def background_serial_worker():
    global stop_communication
    print("[BG] Serial Thread Started.")
    
    while not stop_communication:
        try:
            while True:
                try:
                    data_to_send = send_queue.get_nowait()
                except queue.Empty:
                    break
                
                framenum = int(data_to_send[0])
                real_send = data_to_send[1]

                ser.write(real_send.encode('ascii'))
                ser.flush()
                
                response = ser.read_until(expected=b'\x03')

                if response and response.endswith(b'\x03'):
                    recv_queue.put((framenum, response))
                    send_queue.task_done()
                else:
                    print(f"[BG] 통신 에러: '{real_send.strip()}'에 대한 응답에 \\x03가 없습니다.")
                    
                    ser.reset_input_buffer()

                    recv_queue.put((framenum, "ERROR_TIMEOUT"))
                    send_queue.task_done()

                    print("[BG] 남은 송신 대기열을 모두 취소합니다.")
                    try:
                        while True:
                            send_queue.get_nowait()
                            send_queue.task_done()
                    except queue.Empty:
                        pass
                    
                    break

        except Exception as e:
            print(f"[BG] Error: {e}")
            
        time.sleep(1.0)

    print("[BG] Serial Thread Stopped.")