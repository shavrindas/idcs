# ===============================================================
# 경로 : src/models/Chat.py
# 명세 : 채팅방, 메시지, 즐겨찾기, 핀 및 해시태그 모델 정의
# ===============================================================
import enum
from sqlalchemy import Column, Integer, String, Text, Enum, DateTime, ForeignKey, UniqueConstraint, func
from sqlalchemy.orm import relationship
from config.db import Base


class ChatRoomType(str, enum.Enum):
    DIRECT = "DIRECT"
    GROUP = "GROUP"
    FACILITY = "FACILITY"


class MessageType(str, enum.Enum):
    TEXT = "TEXT"
    IMAGE = "IMAGE"
    FILE = "FILE"


class ChatRoom(Base):
    __tablename__ = "chatrooms"

    room_id = Column(Integer, primary_key=True, autoincrement=True)
    facility_id = Column(Integer, ForeignKey("facilities_table.id", ondelete="CASCADE"), nullable=True) 
    room_name = Column(String(150), nullable=False)
    type = Column(Enum(ChatRoomType, name="chatroom_type"), nullable=False, default=ChatRoomType.GROUP)
    created_at = Column(DateTime(timezone=True), server_default=func.now())

    # 관계 정의
    facility = relationship("Facility")
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
    parent = relationship("Message", remote_side=[message_id], back_populates="replies")
    replies = relationship("Message", back_populates="parent", cascade="all, delete-orphan")

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
    user_id = Column(Integer, ForeignKey("user_table.id", ondelete="CASCADE"), nullable=False) # 👈 유저 식별자 추가
    created_at = Column(DateTime(timezone=True), server_default=func.now())

    # 관계 정의
    room = relationship("ChatRoom")
    user = relationship("User")

    __table_args__ = (
        UniqueConstraint("room_id", "user_id", name="uq_user_room_fav"),
    )


class MessagePin(Base):
    __tablename__ = "messages_pin"

    pin_id = Column(Integer, primary_key=True, autoincrement=True)
    room_id = Column(Integer, ForeignKey("chatrooms.room_id", ondelete="CASCADE"), nullable=False) # 👈 빠른 조회용 room_id 역정규화 추가
    message_id = Column(Integer, ForeignKey("messages.message_id", ondelete="CASCADE"), nullable=False)
    user_id = Column(Integer, ForeignKey("user_table.id", ondelete="CASCADE"), nullable=False) # 👈 고정한 주체(관리자) 식별자 추가
    created_at = Column(DateTime(timezone=True), server_default=func.now())

    # 관계 정의
    room = relationship("ChatRoom")
    message = relationship("Message")
    user = relationship("User")


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


class PostHiddenChartGroup(Base):
    __tablename__ = "post_hidden_chart_groups"

    post_id = Column(Integer, ForeignKey("posts.post_id", ondelete="CASCADE"), primary_key=True)
    group_id = Column(Integer, ForeignKey("chart_group_table.id", ondelete="CASCADE"), primary_key=True)
    created_at = Column(DateTime(timezone=True), server_default=func.now())

    # 관계 설정 (필요시)
    post = relationship("Post")
    group = relationship("ChartGroup")