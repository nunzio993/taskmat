from sqlalchemy import Column, Integer, String, Boolean, Float, ForeignKey, DateTime, Enum, JSON, Text, UniqueConstraint
from sqlalchemy.orm import relationship
from sqlalchemy.sql import func
from geoalchemy2 import Geometry
import enum
from app.core.database import Base

class UserRole(str, enum.Enum):
    CLIENT = "client"
    HELPER = "helper"
    ADMIN = "admin"

class TaskStatus(str, enum.Enum):
    POSTED = "posted"
    ASSIGNING = "assigning" # Selection/Pre-auth in progress
    ASSIGNED = "assigned" # Pre-auth success, helper assigned
    IN_PROGRESS = "in_progress" # Helper started work
    IN_CONFIRMATION = "in_confirmation" # Completion requested, waiting for client
    COMPLETED = "completed" # Client confirmed, payment captured
    CANCELLED_BY_CLIENT = "cancelled_by_client"
    CANCELLED_BY_HELPER = "cancelled_by_helper"
    PAYMENT_FAILED = "payment_failed" # Pre-auth failed
    EXPIRED = "expired"
    REFUNDED = "refunded"

class OfferStatus(str, enum.Enum):
    SUBMITTED = "submitted"
    WITHDRAWN = "withdrawn"
    ACCEPTED = "accepted"
    DECLINED = "declined"

class MessageType(str, enum.Enum):
    TEXT = "text"
    OFFER_UPDATE = "offer_update"
    SYSTEM = "system"

class Task(Base):
    __tablename__ = "tasks"

    id = Column(Integer, primary_key=True, index=True)
    client_id = Column(Integer, ForeignKey("users.id"))
    title = Column(String, nullable=False)
    description = Column(Text)
    category = Column(String, index=True)
    
    # Financials
    price_cents = Column(Integer, nullable=False) # Current active price (offered or agreed)
    
    # Status & Life Cycle
    status = Column(String, default=TaskStatus.POSTED, index=True)
    selected_offer_id = Column(Integer, ForeignKey("task_offers.id"), nullable=True)
    version = Column(Integer, default=1, nullable=False) # Optimistic Locking
    
    # Location - Exact (private, shown only to assigned helper)
    location = Column(Geometry("POINT", srid=4326), nullable=False)
    # Location - Blurred for public (calculated via PostGIS grid snap)
    public_location = Column(Geometry("POINT", srid=4326), nullable=True)
    
    # Address Fields (precise, shown to assigned helper only)
    street = Column(String, nullable=True)
    street_number = Column(String, nullable=True)
    city = Column(String, nullable=True)
    postal_code = Column(String, nullable=True)
    province = Column(String, nullable=True)
    address_extra = Column(String, nullable=True)  # Scala/Piano/Interno
    place_id = Column(String, nullable=True)  # Google Places ID
    formatted_address = Column(String, nullable=True)
    address_line = Column(String, nullable=True)  # Legacy field
    
    # Access Notes (helper-only after assignment)
    access_notes = Column(Text, nullable=True)
    
    # Scheduling - Urgency is now derived or simplified
    urgency = Column(String, nullable=True) # "asap", "scheduled"
    scheduled_at = Column(DateTime(timezone=True), nullable=True)
    
    # Timestamps
    created_at = Column(DateTime(timezone=True), server_default=func.now())
    expires_at = Column(DateTime(timezone=True), nullable=True)
    assigned_at = Column(DateTime(timezone=True), nullable=True)
    started_at = Column(DateTime(timezone=True), nullable=True)
    completion_requested_at = Column(DateTime(timezone=True), nullable=True)
    completed_at = Column(DateTime(timezone=True), nullable=True)
    
    # Dispute Window
    dispute_open_until = Column(DateTime(timezone=True), nullable=True)

    client = relationship("User", back_populates="tasks_created")
    selected_offer = relationship("TaskOffer", foreign_keys=[selected_offer_id])
    
    offers = relationship("TaskOffer", back_populates="task", foreign_keys="[TaskOffer.task_id]")
    threads = relationship("TaskThread", back_populates="task")
    proofs = relationship("TaskProof", back_populates="task")
    
    assignment = relationship("TaskAssignment", back_populates="task", uselist=False)
    payment = relationship("Payment", back_populates="task", uselist=False)
    messages = relationship("Message", back_populates="task") # Legacy, deprecated by TaskThread
    reviews = relationship("Review", back_populates="task")

class TaskOffer(Base):
    __tablename__ = "task_offers"
    
    id = Column(Integer, primary_key=True, index=True)
    task_id = Column(Integer, ForeignKey("tasks.id"), nullable=False)
    helper_id = Column(Integer, ForeignKey("users.id"), nullable=False)
    
    status = Column(String, default=OfferStatus.SUBMITTED)
    price_cents = Column(Integer, nullable=False)
    message = Column(Text, nullable=True)
    
    created_at = Column(DateTime(timezone=True), server_default=func.now())
    updated_at = Column(DateTime(timezone=True), onupdate=func.now())
    
    task = relationship("Task", foreign_keys=[task_id], back_populates="offers")
    helper = relationship("User", foreign_keys=[helper_id])
    
    __table_args__ = (UniqueConstraint('task_id', 'helper_id', name='unique_offer_per_helper'),)

