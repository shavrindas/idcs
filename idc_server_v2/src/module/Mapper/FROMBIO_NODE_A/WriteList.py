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
'''
for room in range(0, config.room_count - 1):
    MappingData((f"{config.room_start_id + room:02d}.control_runsw", f"02%MX40{room}0/1"))
    MappingData((f"{config.room_start_id + room:02d}.control_efa", f"02%MX40{room}2/1"))
    MappingData((f"{config.room_start_id + room:02d}.control_tica", f"02%MX40{room}3/1"))
    MappingData((f"{config.room_start_id + room:02d}.temp_sv", f"02%DW7{room + 1}20/0.1"))
    MappingData((f"{config.room_start_id + room:02d}.temp_hey", f"02%DW7{room + 1}21/0.1"))

for room in range(0, config.room3_count - 1):
    MappingData((f"{config.room3_start_id + room:02d}.control_runsw", f"03%MX40{room}0/1"))
    MappingData((f"{config.room3_start_id + room:02d}.control_efa", f"03%MX40{room}2/1"))
    MappingData((f"{config.room3_start_id + room:02d}.control_tica", f"03%MX40{room}3/1"))
    MappingData((f"{config.room3_start_id + room:02d}.temp_sv", f"03%DW7{room + 1}20/0.1"))
    MappingData((f"{config.room3_start_id + room:02d}.temp_hey", f"03%DW7{room + 1}21/0.1"))'''