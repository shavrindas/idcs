import src.module.Mapper.config as config

from typing import Dict, Tuple
DataLists:Dict[str, str] = {}

def MappingData(adr: tuple):
    DataLists[adr[0]] = adr[1]

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
    MappingData((f"{config.room3_start_id + room:02d}.temp_hey", f"03%DW7{room + 1}21/0.1"))