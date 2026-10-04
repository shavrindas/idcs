# ===============================================================
# 경로 : src/module/Core/models/Monitoring.py
# 명세 : 포인트 역할, 각종 계측 로그 및 알람 관련 데이터 모델 정의
# ===============================================================
from sqlalchemy import (
    Column, Integer, String, Boolean, DateTime, REAL, Interval, 
    ForeignKey, UniqueConstraint, Index, CHAR, func
)

from sqlalchemy.orm import relationship
from src.config.database import Base
class PointRole(Base):
    __tablename__ = "point_role_table"

    id = Column(Integer, primary_key=True, autoincrement=True)
    facility_id = Column(Integer, ForeignKey("facilities_table.id", ondelete="CASCADE"), nullable=False)
    room_id = Column(Integer, ForeignKey("facilities_room_table.id", ondelete="CASCADE"), nullable=False)
    role_name = Column(String(150), nullable=False)
    target_value = Column(String(255), nullable=True)
    target_low_limit = Column(String(255), nullable=True)
    target_high_limit = Column(String(255), nullable=True)
    valid_from = Column(DateTime(timezone=True), nullable=False)
    valid_to = Column(DateTime(timezone=True), nullable=True)
    is_current = Column(Boolean, nullable=False, default=True)

    # Relationship
    facility = relationship("Facility")
    room = relationship("FacilityRoom")

    # is_current가 True인 대상에 대해서만 유일성을 보장하는 부분 인덱스(Partial Index) 모사
    # (SQLAlchemy 내에서 PostgreSQL partial index 선언)
    __table_args__ = (
        Index(
            "uq_point_role_current", 
            "facility_id", "room_id", "role_name", 
            unique=True, 
            postgresql_where=(is_current == True)
        ),
    )


# ---------------------------------------------------------------
# TimescaleDB 하이퍼테이블 로그 영역 (기본 복합키나 단방향 관계 매핑 지원)
# ---------------------------------------------------------------

class TemperatureNumericalLog(Base):
    __tablename__ = "temperature_numerical_logs"

    role_id = Column(Integer, ForeignKey("point_role_table.id"), primary_key=True, nullable=False)
    timestamp = Column(DateTime(timezone=True), primary_key=True, nullable=False)
    temp_min = Column(REAL, nullable=False)
    temp_max = Column(REAL, nullable=False)
    temp_mean = Column(REAL, nullable=False)
    temp_stdev = Column(REAL, nullable=True)
    sample_count = Column(Integer, nullable=False)

    role = relationship("PointRole")


class GearNumericalLog(Base):
    __tablename__ = "gear_numerical_logs"

    role_id = Column(Integer, ForeignKey("point_role_table.id"), primary_key=True, nullable=False)
    timestamp = Column(DateTime(timezone=True), primary_key=True, nullable=False)
    gear_min = Column(REAL, nullable=False)
    gear_max = Column(REAL, nullable=False)
    gear_mean = Column(REAL, nullable=False)
    gear_stdev = Column(REAL, nullable=True)
    sample_count = Column(Integer, nullable=False)

    role = relationship("PointRole")


class BoolLog(Base):
    __tablename__ = "bool_logs"

    role_id = Column(Integer, ForeignKey("point_role_table.id"), primary_key=True, nullable=False)
    timestamp = Column(DateTime(timezone=True), primary_key=True, nullable=False)
    status_value = Column(Boolean, nullable=False)

    role = relationship("PointRole")


class EquipmentStaticLog(Base):
    __tablename__ = "equipment_static_logs"

    role_id = Column(Integer, ForeignKey("point_role_table.id"), primary_key=True, nullable=False)
    timestamp = Column(DateTime(timezone=True), primary_key=True, nullable=False)
    setnum = Column(Integer, nullable=False)

    role = relationship("PointRole")


# ---------------------------------------------------------------
# 제어 및 알림 영역
# ---------------------------------------------------------------

# 향후 수정 예정
class RemoteControlLog(Base):
    __tablename__ = "remote_control_logs"

    id = Column(Integer, primary_key=True, autoincrement=True)
    role_id = Column(Integer, ForeignKey("point_role_table.id"), nullable=False)
    timestamp = Column(DateTime(timezone=True), primary_key=True, nullable=False)
    control_value = Column(String(255), nullable=False)

    role = relationship("PointRole")

# 향후 적용 예정 
# class RemoteControlLog(Base):
#     __tablename__ = "remote_control_logs"
#     id = Column(Integer, primary_key=True, autoincrement=True)  # 단일 PK로 변경
#     role_id = Column(Integer, ForeignKey("point_role_table.id"), nullable=False)
#     timestamp = Column(DateTime(timezone=True), nullable=False)
#     control_value = Column(String(255), nullable=False)
#     # [추가된 필드]
#     user_id = Column(Integer, ForeignKey("user_table.id", ondelete="SET NULL"), nullable=True)
#     node_id = Column(Integer, ForeignKey("facility_nodes.id", ondelete="SET NULL"), nullable=True)
#     previous_value = Column(String(255), nullable=True)
#     is_authorized = Column(Boolean, nullable=False, default=True)
#     role = relationship("PointRole")
#     user = relationship("User")
#     node = relationship("FacilityNode")


class Alarm(Base):
    __tablename__ = "alarms"

    alarm_id = Column(Integer, primary_key=True, autoincrement=True)
    role_id = Column(Integer, ForeignKey("point_role_table.id"), nullable=False)
    alarm_name = Column(String(150), nullable=False)
    severity = Column(CHAR(1), nullable=False) # CHECK(severity IN ('a', 'b', 'c', 'd', 'e', 'f'))
    timestamp = Column(DateTime(timezone=True), primary_key=True, nullable=False)
    is_triggered = Column(Boolean, nullable=False, default=False)
    
    reset_timeout_interval = Column(Interval, server_default="48 hours")
    end_time = Column(DateTime(timezone=True), nullable=True)
    is_admin_reset = Column(Boolean, nullable=False, default=False)
    admin_reset_remaining_time = Column(Interval, nullable=True)

    role = relationship("PointRole")



# ---------------------------------------------------------------
# 차트 그룹 및 매핑 영역
# ---------------------------------------------------------------

class ChartGroup(Base):
    __tablename__ = "chart_group_table"

    id = Column(Integer, primary_key=True, autoincrement=True)
    facility_id = Column(Integer, ForeignKey("facilities_table.id", ondelete="CASCADE"), nullable=False)
    room_id = Column(Integer, ForeignKey("facilities_room_table.id", ondelete="CASCADE"), nullable=False)
    group_name = Column(String(150), nullable=False)
    # data_type = Column(String(50), nullable=False)  # 삭제됨 
    created_at = Column(DateTime(timezone=True), server_default=func.now())
    updated_at = Column(DateTime(timezone=True), server_default=func.now(), onupdate=func.now())

    # 다대다(N:M) 관계 설정 (PointRole 모델과 양방향 참조)
    roles = relationship(
        "PointRole",
        secondary="chart_group_mapping",
        backref="chart_groups",
        lazy="selectin"
    )

class ChartGroupMapping(Base):
    __tablename__ = "chart_group_mapping"

    group_id = Column(Integer, ForeignKey("chart_group_table.id", ondelete="CASCADE"), primary_key=True)
    role_id = Column(Integer, ForeignKey("point_role_table.id", ondelete="CASCADE"), primary_key=True)

