# ===============================================================
# 경로 : src/models/Chat.py
# 명세 : 채팅방, 메시지, 즐겨찾기, 핀 및 해시태그 모델 정의
# ===============================================================
import enum
from sqlalchemy import Column, Integer, String, Text, Enum, DateTime, ForeignKey, UniqueConstraint, func
from sqlalchemy.orm import relationship
from idcool_server.config.db import Base

class ChatRoomType(str, enum.Enum):
    DIRECT = "DIRECT"
    GROUP = "GROUP"
    FACILITY = "FACILITY"


class MessageType(str, enum.Enum):
    TEXT = "TEXT"
    IMAGE = "IMAGE"
    FILE = "FILE"


class ChatRoom(Base):
    __tablename__ = "chatrooms" # DB 스크립트 대소문자 매칭(chatRooms) 확인 필요하나 일반적으로 소문자 권장, 스크립트 기반 작성

    room_id = Column(Integer, primary_key=True, autoincrement=True)
    room_name = Column(String(150), nullable=False)
    type = Column(Enum(ChatRoomType, name="chatroom_type"), nullable=False, default=ChatRoomType.GROUP)
    created_at = Column(DateTime(timezone=True), server_default=func.now())

    # 관계 정의
    participants = relationship("ChatParticipant", back_populates="room", cascade="all, delete-orphan")
    messages = relationship("Message", back_populates="room", cascade="all, delete-orphan")


class ChatParticipant(Base):
    __tablename__ = "chatparticipants"

    participant_id = Column(Integer, primary_key=True, autoincrement=True)
    room_id = Column(Integer, ForeignKey("chatrooms.room_id", ondelete="CASCADE"), nullable=False)
    user_id = Column(Integer, ForeignKey("user_table.id", ondelete="CASCADE"), nullable=False)
    joined_at = Column(DateTime(timezone=True), server_default=func.now())
    last_read_message_id = Column(Integer, default=0)
    unread_count = Column(Integer, nullable=False, default=0)

    # 관계 정의
    room = relationship("ChatRoom", back_populates="participants")
    user = relationship("User")

    __table_args__ = (
        UniqueConstraint("room_id", "user_id", name="uq_room_user"),
    )


class Message(Base):
    __tablename__ = "messages"

    message_id = Column(Integer, primary_key=True, autoincrement=True)
    room_id = Column(Integer, ForeignKey("chatrooms.room_id", ondelete="CASCADE"), nullable=False)
    user_id = Column(Integer, ForeignKey("user_table.id", ondelete="CASCADE"), nullable=False)
    message_type = Column(Enum(MessageType, name="message_type"), nullable=False, default=MessageType.TEXT)
    content = Column(Text, nullable=False)
    created_at = Column(DateTime(timezone=True), server_default=func.now())
    parent_message_id = Column(Integer, ForeignKey("messages.message_id", ondelete="SET NULL"), nullable=True)

    # 관계 정의
    room = relationship("ChatRoom", back_populates="messages")
    user = relationship("User")
    
    # 자가 참조 (Self-referential) 관계 구성 (답글 기능)
    replies = relationship("Message", backref=relationship("Message", remote_side=[message_id]))

    # 다대다 해시태그 매핑
    hashtags = relationship(
        "Hashtag",
        secondary="message_hashtags",
        back_populates="messages"
    )


class MessageFav(Base):
    __tablename__ = "messages_fav"

    fav_id = Column(Integer, primary_key=True, autoincrement=True)
    room_id = Column(Integer, ForeignKey("chatrooms.room_id", ondelete="CASCADE"), nullable=False)
    created_at = Column(DateTime(timezone=True), server_default=func.now())

    room = relationship("ChatRoom")


class MessagePin(Base):
    __tablename__ = "messages_pin"

    pin_id = Column(Integer, primary_key=True, autoincrement=True)
    message_id = Column(Integer, ForeignKey("messages.message_id", ondelete="CASCADE"), nullable=False)
    created_at = Column(DateTime(timezone=True), server_default=func.now())

    message = relationship("Message")


class Hashtag(Base):
    __tablename__ = "hashtags"

    hashtag_id = Column(Integer, primary_key=True, autoincrement=True)
    tag_name = Column(String(100), nullable=False, unique=True)

    messages = relationship(
        "Message",
        secondary="message_hashtags",
        back_populates="hashtags"
    )


class MessageHashtag(Base):
    __tablename__ = "message_hashtags"

    message_id = Column(Integer, ForeignKey("messages.message_id", ondelete="CASCADE"), primary_key=True)
    hashtag_id = Column(Integer, ForeignKey("hashtags.hashtag_id", ondelete="CASCADE"), primary_key=True)