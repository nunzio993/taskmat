from fastapi import APIRouter, Depends, HTTPException, File, UploadFile
import shutil
import os
import uuid
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select, func
from sqlalchemy.orm import selectinload
from geoalchemy2.shape import to_shape
from typing import List

from app.api import deps
from app.api import deps
from app.models.models import Task, TaskStatus, TaskOffer, TaskThread, TaskMessage, TaskProof, OfferStatus, Review, ReviewStatus
from app.models.user import User
from app.schemas import tasks as schemas
from app.schemas.task_offers import TaskOfferCreate, TaskOfferResponse
from app.schemas.chat import TaskMessageCreate, TaskMessageResponse, TaskThreadResponse

router = APIRouter()

print(">>> LOADING TASKS.PY - CODE VERSION 2 - MANUAL HYDRATION FIX <<<")

# DIAGNOSTIC ENDPOINT - must be BEFORE /{task_id} route!
@router.get("/diag/offers/{task_id}")
async def diag_offers(task_id: int, db: AsyncSession = Depends(deps.get_db)):
    """Diagnostic endpoint to test offer query directly."""
    from sqlalchemy import text
    
    # Raw SQL
    raw_result = await db.execute(text(f"SELECT id, task_id, helper_id, price_cents FROM task_offers WHERE task_id = {task_id}"))
    raw_offers = raw_result.fetchall()
    
    # ORM Query
    orm_stmt = select(TaskOffer).where(TaskOffer.task_id == task_id)
    orm_result = await db.execute(orm_stmt)
    orm_offers = orm_result.scalars().all()
    
    return {
        "code_version": 2,
        "task_id_requested": task_id,
        "raw_sql_count": len(raw_offers),
        "raw_sql_offers": [{"id": r[0], "task_id": r[1], "helper_id": r[2], "price": r[3]} for r in raw_offers],
        "orm_count": len(orm_offers),
        "orm_offers": [{"id": o.id, "task_id": o.task_id, "helper_id": o.helper_id, "price": o.price_cents} for o in orm_offers]
    }

@router.get("/diag/full_task/{task_id}")
async def diag_full_task(task_id: int, db: AsyncSession = Depends(deps.get_db)):
    """Diagnostic: simulate full get_task logic without auth."""
    from sqlalchemy import text
    
    # 1. Get task
    stmt = select(Task).where(Task.id == task_id).options(selectinload(Task.proofs))
    result = await db.execute(stmt)
    task = result.scalars().first()
    if not task:
        return {"error": "Task not found"}
    
    # 2. Manual hydration
    offer_stmt = select(TaskOffer).where(TaskOffer.task_id == task.id).options(selectinload(TaskOffer.helper).selectinload(User.reviews_received))
    offer_res = await db.execute(offer_stmt)
    offers_list = offer_res.scalars().all()
    
    # 3. Return raw data
    raw_result = {
        "task_id": task.id,
        "task_title": task.title,
        "offers_count_from_hydration": len(offers_list),
        "offers_raw": [{"id": o.id, "task_id": o.task_id, "helper_id": o.helper_id, "price": o.price_cents, "has_helper": o.helper is not None} for o in offers_list],
    }
    
    # 4. Now test _to_task_out
    try:
        task_out = _to_task_out(task, explicit_offers=offers_list)
        raw_result["_to_task_out_offers_count"] = len(task_out.offers)
        raw_result["_to_task_out_first_offer"] = task_out.offers[0].dict() if task_out.offers else None
    except Exception as e:
        raw_result["_to_task_out_error"] = str(e)
    
    return raw_result