class TaskThread(Base):
    __tablename__ = "task_threads"
    
    id = Column(Integer, primary_key=True, index=True)
    task_id = Column(Integer, ForeignKey("tasks.id"), nullable=False)
    client_id = Column(Integer, ForeignKey("users.id"), nullable=False)
    helper_id = Column(Integer, ForeignKey("users.id"), nullable=False)
    created_at = Column(DateTime(timezone=True), server_default=func.now())
    
    task = relationship("Task", back_populates="threads")
    messages = relationship("TaskMessage", back_populates="thread")
    
    __table_args__ = (UniqueConstraint('task_id', 'helper_id', name='unique_thread_per_helper'),)

class TaskMessage(Base):
    __tablename__ = "task_messages"
    
    id = Column(Integer, primary_key=True, index=True)
    thread_id = Column(Integer, ForeignKey("task_threads.id"), nullable=False)
    sender_id = Column(Integer, ForeignKey("users.id"), nullable=False)
    
    type = Column(String, default=MessageType.TEXT) # TEXT, OFFER_UPDATE, SYSTEM
    body = Column(Text, nullable=True)
    payload = Column(JSON, nullable=True) # For offer details
    
    created_at = Column(DateTime(timezone=True), server_default=func.now())
    read_at = Column(DateTime(timezone=True), nullable=True)
    
    thread = relationship("TaskThread", back_populates="messages")

class TaskProof(Base):
    __tablename__ = "task_proofs"
    
    id = Column(Integer, primary_key=True, index=True)
    task_id = Column(Integer, ForeignKey("tasks.id"), nullable=False, index=True)
    uploader_id = Column(Integer, ForeignKey("users.id"), nullable=False)
    
    kind = Column(String, default="photo") # photo, document
    storage_key = Column(String, nullable=False) # S3/Minio key or URL
    
    created_at = Column(DateTime(timezone=True), server_default=func.now())
    
    task = relationship("Task", back_populates="proofs")

class TaskAssignment(Base):
    __tablename__ = "task_assignments"

    id = Column(Integer, primary_key=True, index=True)
    task_id = Column(Integer, ForeignKey("tasks.id"), unique=True)
    helper_id = Column(Integer, ForeignKey("users.id"))
    status = Column(String, default="assigned")
    locked_until = Column(DateTime(timezone=True), nullable=True)
    assigned_at = Column(DateTime(timezone=True), server_default=func.now())
    completed_at = Column(DateTime(timezone=True), nullable=True)

    task = relationship("Task", back_populates="assignment")
    helper = relationship("User", foreign_keys=[helper_id])

class PaymentStatus(str, enum.Enum):
    PENDING = "pending"
    REQUIRES_CAPTURE = "requires_capture" # Pre-auth done
    CAPTURED = "captured"
    REFUNDED = "refunded"
    FAILED = "failed"
    CANCELLED = "cancelled" # Voided

class Payment(Base):
    __tablename__ = "payments"

    id = Column(Integer, primary_key=True, index=True)
    task_id = Column(Integer, ForeignKey("tasks.id"), unique=True, nullable=False)
    stripe_payment_intent_id = Column(String, unique=True, index=True)
    amount_cents = Column(Integer, nullable=False)
    app_fee_cents = Column(Integer, default=0)
    status = Column(String, default=PaymentStatus.PENDING)
    created_at = Column(DateTime(timezone=True), server_default=func.now())
    captured_at = Column(DateTime(timezone=True), nullable=True)
    refunded_at = Column(DateTime(timezone=True), nullable=True)

    task = relationship("Task", back_populates="payment")

class Message(Base):
    # DEPRECATED: Replaced by TaskThread/TaskMessage
    # TODO: Remove in future migration after verifying no active references
    __tablename__ = "messages"

    id = Column(Integer, primary_key=True, index=True)
    task_id = Column(Integer, ForeignKey("tasks.id"), nullable=False)
    sender_id = Column(Integer, ForeignKey("users.id"), nullable=False)
    body = Column(String, nullable=False)
    created_at = Column(DateTime(timezone=True), server_default=func.now())

    task = relationship("Task", back_populates="messages")
    sender = relationship("User", foreign_keys=[sender_id])

class ReviewStatus(str, enum.Enum):
    PENDING_BLIND = "pending_blind"  # Waiting for other party in blind mode
    VISIBLE = "visible"
    HIDDEN_BY_ADMIN = "hidden_by_admin"

class Review(Base):
    __tablename__ = "reviews"
    __table_args__ = (
        UniqueConstraint('task_id', 'from_user_id', name='uq_review_task_from_user'),
    )

    id = Column(Integer, primary_key=True, index=True)
    task_id = Column(Integer, ForeignKey("tasks.id"), nullable=False, index=True)
    from_user_id = Column(Integer, ForeignKey("users.id"), nullable=False)
    to_user_id = Column(Integer, ForeignKey("users.id"), nullable=False)
    from_role = Column(String, nullable=False)  # 'client' or 'helper'
    stars = Column(Integer, nullable=False)
    comment = Column(String(500), nullable=True)
    tags = Column(JSON, nullable=True, default=list)  # Max 3 tags
    status = Column(String, default=ReviewStatus.PENDING_BLIND.value, nullable=False)
    created_at = Column(DateTime(timezone=True), server_default=func.now())
    updated_at = Column(DateTime(timezone=True), onupdate=func.now())

    task = relationship("Task", back_populates="reviews")
    from_user = relationship("User", foreign_keys=[from_user_id])
    to_user = relationship("User", foreign_keys=[to_user_id], back_populates="reviews_received")

class SystemSetting(Base):
    __tablename__ = "system_settings"

    key = Column(String, primary_key=True, index=True)
    value = Column(JSON, nullable=False)
    description = Column(String, nullable=True)
