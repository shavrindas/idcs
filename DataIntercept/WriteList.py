import config

from typing import Dict, Tuple
DataLists:Dict[str, str] = {}

def MappingData(adr: tuple):
    DataLists[adr[0]] = adr[1]

for room in range(0, config.room_count - 1):
    MappingData((f"{config.room_start_id + room:02d}.control_runsw", f"01%MX40{room}0/1"))
    MappingData((f"{config.room_start_id + room:02d}.control_efa", f"01%MX40{room}2/1"))
    MappingData((f"{config.room_start_id + room:02d}.control_tica", f"01%MX40{room}3/1"))
    MappingData((f"{config.room_start_id + room:02d}.temp_sv", f"01%DW7{room + 1}20/0.1"))
    MappingData((f"{config.room_start_id + room:02d}.temp_hey", f"01%DW7{room + 1}21/0.1"))