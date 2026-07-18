# ===============================================================
# 경로 : src/models/Facility.py
# 명세 : Facility 관련 데이터 모델 정의
# ===============================================================
import enum
from sqlalchemy import (
    Column, Integer, String, Boolean, Date, Enum, DateTime, func, ForeignKey, UniqueConstraint
)
from sqlalchemy.orm import relationship
from idcool_server.config.db import Base
# ===============================================================

class RoomStatusType(str, enum.Enum):
    OPERATING = "OPERATING"
    MAINTENANCE = "MAINTENANCE"
    NOT_OPERATING = "NOT_OPERATING"


class FacilityUser(Base):
    __tablename__ = "facility_users"

    id = Column(Integer, primary_key=True, autoincrement=True)
    facility_id = Column(Integer, ForeignKey("facilities_table.id", ondelete="CASCADE"), nullable=False)
    user_id = Column(Integer, ForeignKey("user_table.id", ondelete="CASCADE"), nullable=False)
    created_at = Column(DateTime(timezone=True), server_default=func.now())

    # 유니크 제약 조건 (동일한 유저가 같은 시설에 중복 등록되는 것 방지)
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

    # 관계 정의 (메모리에 실제 로드되는 FacilityRoom과의 관계만 유지)
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

    # 관계 정의
    facility = relationship("Facility", back_populates="rooms")