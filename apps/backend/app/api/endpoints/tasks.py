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
from app.models.models import Task, TaskStatus, TaskOffer, TaskThread, TaskMessage, TaskProof, OfferStatus
from app.models.user import User
from app.schemas import tasks as schemas
from app.schemas.task_offers import TaskOfferCreate, TaskOfferResponse
from app.schemas.chat import TaskMessageCreate, TaskMessageResponse, TaskThreadResponse

router = APIRouter()

@router.post("/", response_model=schemas.TaskOut)
async def create_task(
    task_in: schemas.TaskCreate,
    db: AsyncSession = Depends(deps.get_db)
):
    # Verify client exists (optional for MVP speed but good practice)
    result = await db.execute(select(User).where(User.id == task_in.client_id))
    client = result.scalars().first()
    if not client:
        # Auto-create a test user if not exists for easier testing
        client = User(id=task_in.client_id, contact=f"user_{task_in.client_id}", display_name="Test User", role="client")
        db.add(client)
        await db.flush()
    
    # Create Task
    location_wkt = f'POINT({task_in.lon} {task_in.lat})'
    
    new_task = Task(
        title=task_in.title,
        description=task_in.description,
        category=task_in.category,
        price_cents=task_in.price_cents,
        urgency=task_in.urgency,
        client_id=task_in.client_id,
        location=location_wkt,
        # New Phase 2 Fields
        address_line=task_in.address_line,
        city=task_in.city,
        scheduled_at=task_in.scheduled_at,
        status=TaskStatus.POSTED,
        version=1
    )
    
    db.add(new_task)
    await db.commit()
    await db.refresh(new_task)
    
    return _to_task_out(new_task)

    return _to_task_out(new_task)

@router.get("/nearby", response_model=List[schemas.TaskOut])
async def get_nearby_tasks(
    lat: float,
    lon: float,
    radius_km: float = 50.0,
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
    return [_to_task_out(t) for t in tasks]

@router.get("/created", response_model=List[schemas.TaskOut])
async def get_created_tasks(
    client_id: int,
    db: AsyncSession = Depends(deps.get_db)
):
    stmt = select(Task).where(Task.client_id == client_id).order_by(Task.created_at.desc()).options(selectinload(Task.proofs))
    result = await db.execute(stmt)
    return [_to_task_out(t) for t in result.scalars().all()]

@router.get("/assigned", response_model=List[schemas.TaskOut])
async def get_assigned_tasks(
    helper_id: int,
    db: AsyncSession = Depends(deps.get_db)
):
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

@router.get("/{task_id}", response_model=schemas.TaskOut)
async def get_task(
    task_id: int,
    db: AsyncSession = Depends(deps.get_db)
):
    stmt = select(Task).where(Task.id == task_id).options(selectinload(Task.proofs))
    result = await db.execute(stmt)
    task = result.scalars().first()
    if not task:
        raise HTTPException(status_code=404, detail="Task not found")
    return _to_task_out(task)

def _to_task_out(task: Task) -> schemas.TaskOut:
    sh = to_shape(task.location)
    
    # Client Profile Construction
    client_profile = None
    if 'client' in task.__dict__ and task.client:
         # Safely access reviews if loaded
         reviews = task.client.reviews_received if 'reviews_received' in task.client.__dict__ else []
         avg_rating = sum([r.stars for r in reviews]) / len(reviews) if reviews else 0.0
         
         client_profile = schemas.UserPublicProfile(
             id=task.client.id,
             display_name=(lambda n: f"{n.split()[0]} {n.split()[1][0]}." if n and len(n.split()) > 1 else n or f"User {task.client.id}")(task.client.name),
             avatar_url=None, # Placeholder until User model has avatar
             avg_rating=avg_rating,
             review_count=len(reviews)
         )

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
        lat=sh.y,
        lon=sh.x,
        # New Fields
        address_line=task.address_line,
        city=task.city,
        scheduled_at=task.scheduled_at,
        version=task.version,
        selected_offer_id=task.selected_offer_id,
        assigned_at=task.assigned_at,
        started_at=task.started_at,
        completion_requested_at=task.completion_requested_at,
        completed_at=task.completed_at,
        dispute_open_until=task.dispute_open_until,
        proofs=[schemas.TaskProofResponse.from_orm(p) for p in task.proofs] if 'proofs' in task.__dict__ else [],
        offers=[schemas.TaskOfferResponse.from_orm(o) for o in task.offers] if 'offers' in task.__dict__ else []
    )

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
