from typing import Dict, Tuple
DataLists:Dict[str, str] = {}

def MappingData(adr: tuple):
    DataLists[adr[0]] = adr[1]

MappingData(("21.control_runsw", "01%MX4050/1"))
MappingData(("21.temp_sv", "01%DW7620/0.1"))