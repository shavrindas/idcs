from . import config

from typing import Dict, Tuple
DataLists:Dict[str, str] = {}

def MappingData(adr: tuple):
    DataLists[adr[0]] = adr[1]

def mappingSet(chan: int, room_ind: int, room_number: int):
    MappingData((f"{room_number:02d}.control_runsw", f"{chan:02d}%MX40{room_ind}0/1"))
    MappingData((f"{room_number:02d}.control_efa", f"{chan:02d}%MX40{room_ind}2/1"))
    MappingData((f"{room_number:02d}.control_tica", f"{chan:02d}%MX40{room_ind}3/1"))
    MappingData((f"{room_number:02d}.temp_sv", f"{chan:02d}%DW7{room_ind + 1}20/0.1"))
    MappingData((f"{room_number:02d}.temp_hey", f"{chan:02d}%DW7{room_ind + 1}21/0.1"))


mappingSet(1, 0, 38)
mappingSet(1, 1, 39)
mappingSet(1, 2, 40)
mappingSet(1, 3, 41)
mappingSet(1, 4, 42)
mappingSet(2, 0, 42)
mappingSet(2, 1, 43)
mappingSet(2, 2, 44)
mappingSet(2, 3, 45)