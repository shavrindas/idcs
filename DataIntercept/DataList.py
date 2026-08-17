import config
from categories import category as CT

class DataFormat:
    def __init__(self):
        self.vals = []
        self.val_sum = 0.0
        self.val_min = float('inf')
        self.val_max = float('-inf')
        self.val_mean = 0.0
        self.val_var = 0.0
        self.val_std = 0.0
        self.count: int = 0

    def to_dict(self, is_bool=False):
        """JSON 변환용 딕셔너리 생성"""
        if is_bool:
            return {
                "last_value": self.vals[-1] if self.vals else None
            }
        else:
            return {
                "val_mean": getattr(self, 'val_mean', 0.0),
                "val_var": getattr(self, 'val_var', 0.0),
                "val_std": getattr(self, 'val_std', 0.0),
                "val_max": None if self.val_max == float('-inf') else self.val_max,
                "val_min": None if self.val_min == float('inf') else self.val_min,
                "count": self.count
            }


DataLists = []

def MappingData(adr: tuple):
    DataLists.append(adr)

for room in range(0, config.room_count - 1):
    MappingData((f"C01_MX3{room * 3:02d}0", 1, f"{config.room_start_id + room:02d}.control_runsw", CT.bool_logs))
    MappingData((f"C01_MX3{room * 3:02d}1", 1, f"{config.room_start_id + room:02d}.emergency_cint", CT.bool_logs))
    MappingData((f"C01_MX3{room * 3:02d}2", 1, f"{config.room_start_id + room:02d}.emergency_high", CT.bool_logs))
    MappingData((f"C01_MX3{room * 3:02d}3", 1, f"{config.room_start_id + room:02d}.emergency_uf_ocr", CT.bool_logs))
    MappingData((f"C01_MX3{room * 3:02d}4", 1, f"{config.room_start_id + room:02d}.emergency_locked", CT.bool_logs))
    MappingData((f"C01_MX3{room * 3:02d}5", 1, f"{config.room_start_id + room:02d}.emergency_outtemp", CT.bool_logs))
    MappingData((f"C01_MX3{room * 3:02d}6", 1, f"{config.room_start_id + room:02d}.emergency_gas", CT.bool_logs))
    MappingData((f"C01_MX3{room * 3:02d}7", 1, f"{config.room_start_id + room:02d}.emergency_tempsensor", CT.bool_logs))
    MappingData((f"C01_MX3{room * 3:02d}8", 1, f"{config.room_start_id + room:02d}.emergency_defemg", CT.bool_logs))
    #MappingData((f"C01_MX3{room * 3:02d}9", 1, f"{config.room_start_id + room:02d}.emergency_lowsw"))
    MappingData((f"C01_MX3{room * 3:02d}A", 1, f"{config.room_start_id + room:02d}.control_hottic", CT.bool_logs))
    MappingData((f"C01_MX3{room * 3:02d}B", 1, f"{config.room_start_id + room:02d}.control_roomtemp", CT.bool_logs))
    MappingData((f"C01_MX3{room * 3:02d}C", 1, f"{config.room_start_id + room:02d}.temp_comp", CT.bool_logs))
    MappingData((f"C01_MX3{room * 3:02d}D", 1, f"{config.room_start_id + room:02d}.control_cffan1", CT.bool_logs))
    MappingData((f"C01_MX3{room * 3:02d}E", 1, f"{config.room_start_id + room:02d}.control_cffan2", CT.bool_logs))
    MappingData((f"C01_MX3{room * 3:02d}F", 1, f"{config.room_start_id + room:02d}.control_lsv", CT.bool_logs))
    MappingData((f"C01_MX3{room * 3 + 1:02d}0", 1, f"{config.room_start_id + room:02d}.control_ingsv", CT.bool_logs))
    MappingData((f"C01_MX3{room * 3 + 1:02d}1", 1, f"{config.room_start_id + room:02d}.control_uffan", CT.bool_logs))
    MappingData((f"C01_MX3{room * 3 + 1:02d}2", 1, f"{config.room_start_id + room:02d}.deforest_def", CT.bool_logs))
    MappingData((f"C01_MX3{room * 3 + 1:02d}3", 1, f"{config.room_start_id + room:02d}.emergency_emg", CT.bool_logs))
    MappingData((f"C01_MX3{room * 3 + 1:02d}4", 1, f"{config.room_start_id + room:02d}.control_tica", CT.bool_logs))
    MappingData((f"C01_MX3{room * 3 + 1:02d}5", 1, f"{config.room_start_id + room:02d}.control_efa", CT.bool_logs))
    MappingData((f"C01_MX3{room * 3 + 1:02d}6", 1, f"{config.room_start_id + room:02d}.control_heatdelflag", CT.bool_logs))
    MappingData((f"C01_MX3{room * 3 + 1:02d}7", 1, f"{config.room_start_id + room:02d}.control_initdelflag", CT.bool_logs))
    MappingData((f"C01_MX3{room * 3 + 1:02d}8", 1, f"{config.room_start_id + room:02d}.control_compdelflag", CT.bool_logs))
    #MappingData((f"C01_MX3{room * 3 + 1:02d}9", 1, f"{config.room_start_id + room:02d}.control_coolerdelflag"))
    MappingData((f"C01_MX3{room * 3 + 1:02d}A", 1, f"{config.room_start_id + room:02d}.control_mdf", CT.bool_logs))
    MappingData((f"C01_MX3{room * 3 + 1:02d}B", 1, f"{config.room_start_id + room:02d}.control_sw", CT.bool_logs))
    MappingData((f"C01_MX3{room * 3 + 1:02d}C", 1, f"{config.room_start_id + room:02d}.emergency_emgreset", CT.bool_logs))
    MappingData((f"C01_DW{room + 61:02d}00", 1, f"{config.room_start_id + room:02d}.equipment_temp1", CT.real_logs))
    MappingData((f"C01_DW{room + 61:02d}01", 1, f"{config.room_start_id + room:02d}.temp_pv", CT.real_logs))
    MappingData((f"C01_DW{room + 61:02d}02", 0.1, f"{config.room_start_id + room:02d}.temp_sv", CT.real_static_logs))
    MappingData((f"C01_DW{room + 61:02d}03", 1, f"{config.room_start_id + room:02d}.temp_hey", CT.real_static_logs))
    MappingData((f"C01_DW{room + 61:02d}04", 1, f"{config.room_start_id + room:02d}.temp_zero", CT.real_static_logs))
    MappingData((f"C01_DW{room + 61:02d}05", 1, f"{config.room_start_id + room:02d}.equipment_press1", CT.real_logs))
    MappingData((f"C01_DW{room + 61:02d}06", 1, f"{config.room_start_id + room:02d}.equipment_press2", CT.real_logs))
    MappingData((f"C01_DW{room + 61:02d}07", 1, f"{config.room_start_id + room:02d}.control_runtimelow", CT.real_logs))
    MappingData((f"C01_DW{room + 61:02d}08", 1, f"{config.room_start_id + room:02d}.control_runtimehigh", CT.real_logs))
    MappingData((f"C01_DW{room + 61:02d}09", 1, f"{config.room_start_id + room:02d}.deforest_dfcm", CT.real_static_logs))
    MappingData((f"C01_DW{room + 61:02d}10", 1, f"{config.room_start_id + room:02d}.deforest_dfct", CT.real_static_logs))
    MappingData((f"C01_DW{room + 61:02d}11", 1, f"{config.room_start_id + room:02d}.deforest_sysm", CT.real_logs))
    MappingData((f"C01_DW{room + 61:02d}12", 1, f"{config.room_start_id + room:02d}.deforest_syst", CT.real_logs))
    MappingData((f"C01_DW{room + 61:02d}13", 1, f"{config.room_start_id + room:02d}.control_initdelst", CT.real_static_logs))
    MappingData((f"C01_DW{room + 61:02d}14", 1, f"{config.room_start_id + room:02d}.control_compdelst", CT.real_static_logs))
    MappingData((f"C01_DW{room + 61:02d}15", 1, f"{config.room_start_id + room:02d}.control_cooldelst", CT.real_static_logs))
    MappingData((f"C01_DW{room + 61:02d}16", 1, f"{config.room_start_id + room:02d}.control_defdelst", CT.real_static_logs))
    MappingData((f"C01_DW{room + 61:02d}17", 1, f"{config.room_start_id + room:02d}.control_initdeltm", CT.real_logs))
    MappingData((f"C01_DW{room + 61:02d}18", 1, f"{config.room_start_id + room:02d}.control_compdeltm", CT.real_logs))
    MappingData((f"C01_DW{room + 61:02d}19", 1, f"{config.room_start_id + room:02d}.control_cooldeltm", CT.real_logs))
    MappingData((f"C01_DW{room + 61:02d}20", 1, f"{config.room_start_id + room:02d}.control_defdeltm", CT.real_logs))

