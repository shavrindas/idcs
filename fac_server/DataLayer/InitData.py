import Data_Layer.DataList as DL
import Mapping_Layer.Mapping as MP

room_id = 1

def Adr_add(adr: str, label: str, degree: int = 0):
    DL.add_LS_addr(adr)
    MP.Mapping(adr, f"{room_id}.{label}", degree)

#주소 및 매핑 레이블
def init():
    Adr_add("01%PX21", "comp", -1)
    Adr_add("01%PX2D", "def", -1)
    Adr_add("01%PX2F", "emg", -1)
    Adr_add("01%DW420", "temppv", -1)
    Adr_add("01%DW421", "tempsv", -1)
    Adr_add("01%DW2421", "temphey", -1)
    Adr_add("01%DW2420", "tempzero", -1)
    Adr_add("01%CW0001", "runtime")
    Adr_add("01%CW0004", "cruntime")
    Adr_add("01%DW0001", "rundel", -1)
    Adr_add("01%DW0003", "compdel", -1)
    Adr_add("01%DW0035", "cooldel", -1)
    Adr_add("01%DW0036", "defdel", -1)
    Adr_add("01%DW59", "DFC")
    Adr_add("01%DW57", "DFT")
    Adr_add("01%CW11", "SYSH")
    Adr_add("01%CW10", "SYSM")
    
    Adr_add("01%DW0400", "comp1temp", -1)
    Adr_add("01%DW0300", "comp1press1", -1)
    Adr_add("01%DW0310", "comp1press2", -1)
    Adr_add("01%DW0405", "comp2temp", -1)
    Adr_add("01%DW0315", "comp2press1", -1)
    Adr_add("01%DW0326", "comp2press2", -1)
    Adr_add("01%DW0415", "transtemp", -1)
    
    Adr_add("01%MX0000", "runsw")
    Adr_add("01%PX20", "expan")
    Adr_add("01%PX22", "expan2")
    Adr_add("01%PX29", "expan3")

    Adr_add("01%MX0120", "emg_cinteocr")
    Adr_add("01%MX0125", "emg_high")
    Adr_add("01%MX012C", "emg_fan")
    Adr_add("01%MX0121", "emg_lock")
    Adr_add("01%MX0126", "emg_press")
    Adr_add("01%MX0122", "emp_temp")
    Adr_add("01%MX0127", "emp_hot")
    Adr_add("01%MX030E", "emp_low")
    Adr_add("01%MX0131", "emp_rotation")

    Adr_add("01%MX000E", "rtc")
    Adr_add("01%MX000B", "dth")
    Adr_add("01%MX0006", "lsv")