# ===============================================================
# 경로 : src/module/Core/models/Facility.py
# 명세 : Facility 관련 데이터 모델 정의
# ===============================================================
import enum
from sqlalchemy import (
    Column, Integer, String, Boolean, Date, Enum, DateTime, func, ForeignKey, UniqueConstraint
)
from sqlalchemy.orm import relationship
from config.db import Base
# ===============================================================

class RoomStatusType(str, enum.Enum):
    OPERATING = "OPERATING"
    MAINTENANCE = "MAINTENANCE"
    NOT_OPERATING = "NOT_OPERATING"


class NodeStatusType(str, enum.Enum):
    ONLINE = "ONLINE"
    OFFLINE = "OFFLINE"
    ERROR = "ERROR"
    MAINTENANCE = "MAINTENANCE"


class FacilityUser(Base):
    __tablename__ = "facility_users"

    id = Column(Integer, primary_key=True, autoincrement=True)
    facility_id = Column(Integer, ForeignKey("facilities_table.id", ondelete="CASCADE"), nullable=False)
    user_id = Column(Integer, ForeignKey("user_table.id", ondelete="CASCADE"), nullable=False)
    created_at = Column(DateTime(timezone=True), server_default=func.now())

    __table_args__ = (
        UniqueConstraint("facility_id", "user_id", name="uq_facility_user"),
    )


class Facility(Base):
    __tablename__ = "facilities_table"

    id = Column(Integer, primary_key=True, autoincrement=True)
    name = Column(String(255), nullable=False)
    access_code = Column(String(50), unique=True, nullable=False, index=True)
    is_active = Column(Boolean, nullable=False, default=True)
    start_date = Column(Date, nullable=True)
    end_date = Column(Date, nullable=True)
    created_at = Column(DateTime(timezone=True), server_default=func.now())
    updated_at = Column(DateTime(timezone=True), server_default=func.now(), onupdate=func.now())

    rooms = relationship("FacilityRoom", back_populates="facility", cascade="all, delete-orphan")


class FacilityRoom(Base):
    __tablename__ = "facilities_room_table"

    id = Column(Integer, primary_key=True, autoincrement=True)
    facility_id = Column(Integer, ForeignKey("facilities_table.id", ondelete="CASCADE"), nullable=False)
    name = Column(String(100), nullable=False)
    status = Column(Enum(RoomStatusType, name="room_status_type"), nullable=False, default=RoomStatusType.OPERATING)
    operation_start_date = Column(Date, nullable=True)
    operation_end_date = Column(Date, nullable=True)
    created_at = Column(DateTime(timezone=True), server_default=func.now())
    updated_at = Column(DateTime(timezone=True), server_default=func.now(), onupdate=func.now())

    facility = relationship("Facility", back_populates="rooms")

#26.7.23 추가  
#26.8.02 제거 (중복 제거)  Monitoring.py 에서 참조
#
# class PointRole(Base):
#     __tablename__ = "point_role_table"
#     id = Column(Integer, primary_key=True, autoincrement=True)
#     facility_id = Column(Integer, ForeignKey("facilities_table.id", ondelete="CASCADE"), nullable=False)
#     room_id = Column(Integer, ForeignKey("facilities_room_table.id", ondelete="CASCADE"), nullable=False)
#     role_name = Column(String(150), nullable=False)
#     target_value = Column(String(255), nullable=True)
#     target_low_limit = Column(String(255), nullable=True)
#     target_high_limit = Column(String(255), nullable=True)
#     valid_from = Column(Date, nullable=False)
#     valid_to = Column(Date, nullable=True)
#     is_current = Column(Boolean, nullable=False, default=True)


class FacilityNode(Base):
    __tablename__ = "facility_nodes"

    id = Column(Integer, primary_key=True, autoincrement=True)
    facility_id = Column(Integer, ForeignKey("facilities_table.id", ondelete="CASCADE"), nullable=False, index=True)
    node_code = Column(String(100), unique=True, nullable=False)
    node_name = Column(String(150), nullable=False)
    api_key_hash = Column(String(255), nullable=False)
    allowed_ip_cidr = Column(String(50), nullable=True)
    status = Column(Enum(NodeStatusType, name="node_status_type"), nullable=False, default=NodeStatusType.OFFLINE, index=True)
    firmware_version = Column(String(50), nullable=True)
    last_heartbeat_at = Column(DateTime(timezone=True), nullable=True)
    is_active = Column(Boolean, nullable=False, default=True)
    created_at = Column(DateTime(timezone=True), server_default=func.now())
    updated_at = Column(DateTime(timezone=True), server_default=func.now(), onupdate=func.now())

    facility = relationship("Facility", back_populates="nodes")