@router.post("/", response_model=schemas.TaskOut)
async def create_task(
    task_in: schemas.TaskCreate,
    current_user: User = Depends(deps.get_current_user),
    db: AsyncSession = Depends(deps.get_db)
):
    if current_user.role != 'client':
         pass

    # Force client_id to match token owner
    task_in.client_id = current_user.id
    
    result = await db.execute(select(User).where(User.id == task_in.client_id))
    client = result.scalars().first()
    if not client:
        client = User(id=task_in.client_id, contact=f"user_{task_in.client_id}", display_name="Test User", role="client")
        db.add(client)
        await db.flush()
    
    # Create exact location WKT
    location_wkt = f'POINT({task_in.lon} {task_in.lat})'
    
    new_task = Task(
        title=task_in.title,
        description=task_in.description,
        category=task_in.category,
        price_cents=task_in.price_cents,
        urgency=task_in.urgency,
        client_id=task_in.client_id,
        location=location_wkt,
        # Address Fields
        street=task_in.street,
        street_number=task_in.street_number,
        city=task_in.city,
        postal_code=task_in.postal_code,
        province=task_in.province,
        address_extra=task_in.address_extra,
        place_id=task_in.place_id,
        formatted_address=task_in.formatted_address,
        address_line=task_in.address_line,
        access_notes=task_in.access_notes,
        scheduled_at=task_in.scheduled_at,
        status=TaskStatus.POSTED,
        version=1
    )
    
    db.add(new_task)
    await db.commit()
    await db.refresh(new_task)
    
    # Calculate public_location with PostGIS Grid Snap (500m in WebMercator)
    from sqlalchemy import text
    await db.execute(text("""
        UPDATE tasks 
        SET public_location = ST_Transform(
            ST_SnapToGrid(ST_Transform(location, 3857), 500),
            4326
        )
        WHERE id = :task_id
    """), {"task_id": new_task.id})
    await db.commit()
    await db.refresh(new_task)
    
    return _to_task_out(new_task)

@router.get("/nearby", response_model=List[schemas.TaskOut])
async def get_nearby_tasks(
    lat: float,
    lon: float,
    radius_km: float = 50.0,
    current_user: User = Depends(deps.get_current_user),
    db: AsyncSession = Depends(deps.get_db)
):
    # PostGIS query
    # ST_DWithin takes meters if using geography, or degrees if geometry.
    # We are using geometry(POINT, 4326). 
    # For MVP, simple bounding box or distance approximation if PostGIS setup is complex.
    # Note: ST_DistanceSphere is good for lat/lon.
    location = f'POINT({lon} {lat})'
    
    stmt = select(Task).where(
        Task.status == TaskStatus.POSTED
    ).options(
        selectinload(Task.proofs), 
        selectinload(Task.offers),
        selectinload(Task.client).selectinload(User.reviews_received)
    )
    
    # Filter by distance (Pseudo-code if PostGIS not fully activated, but here we assume it works)
    # stmt = stmt.where(func.ST_DistanceSphere(Task.location, func.ST_GeomFromText(location, 4326)) <= radius_km * 1000)
    
    # For MVP/SQLite compatibility fallback (though we use PG): just return all posted.
    # Ideally:
    stmt = stmt.order_by(Task.created_at.desc())
    
    result = await db.execute(stmt)
    tasks = result.scalars().all()
    
    # Manual hydration for offers (same pattern as /tasks/created)
    final_list = []
    for t in tasks:
        offer_stmt = select(TaskOffer).where(TaskOffer.task_id == t.id).options(selectinload(TaskOffer.helper).selectinload(User.reviews_received))
        offer_res = await db.execute(offer_stmt)
        offers_list = offer_res.scalars().all()
        # Nearby tasks: always use blurred location, no exact address
        final_list.append(_to_task_out(t, explicit_offers=offers_list, show_exact_address=False))
        
    return final_list

@router.get("/created", response_model=List[schemas.TaskOut])
async def get_created_tasks(
    client_id: int,
    current_user: User = Depends(deps.get_current_user),
    db: AsyncSession = Depends(deps.get_db)
):
    # Verify access
    if current_user.id != client_id and current_user.role != 'admin':
        # Clients can only see their own created? 
        # Helpers might need to see CLIENT's history? 
        # For now, restrict created to owner
        raise HTTPException(status_code=403, detail="Not authorized")
    stmt = select(Task).where(Task.client_id == client_id).order_by(Task.created_at.desc()).options(
        selectinload(Task.proofs)
    )
    result = await db.execute(stmt)
    tasks = result.scalars().all()
    # Manual hydration hack to ensure offers are visible
    final_list = []
    for t in tasks:
        offer_stmt = select(TaskOffer).where(TaskOffer.task_id == t.id).options(selectinload(TaskOffer.helper).selectinload(User.reviews_received))
        offer_res = await db.execute(offer_stmt)
        offers_list = offer_res.scalars().all()
        print(f"DEBUG /tasks/created: Task {t.id} has {len(offers_list)} offers")
        for o in offers_list:
            print(f"   -> Offer {o.id}: helper={o.helper_id}, price={o.price_cents}, status={o.status}")
        final_list.append(_to_task_out(t, explicit_offers=offers_list))
        
    return final_list

