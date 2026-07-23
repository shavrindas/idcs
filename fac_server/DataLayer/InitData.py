import Data_Layer.DataList as DL
import Mapping_Layer.Mapping as MP

room_id = 1
role_name = "temp"

#주소 및 매핑 레이블
MAPPING_DATA = {
    1: {  # room_id = 1
        "temp": [
            ("01%DW420", "pv", -1),
            ("01%DW421", "sv", -1),
            ("01%DW2421", "hey", -1),
            ("01%DW2420", "zero", -1),
            ("01%PX21", "comp", -1),
        ],
        "deforest": [
            ("01%DW59", "DFC"),
            ("01%DW57", "DFT"),
            ("01%CW11", "SYSH"),
            ("01%CW10", "SYSM"),
            ("01%PX2D", "def", -1),
        ],
        "emergency": [
            ("01%PX2F", "total", -1),
            ("01%MX0120", "cinteocr"),
            ("01%MX0125", "high"),
            ("01%MX012C", "fan"),
            ("01%MX0121", "lock"),
            ("01%MX0126", "press"),
            ("01%MX0122", "temp"),
            ("01%MX0127", "hot"),
            ("01%MX030E", "low"),
            ("01%MX0131", "rotation"),
        ],
        "inverter": [],
        "equipment": [
            ("01%DW0400", "comp1temp", -1),
            ("01%DW0300", "comp1press1", -1),
            ("01%DW0310", "comp1press2", -1),
            ("01%DW0405", "comp2temp", -1),
            ("01%DW0315", "comp2press1", -1),
            ("01%DW0326", "comp2press2", -1),
            ("01%DW0415", "transtemp", -1),
            ("01%PX20", "expan"),
            ("01%PX22", "expan2"),
            ("01%PX29", "expan3"),
        ],
        "control": [
            ("01%MX0000", "runsw"),
            ("01%CW0001", "runtime"),
            ("01%CW0004", "cruntime"),
            ("01%DW0001", "rundel", -1),
            ("01%DW0003", "compdel", -1),
            ("01%DW0036", "defdel", -1),
            ("01%DW0035", "cooldel", -1),
            ("01%MX000E", "rtc"),
            ("01%MX000B", "dth"),
            ("01%MX0006", "lsv"),
        ],
    },
}

# ==========================================
# 2. 실행 함수
# ==========================================
def init(target_room_id: int = None):
    for room_id, roles in MAPPING_DATA.items():
        # 특정 room_id만 필터링해서 처리하고 싶은 경우
        if target_room_id is not None and room_id != target_room_id:
            continue

        for role_name, items in roles.items():
            for item in items:
                adr = item[0]
                label = item[1]
                degree = item[2] if len(item) > 2 else 0

                DL.add_LS_addr(adr)
                MP.Mapping(adr, f"{room_id}.{role_name}_{label}", degree)