MappingData((f"C11_0x4000A", 1, "16.inverter_hz", CT.real_logs))
MappingData((f"C11_0x4000D", 1, "16.inverter_kw", CT.real_logs))
MappingData((f"C11_0x4000B", 1, "16.inverter_outv", CT.real_logs))
MappingData((f"C11_0x40009", 1, "16.inverter_outa", CT.real_logs))
MappingData((f"C11_0x40005", 1, "16.inverter_outhz", CT.real_logs))

MappingData((f"C12_0x4000A", 1, "17.inverter_hz", CT.real_logs))
MappingData((f"C12_0x4000D", 1, "17.inverter_kw", CT.real_logs))
MappingData((f"C12_0x4000B", 1, "17.inverter_outv", CT.real_logs))
MappingData((f"C12_0x40009", 1, "17.inverter_outa", CT.real_logs))
MappingData((f"C12_0x40005", 1, "17.inverter_outhz", CT.real_logs))

MappingData((f"C13_0x4000A", 1, "18.inverter_hz", CT.real_logs))
MappingData((f"C13_0x4000D", 1, "18.inverter_kw", CT.real_logs))
MappingData((f"C13_0x4000B", 1, "18.inverter_outv", CT.real_logs))
MappingData((f"C13_0x40009", 1, "18.inverter_outa", CT.real_logs))
MappingData((f"C13_0x40005", 1, "18.inverter_outhz", CT.real_logs))