@router.get("/assigned", response_model=List[schemas.TaskOut])
async def get_assigned_tasks(
    helper_id: int,
    current_user: User = Depends(deps.get_current_user),
    db: AsyncSession = Depends(deps.get_db)
):
    if current_user.id != helper_id:
        raise HTTPException(status_code=403, detail="Not authorized")
    # Find active assignments
    # Using TaskAssignment table logic or inferred from status/offers?
    # Phase 2 logic: TaskAssignment exists OR selected_offer.helper_id == helper_id
    # Simpler: Join TaskAssignment
    from app.models.models import TaskAssignment
    
    stmt = select(Task).join(TaskAssignment, Task.id == TaskAssignment.task_id).where(
        TaskAssignment.helper_id == helper_id
    ).options(selectinload(Task.proofs))
    
    result = await db.execute(stmt)
    return [_to_task_out(t) for t in result.scalars().all()]

import logging
logger = logging.getLogger("uvicorn")

@router.get("/debug_probe")
async def debug_probe():
    logger.info("DEBUG_EP: Probe endpoint hit!")
    return {"status": "alive", "message": "I am the new code with manual hydration!"}

@router.get("/{task_id}", response_model=schemas.TaskOut)
async def get_task(
    task_id: int,
    current_user: User = Depends(deps.get_current_user),
    db: AsyncSession = Depends(deps.get_db)
):
    from app.models.models import TaskAssignment
    
    stmt = select(Task).where(Task.id == task_id).options(
        selectinload(Task.proofs)
    )
    result = await db.execute(stmt)
    task = result.scalars().first()
    if not task:
        raise HTTPException(status_code=404, detail="Task not found")

    # Manual hydration for offers
    offer_stmt = select(TaskOffer).where(TaskOffer.task_id == task.id).options(selectinload(TaskOffer.helper).selectinload(User.reviews_received))
    offer_res = await db.execute(offer_stmt)
    offers_list = offer_res.scalars().all()
    
    # Determine visibility: exact address shown to owner or assigned helper (status >= ASSIGNED)
    is_owner = current_user.id == task.client_id
    
    # Check if user is the assigned helper
    is_assigned_helper = False
    if current_user.role == 'helper' and task.status in ['assigned', 'in_progress', 'in_confirmation', 'completed']:
        # Check assignment
        assign_result = await db.execute(
            select(TaskAssignment).where(
                TaskAssignment.task_id == task.id,
                TaskAssignment.helper_id == current_user.id
            )
        )
        assignment = assign_result.scalars().first()
        is_assigned_helper = assignment is not None
    
    show_exact = is_owner or is_assigned_helper
    
    return _to_task_out(task, explicit_offers=offers_list, show_exact_address=show_exact)

