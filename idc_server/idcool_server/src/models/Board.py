# ===============================================================
# 경로 : src/models/Board.py
# 명세 : 게시판(Board) 및 게시글(Post) 데이터 모델 정의
# ===============================================================
from sqlalchemy import Column, Integer, String, Text, ForeignKey, DateTime, Numeric, func
from idcool_server.config.db import Base
# ===============================================================

class Board(Base):
    __tablename__ = "boards"

    board_id = Column(Integer, primary_key=True, autoincrement=True)
    facility_id = Column(Integer, nullable=False)
    facility_name = Column(String(255))
    created_at = Column(DateTime(timezone=True), server_default=func.now())

class Post(Base):
    __tablename__ = "posts"

    post_id = Column(Integer, primary_key=True, autoincrement=True)
    board_id = Column(Integer, ForeignKey("boards.board_id", ondelete="CASCADE"), nullable=False)
    creator_id = Column(Integer, nullable=False)  
    updater_id = Column(Integer, nullable=False)
    title = Column(String(255), nullable=False)
    content = Column(Text, nullable=False)
    
    # [변경] images 배열 삭제
    # images = Column(ARRAY(Text), default=[]) 
    
    created_at = Column(DateTime(timezone=True), server_default=func.now())
    updated_at = Column(DateTime(timezone=True), server_default=func.now(), onupdate=func.now())

class PostImage(Base):
    __tablename__ = "post_images"
    
    image_id = Column(Integer, primary_key=True, autoincrement=True)
    # 글 작성 중 선업로드 된 상태를 위해 nullable=True 설정
    post_id = Column(Integer, ForeignKey("posts.post_id", ondelete="CASCADE"), nullable=True)
    image_url = Column(String(512), nullable=False)
    original_name = Column(String(255), nullable=False)
    file_size = Column(Integer, nullable=False)
    width = Column(Integer, nullable=False)
    height = Column(Integer, nullable=False)
    aspect_ratio = Column(Numeric(4, 2), nullable=False)
    
    created_at = Column(DateTime(timezone=True), server_default=func.now())