MappingData((f"C14_0x4000A", 1, "19.inverter_hz", CT.real_logs))
MappingData((f"C14_0x4000D", 1, "19.inverter_kw", CT.real_logs))
MappingData((f"C14_0x4000B", 1, "19.inverter_outv", CT.real_logs))
MappingData((f"C14_0x40009", 1, "19.inverter_outa", CT.real_logs))
MappingData((f"C14_0x40005", 1, "19.inverter_outhz", CT.real_logs))

MappingData((f"C15_0x4000A", 1, "20.inverter_hz", CT.real_logs))
MappingData((f"C15_0x4000D", 1, "20.inverter_kw", CT.real_logs))
MappingData((f"C15_0x4000B", 1, "20.inverter_outv", CT.real_logs))
MappingData((f"C15_0x40009", 1, "20.inverter_outa", CT.real_logs))
MappingData((f"C15_0x40005", 1, "20.inverter_outhz", CT.real_logs))

MappingData((f"C16_0x4000A", 1, "21.inverter_hz", CT.real_logs))
MappingData((f"C16_0x4000D", 1, "21.inverter_kw", CT.real_logs))
MappingData((f"C16_0x4000B", 1, "21.inverter_outv", CT.real_logs))
MappingData((f"C16_0x40009", 1, "21.inverter_outa", CT.real_logs))
MappingData((f"C16_0x40005", 1, "21.inverter_outhz", CT.real_logs))