def _to_task_out(task: Task, explicit_offers: List[TaskOffer] = None, show_exact_address: bool = True) -> schemas.TaskOut:
    """Convert Task model to TaskOut schema.
    
    Args:
        task: The Task model
        explicit_offers: Pre-loaded offers (for manual hydration)
        show_exact_address: If True, show exact location and address. If False, use public_location.
    """
    # Determine which location to use
    if show_exact_address:
        sh = to_shape(task.location)
        lat, lon = sh.y, sh.x
    else:
        # Use blurred public_location if available
        if task.public_location:
            sh = to_shape(task.public_location)
            lat, lon = sh.y, sh.x
        else:
            sh = to_shape(task.location)
            lat, lon = sh.y, sh.x

    # Client Profile Construction
    client_profile = None
    if 'client' in task.__dict__ and task.client:
         # Only count VISIBLE reviews
         reviews = task.client.reviews_received if 'reviews_received' in task.client.__dict__ else []
         visible_reviews = [r for r in reviews if r.status == ReviewStatus.VISIBLE.value]
         avg_rating = sum([r.stars for r in visible_reviews]) / len(visible_reviews) if visible_reviews else 0.0
         
         client_profile = schemas.UserPublicProfile(
             id=task.client.id,
             display_name=(lambda n: f"{n.split()[0]} {n.split()[1][0]}." if n and len(n.split()) > 1 else n or f"User {task.client.id}")(task.client.name),
             avatar_url=task.client.avatar_url,
             avg_rating=avg_rating,
             review_count=len(visible_reviews)
         )

    # Use explicit offers if provided
    final_offers = explicit_offers if explicit_offers is not None else (task.offers if 'offers' in task.__dict__ else [])

    # Build offer responses with helper ratings
    offer_responses = []
    for o in final_offers:
        helper_rating = 0.0
        helper_review_count = 0
        if o.helper and hasattr(o.helper, 'reviews_received'):
            helper_reviews = [r for r in o.helper.reviews_received if r.status == ReviewStatus.VISIBLE.value]
            if helper_reviews:
                helper_rating = sum([r.stars for r in helper_reviews]) / len(helper_reviews)
                helper_review_count = len(helper_reviews)
        
        offer_responses.append(schemas.TaskOfferResponse(
            id=o.id,
            task_id=o.task_id,
            helper_id=o.helper_id,
            status=o.status,
            price_cents=o.price_cents,
            message=o.message,
            created_at=o.created_at,
            updated_at=o.updated_at,
            helper_name=o.helper.name if o.helper else "Unknown Helper",
            helper_avatar_url=o.helper.avatar_url if o.helper else None,
            helper_rating=helper_rating
        ))

    return schemas.TaskOut(
        id=task.id,
        client_id=task.client_id,
        client=client_profile,
        title=task.title,
        description=task.description,
        category=task.category,
        price_cents=task.price_cents,
        urgency=task.urgency,
        status=task.status,
        created_at=task.created_at,
        expires_at=task.expires_at,
        lat=lat,
        lon=lon,
        # Address fields - only included if show_exact_address is True
        street=task.street if show_exact_address else None,
        street_number=task.street_number if show_exact_address else None,
        city=task.city,  # City is safe to show always
        postal_code=task.postal_code if show_exact_address else None,
        province=task.province if show_exact_address else None,
        address_extra=task.address_extra if show_exact_address else None,
        place_id=task.place_id if show_exact_address else None,
        formatted_address=task.formatted_address if show_exact_address else None,
        address_line=task.address_line if show_exact_address else None,
        access_notes=task.access_notes if show_exact_address else None,
        scheduled_at=task.scheduled_at,
        version=task.version,
        selected_offer_id=task.selected_offer_id,
        assigned_at=task.assigned_at,
        started_at=task.started_at,
        completion_requested_at=task.completion_requested_at,
        completed_at=task.completed_at,
        dispute_open_until=task.dispute_open_until,
        proofs=[schemas.TaskProofResponse.from_orm(p) for p in task.proofs] if 'proofs' in task.__dict__ else [],
        offers=offer_responses
    )

@router.patch("/{task_id}", response_model=schemas.TaskOut)
async def update_task(
    task_id: int,
    task_in: schemas.TaskUpdate,
    current_user: User = Depends(deps.get_current_user),
    db: AsyncSession = Depends(deps.get_db)
):
    # Verify ownership
    result = await db.execute(select(Task).where(Task.id == task_id).options(selectinload(Task.proofs)))
    task = result.scalars().first()
    
    if not task:
        raise HTTPException(status_code=404, detail="Task not found")
        
    if task.client_id != current_user.id:
        raise HTTPException(status_code=403, detail="Not authorized")
        
    # Guard: Editing allowed only if POSTED
    if task.status != TaskStatus.POSTED:
        raise HTTPException(status_code=400, detail="Cannot edit task that is not in POSTED state")
        
    # Update Fields
    if task_in.title is not None:
        task.title = task_in.title
    if task_in.description is not None:
        task.description = task_in.description
    if task_in.category is not None:
        task.category = task_in.category
    if task_in.price_cents is not None:
        task.price_cents = task_in.price_cents
    if task_in.urgency is not None:
        task.urgency = task_in.urgency
    
    # Update location if changed
    if task_in.lat is not None and task_in.lon is not None:
         task.location = f'POINT({task_in.lon} {task_in.lat})'
         
    if task_in.address_line is not None:
        task.address_line = task_in.address_line
    if task_in.city is not None:
        task.city = task_in.city
    
    # Increment Revision
    task.version += 1
    
    db.add(task)
    await db.commit()
    await db.refresh(task)
    
    return _to_task_out(task)

