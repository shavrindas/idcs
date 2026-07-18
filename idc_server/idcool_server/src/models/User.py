# ===============================================================
# 경로 : src/models/User.py
# 명세 : User 계정 및 권한(Role) 관련 데이터 모델 정의
# ===============================================================
import enum
from sqlalchemy import Column, Integer, String, Enum, DateTime, func, ForeignKey
from sqlalchemy.orm import relationship
from idcool_server.config.db import Base
# ===============================================================

class UserRole(str, enum.Enum):
    USER = "USER"
    ADMIN = "ADMIN"
    DEVELOPER = "DEVELOPER"


class User(Base):
    __tablename__ = "user_table"

    id = Column(Integer, primary_key=True, autoincrement=True)
    email = Column(String(255), unique=True, nullable=False, index=True)
    password = Column(String(255), nullable=True)
    name = Column(String(100), nullable=False)
    role = Column(Enum(UserRole, name="user_role"), nullable=False, default=UserRole.USER)
    phone_number = Column(String(20), nullable=True)
    
    # 타임존을 포함하는 생성일, 수정일 (자동 갱신)
    created_at = Column(DateTime(timezone=True), server_default=func.now())
    updated_at = Column(DateTime(timezone=True), server_default=func.now(), onupdate=func.now())

    external_providers = relationship("ExternalProvider", back_populates="user", cascade="all, delete-orphan")


    # 역참조 맵핑 
    facilities = relationship(
        "Facility",
        secondary="facility_users",
        primaryjoin="User.id == facility_users.c.user_id",
        secondaryjoin="Facility.id == facility_users.c.facility_id",
        viewonly=True # 다대다 조회 목적
    )


class ExternalProvider(Base):
    __tablename__ = "external_providers"

    external_provider_id = Column(Integer, primary_key=True, autoincrement=True)
    account_id = Column(Integer, ForeignKey("user_table.id", ondelete="CASCADE"), nullable=False)
    provider = Column(String(50), nullable=False) # 'google' or 'apple' 제한
    provider_id = Column(String(255), nullable=False)
    created_at = Column(DateTime(timezone=True), server_default=func.now())

    user = relationship("User", back_populates="external_providers")


