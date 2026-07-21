import re
from typing import Dict

# LS주소 구조 (채널: [[부울], [정수]])
LS_addr_list: Dict[int, list[list[str]]] = {}
LS_addr_static_list: Dict[int, list[list[str]]] = {}

def add_LS_addr(addr: str):
    chan = int(addr[:2]) 
    adr = addr[2:]   

    if chan not in LS_addr_list:
        LS_addr_list[chan] = [[], []]

    if adr[2] == "X" and not adr in LS_addr_list[chan][0]:
        LS_addr_list[chan][0].append(adr)  # 부울 영역에 추가
    if adr[2] == "W" and not adr in LS_addr_list[chan][1]:
        LS_addr_list[chan][1].append(adr)  # 정수 영역에 추가

def add_LS_static_addr(addr: str):
    chan = int(addr[:2]) 
    adr = addr[2:]   

    if chan not in LS_addr_static_list:
        LS_addr_static_list[chan] = [[], []]

    if adr[2] == "X" and not adr in LS_addr_static_list[chan][0]:
        LS_addr_static_list[chan][0].append(adr)  # 부울 영역에 추가
    if adr[2] == "W" and not adr in LS_addr_static_list[chan][1]:
        LS_addr_static_list[chan][1].append(adr)  # 정수 영역에 추가

def sort_LS_addresses():
    global LS_addr_list, LS_addr_static_list

    def extract_number(addr_str: str) -> int:
        match = re.search(r'\d+', addr_str)
        return int(match.group()) if match else 0

    LS_addr_list = dict(sorted(LS_addr_list.items()))
    for chan in LS_addr_list:
        LS_addr_list[chan][0].sort(key=extract_number)  # 부울 리스트 정렬
        LS_addr_list[chan][1].sort(key=extract_number)  # 정수 리스트 정렬

    LS_addr_static_list = dict(sorted(LS_addr_static_list.items()))
    for chan in LS_addr_static_list:
        LS_addr_static_list[chan][0].sort(key=extract_number)
        LS_addr_static_list[chan][1].sort(key=extract_number)