# --- OFFERS ---

@router.post("/{task_id}/offers", response_model=TaskOfferResponse)
async def create_offer(
    task_id: int,
    offer_in: TaskOfferCreate,
    current_user: User = Depends(deps.get_current_user),
    db: AsyncSession = Depends(deps.get_db)
):
    from app.models.models import MessageType
    
    helper_id = current_user.id
    # Verify Task Exists and is Posted
    task = await db.get(Task, task_id)
    if not task:
        raise HTTPException(status_code=404, detail="Task not found")
        
    # Check if offer already exists for this helper (Upsert logic)
    result = await db.execute(select(TaskOffer).where(
        TaskOffer.task_id == task_id,
        TaskOffer.helper_id == helper_id
    ))
    existing_offer = result.scalars().first()
    
    is_update = existing_offer is not None
    
    if existing_offer:
        existing_offer.price_cents = offer_in.price_cents
        existing_offer.message = offer_in.message
        existing_offer.status = OfferStatus.SUBMITTED # Reset status on update
        db.add(existing_offer)
        await db.commit()
        await db.refresh(existing_offer)
        offer = existing_offer
    else:
        new_offer = TaskOffer(
            task_id=task_id,
            helper_id=helper_id,
            price_cents=offer_in.price_cents,
            message=offer_in.message,
            status=OfferStatus.SUBMITTED
        )
        db.add(new_offer)
        await db.commit()
        await db.refresh(new_offer)
        offer = new_offer
    
    # Auto-post offer as chat message
    # Get or create thread
    thread_result = await db.execute(select(TaskThread).where(
        TaskThread.task_id == task_id,
        TaskThread.helper_id == helper_id
    ))
    thread = thread_result.scalars().first()
    
    if not thread:
        thread = TaskThread(
            task_id=task_id,
            client_id=task.client_id,
            helper_id=helper_id
        )
        db.add(thread)
        await db.commit()
        await db.refresh(thread)
    
    # Create offer message
    price_formatted = f"€{offer.price_cents / 100:.2f}"
    action_word = "updated" if is_update else "submitted"
    msg_body = f"💰 Offer {action_word}: {price_formatted}"
    if offer.message:
        msg_body += f"\n📝 {offer.message}"
    
    offer_message = TaskMessage(
        thread_id=thread.id,
        sender_id=helper_id,
        body=msg_body,
        type=MessageType.OFFER_UPDATE,
        payload={"offer_id": offer.id, "price_cents": offer.price_cents}
    )
    db.add(offer_message)
    await db.commit()
    
    # Publish WebSocket event to notify client
    from app.core.redis_client import redis_client
    await redis_client.publish_event(
        user_id=task.client_id,
        event_type="new_offer",
        payload={"task_id": task_id, "offer_id": offer.id, "helper_id": helper_id}
    )
    
    return offer

@router.get("/{task_id}/offers", response_model=List[TaskOfferResponse])
async def list_offers(
    task_id: int,
    db: AsyncSession = Depends(deps.get_db)
):
    stmt = select(TaskOffer).where(TaskOffer.task_id == task_id)
    result = await db.execute(stmt)
    return result.scalars().all()

