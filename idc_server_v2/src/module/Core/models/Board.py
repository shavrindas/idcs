# ===============================================================
# 경로 : src/module/Core/models/Board.py
# 명세 : 게시판, 게시글, 댓글 및 이미지 첨부파일 모델 정의
# ===============================================================
from sqlalchemy import Column, Integer, String, Text, Date, DateTime, Numeric, ForeignKey, func
from sqlalchemy.orm import relationship
from config.db import Base

class Board(Base):
    __tablename__ = "boards"

    board_id = Column(Integer, primary_key=True, autoincrement=True)
    facility_id = Column(Integer, ForeignKey("facilities_table.id", ondelete="CASCADE"), nullable=False)
    facility_name = Column(String(255), nullable=True)
    created_at = Column(DateTime(timezone=True), server_default=func.now())

    # 관계 정의
    facility = relationship("Facility")
    posts = relationship("Post", back_populates="board", cascade="all, delete-orphan")


class Post(Base):
    __tablename__ = "posts"

    post_id = Column(Integer, primary_key=True, autoincrement=True)
    board_id = Column(Integer, ForeignKey("boards.board_id", ondelete="CASCADE"), nullable=False)
    creator_id = Column(Integer, ForeignKey("user_table.id"), nullable=False)
    updater_id = Column(Integer, ForeignKey("user_table.id"), nullable=False)
    title = Column(String(255), nullable=False)
    content = Column(Text, nullable=False)
    start_date = Column(Date, nullable=True)
    end_date = Column(Date, nullable=True)
    created_at = Column(DateTime(timezone=True), server_default=func.now())
    updated_at = Column(DateTime(timezone=True), server_default=func.now(), onupdate=func.now())

    # 관계 정의
    board = relationship("Board", back_populates="posts")
    creator = relationship("User", foreign_keys=[creator_id])
    updater = relationship("User", foreign_keys=[updater_id])
    
    images = relationship("PostImage", back_populates="post", cascade="all, delete-orphan")
    comments = relationship("Comment", back_populates="post", cascade="all, delete-orphan")


class PostImage(Base):
    __tablename__ = "post_images"

    image_id = Column(Integer, primary_key=True, autoincrement=True)
    post_id = Column(Integer, ForeignKey("posts.post_id", ondelete="CASCADE"), nullable=True) # 임시 저장 허용을 위해 nullable=True
    image_url = Column(String(512), nullable=False)
    original_name = Column(String(255), nullable=False)
    file_size = Column(Integer, nullable=False)
    width = Column(Integer, nullable=False)
    height = Column(Integer, nullable=False)
    aspect_ratio = Column(Numeric(4, 2), nullable=False)
    created_at = Column(DateTime(timezone=True), server_default=func.now())

    # 관계 정의
    post = relationship("Post", back_populates="images")


class Comment(Base):
    __tablename__ = "comments"

    comment_id = Column(Integer, primary_key=True, autoincrement=True)
    post_id = Column(Integer, ForeignKey("posts.post_id", ondelete="CASCADE"), nullable=False)
    creator_id = Column(Integer, ForeignKey("user_table.id"), nullable=False)
    content = Column(Text, nullable=False)
    created_at = Column(DateTime(timezone=True), server_default=func.now())
    updated_at = Column(DateTime(timezone=True), server_default=func.now(), onupdate=func.now())

    # 관계 정의
    post = relationship("Post", back_populates="comments")
    creator = relationship("User")