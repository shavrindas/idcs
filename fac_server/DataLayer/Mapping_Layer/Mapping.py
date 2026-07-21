from typing import Dict
from dataclasses import dataclass

@dataclass
class MapInfo():
    Adr: str
    degree: int

AdrMap: Dict[str, int] = {}
Adr_LabelMap: Dict[str, MapInfo] = {}
LabelMap: Dict[str, float] = {}

#받아온 응답에서 데이터 주소에 대입
def insert_data(adrs, response: bytes):
    if not response or not adrs:
        return

    if response[0] != 6:
        print("잘못된 제어문자 시작:", response[:1])
        print(response)
        return

    chan_str = response[1:3].decode()
    dresponse = response.decode()
    idx = 6 
    
    rlen = int(dresponse[idx:idx+2], 16)
    idx += 2

    chan_prefix = f"{int(chan_str):02d}"
    limit = min(rlen, len(adrs))
    
    for i in range(limit):
        if len(dresponse) - idx <= 2:
            break
            
        slen = int(dresponse[idx:idx+2], 16) * 2
        idx += 2

        if len(dresponse) - idx < slen:
            break
        
        tadr = f"{chan_prefix}{adrs[i]}"
        hex_segment = dresponse[idx:idx+slen]
        
        val = int.from_bytes(bytes.fromhex(hex_segment), byteorder='big', signed=True)
        
        AdrMap[tadr] = val
        if (label := Adr_LabelMap.get(tadr)) is not None:
            calculated_val = val * (10 ** label.degree)
            
            if label.degree < 0:
                LabelMap[label.Adr] = round(calculated_val, abs(label.degree))
            else:
                LabelMap[label.Adr] = calculated_val
            
        idx += slen  # 포인터 이동

def Mapping(adr: str, label: str, degree:int=0):
    Adr_LabelMap[adr] = MapInfo(label, degree)