@router.post("/{task_id}/offers/{offer_id}/select", response_model=schemas.TaskOut)
async def select_offer(
    task_id: int,
    offer_id: int,
    current_user: User = Depends(deps.get_current_user),
    db: AsyncSession = Depends(deps.get_db)
):
    # Verify ownership
    print(f"DEBUG: select_offer called for task {task_id}, offer {offer_id} by user {current_user.id}")
    task_check = await db.get(Task, task_id)
    if not task_check:
        print(f"DEBUG: Task {task_id} not found")
        raise HTTPException(status_code=404, detail="Task not found")
    if task_check.client_id != current_user.id:
        print(f"DEBUG: User {current_user.id} not authorized for task {task_id} (owner: {task_check.client_id})")
        raise HTTPException(status_code=403, detail="Not authorized to accept offers for this task")

    from app.services.task_service import task_service
    # Pass db, task_id, offer_id. Service will re-fetch, which is fine (cached in session identity map)
    try:
        print("DEBUG: Calling task_service.select_offer")
        task = await task_service.select_offer(db, task_id, offer_id)
        print("DEBUG: task_service.select_offer returned successfully")
        return _to_task_out(task)
    except Exception as e:
        import traceback
        traceback.print_exc()
        print(f"DEBUG: Error in task_service.select_offer: {e}")
        raise HTTPException(status_code=500, detail=f"Internal Server Error: {e}")

@router.post("/{task_id}/offers/{offer_id}/reject")
async def reject_offer(
    task_id: int,
    offer_id: int,
    current_user: User = Depends(deps.get_current_user),
    db: AsyncSession = Depends(deps.get_db)
):
    """Client rejects an offer."""
    from app.models.models import MessageType
    
    # Verify ownership
    task = await db.get(Task, task_id)
    if not task:
        raise HTTPException(status_code=404, detail="Task not found")
    if task.client_id != current_user.id:
        raise HTTPException(status_code=403, detail="Not authorized")
    
    # Get offer
    offer = await db.get(TaskOffer, offer_id)
    if not offer or offer.task_id != task_id:
        raise HTTPException(status_code=404, detail="Offer not found")
    
    # Update offer status
    offer.status = OfferStatus.DECLINED
    db.add(offer)
    await db.commit()
    
    # Post rejection message to chat
    thread_result = await db.execute(select(TaskThread).where(
        TaskThread.task_id == task_id,
        TaskThread.helper_id == offer.helper_id
    ))
    thread = thread_result.scalars().first()
    
    if thread:
        rejection_message = TaskMessage(
            thread_id=thread.id,
            sender_id=current_user.id,
            body="❌ Your offer was declined.",
            type=MessageType.SYSTEM,
            payload={"offer_id": offer.id, "action": "rejected"}
        )
        db.add(rejection_message)
        await db.commit()
    
    # Publish WebSocket events
    from app.core.redis_client import redis_client
    
    # Notify Client (to trigger refresh)
    await redis_client.publish_event(
        user_id=current_user.id,
        event_type="offer_status_changed",
        payload={"task_id": task_id, "offer_id": offer.id, "status": "rejected"}
    )
    
    # Notify Helper
    await redis_client.publish_event(
        user_id=offer.helper_id,
        event_type="offer_rejected",
        payload={"task_id": task_id, "offer_id": offer.id}
    )

    return {"status": "rejected"}

# --- CHAT ---

@router.post("/{task_id}/threads/{helper_id}/messages", response_model=TaskMessageResponse)
async def send_message(
    task_id: int,
    helper_id: int,
    msg_in: TaskMessageCreate,
    current_user: User = Depends(deps.get_current_user),
    db: AsyncSession = Depends(deps.get_db)
):
    sender_id = current_user.id
    # Get or Create Thread
    result = await db.execute(select(TaskThread).where(
        TaskThread.task_id == task_id,
        TaskThread.helper_id == helper_id
    ))
    thread = result.scalars().first()
    
    if not thread:
        task = await db.get(Task, task_id)
        if not task: raise HTTPException(404, "Task not found")
        thread = TaskThread(
            task_id=task_id,
            client_id=task.client_id,
            helper_id=helper_id
        )
        db.add(thread)
        await db.flush() # flush to get thread.id
        
    new_msg = TaskMessage(
        thread_id=thread.id,
        sender_id=sender_id,
        body=msg_in.body,
        type=msg_in.type,
        payload=msg_in.payload
    )
    db.add(new_msg)
    await db.commit()
    await db.refresh(new_msg)
    
    # Publish WebSocket event to notify the other party
    from app.core.redis_client import redis_client
    # Determine recipient: if sender is client, notify helper; if sender is helper, notify client
    recipient_id = helper_id if sender_id == thread.client_id else thread.client_id
    await redis_client.publish_event(
        user_id=recipient_id,
        event_type="new_message",
        payload={"thread_id": thread.id, "task_id": task_id, "sender_id": sender_id}
    )
    
    return new_msg

