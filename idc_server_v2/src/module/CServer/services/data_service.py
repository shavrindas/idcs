import json
import datetime
import src.module.CServer.services.alarm_service as alarm_services
from src.module.Core.models.Monitoring import BoolLog, TemperatureNumericalLog, EquipmentStaticLog, PointRole, RemoteControlLog
import re
from src.config.database import get_db
from sqlalchemy.future import select
from typing import Dict
from datetime import datetime, timezone

'''일정 인터벌 데이터 기록'''
async def facility_log_check(data_dict: dict, facility_id: int):
    if isinstance(data_dict, str):
        try:
            data_dict = json.loads(data_dict)
        except json.JSONDecodeError:
            print("❌ facility_log_check: JSON 파싱 실패")
            return
    
    if "time" in data_dict:
        bool_logs = []
        real_logs = []
        static_logs = []
        roles = await alarm_services.scan_roles_asc_name(facility_id)
        #print(roles)
        #print(f"현재시간: {datetime.strptime(data_dict["time"], "%Y-%m-%d %H:%M:%S")}")

        dt_object = datetime.strptime(data_dict["time"], "%Y-%m-%d %H:%M:%S")

        for datakey, labled_dict in data_dict.items():
            try:
                json_dict = json.loads(labled_dict) if isinstance(labled_dict, str) else labled_dict
            except json.JSONDecodeError:
                continue

            for label, values in json_dict.items():
                if label in roles:
                    role_obj = roles[label]

                    #print(f"✅ 매칭 성공! 라벨: {label} | 롤 정보: {values}")

                    if datakey == "bool":
                        bool_logs.append(BoolLog(
                            role_id=role_obj.id,
                            timestamp=dt_object,
                            status_value=values.get("last_value")
                        ))
                    elif datakey == "real":
                        real_logs.append(TemperatureNumericalLog(
                            role_id = role_obj.id,
                            timestamp = dt_object,
                            temp_min = values.get("val_min"),
                            temp_max = values.get("val_max"),
                            temp_mean = values.get("val_mean"),
                            temp_stdev = values.get("val_std"),
                            sample_count = values.get("count")
                        ))
                    elif datakey == "real_static":
                        static_logs.append(EquipmentStaticLog(
                            role_id=role_obj.id,
                            timestamp=dt_object,
                            setnum=values.get("last_value")
                        ))
                else:
                    pass
        
        async for db in get_db():
            iscommit = False
            if bool_logs:
                db.add_all(bool_logs)
                iscommit = True
            if real_logs:
                db.add_all(real_logs)
                iscommit = True
            if static_logs:
                db.add_all(static_logs)
                iscommit = True
            if iscommit:
                await db.commit()
            
            break

'''알람 체크'''
async def facility_alarm_check(data_dict : dict, facility_id: int):
    if isinstance(data_dict, str):
        try:
            data_dict = json.loads(data_dict)
        except json.JSONDecodeError:
            print("❌ facility_log_check: JSON 파싱 실패")
            return
    
    if "datas" in data_dict:
        # 역할 스캔 및 알람 확인
        roles = await alarm_services.scan_roles(facility_id)
        await alarm_services.check_roles(facility_id, data_dict["datas"], roles)

'''원격조작 기록'''
async def facility_remote_record(data_dict : dict):
    if isinstance(data_dict, str):
        try:
            data_dict = json.loads(data_dict)
        except json.JSONDecodeError:
            print("❌ facility_log_check: JSON 파싱 실패")
            return
    
    if "SUCCESS" in data_dict["status"]:
        datas = re.split(r"[.]", data_dict["request_id"])
        print(datas)

        async for db in get_db():
            stmt = select(PointRole.id).where(PointRole.role_name == datas[1]).where(PointRole.room_id == int(datas[0]))

            result = await db.execute(stmt)

            role_id = result.scalars().first()

            if not role_id:
                print(f"⚠️ [로그 저장 실패] 매칭되는 PointRole을 찾을 수 없습니다. (room_id: {datas[0]}, role_name: {datas[1]})")
                # 필요하다면 여기서 에러 응답을 리턴하거나 로직을 중단합니다.
                break

            now_time = datetime.now(timezone.utc)

            new_log = RemoteControlLog(
                role_id = role_id,
                control_value=data_dict["request_val"],
                timestamp=now_time
            )

            db.add(new_log)
            await db.commit()

            break