@router.get("/{task_id}/threads/{helper_id}/messages", response_model=List[TaskMessageResponse])
async def list_messages(
    task_id: int,
    helper_id: int,
    db: AsyncSession = Depends(deps.get_db)
):
    # Find thread
    result = await db.execute(select(TaskThread).where(
        TaskThread.task_id == task_id,
        TaskThread.helper_id == helper_id
    ))
    thread = result.scalars().first()
    if not thread:
        return []
        
    msgs_res = await db.execute(select(TaskMessage).where(TaskMessage.thread_id == thread.id).order_by(TaskMessage.created_at.asc()))
    return msgs_res.scalars().all()

# --- PROOFS ---

@router.post("/{task_id}/proofs")
async def add_proof(
    task_id: int,
    storage_key: str, # In real app, this is result of upload
    kind: str = "photo",
    current_user: User = Depends(deps.get_current_user),
    db: AsyncSession = Depends(deps.get_db)
):
    proof = TaskProof(
        task_id=task_id,
        uploader_id=current_user.id,
        kind=kind,
        storage_key=storage_key
    )
    db.add(proof)
    await db.commit()
    return {"status": "ok", "id": proof.id}

@router.post("/{task_id}/proofs/upload")
async def upload_proof_image(
    task_id: int,
    file: UploadFile = File(...),
    current_user: User = Depends(deps.get_current_user),
    db: AsyncSession = Depends(deps.get_db)
):
    # Validate file
    if not file.content_type.startswith('image/'):
        raise HTTPException(400, "Invalid file type")
    
    # Generate ID
    file_ext = file.filename.split('.')[-1]
    filename = f"{uuid.uuid4()}.{file_ext}"
    
    # Ensure directory exists (redundant if main.py mounted it but good for safety)
    save_dir = "static/proofs"
    os.makedirs(save_dir, exist_ok=True)
    
    file_path = os.path.join(save_dir, filename)
    
    with open(file_path, "wb") as buffer:
        shutil.copyfileobj(file.file, buffer)
        
    # Create DB Record
    # URL path to serve
    storage_key = f"/static/proofs/{filename}"
    
    proof = TaskProof(
        task_id=task_id,
        uploader_id=current_user.id,
        kind="photo",
        storage_key=storage_key
    )
    db.add(proof)
    await db.commit()
    
    return {"status": "ok", "storage_key": storage_key, "id": proof.id}

# --- LIFECYCLE ---

@router.post("/{task_id}/start", response_model=schemas.TaskOut)
async def start_task(
    task_id: int,
    current_user: User = Depends(deps.get_current_user),
    db: AsyncSession = Depends(deps.get_db)
):
    helper_id = current_user.id
    from app.services.task_service import task_service
    task = await task_service.start_task(db, task_id, helper_id)
    return _to_task_out(task)

@router.post("/{task_id}/complete-request", response_model=schemas.TaskOut)
async def request_completion(
    task_id: int,
    current_user: User = Depends(deps.get_current_user),
    db: AsyncSession = Depends(deps.get_db)
):
    helper_id = current_user.id
    from app.services.task_service import task_service
    task = await task_service.request_completion(db, task_id, helper_id)
    return _to_task_out(task)

@router.post("/{task_id}/confirm", response_model=schemas.TaskOut)
async def confirm_completion(
    task_id: int,
    current_user: User = Depends(deps.get_current_user),
    db: AsyncSession = Depends(deps.get_db)
):
    client_id = current_user.id
    from app.services.task_service import task_service
    task = await task_service.confirm_completion(db, task_id, client_id)
    return _to_task_out(task)
