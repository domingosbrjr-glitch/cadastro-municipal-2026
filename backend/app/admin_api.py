from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session
from sqlalchemy import func
from .db import get_db
from .auth import require_roles
from . import models

router = APIRouter(prefix="/admin/api", tags=["admin-api"])

@router.get("/stats")
def stats(db: Session = Depends(get_db), user=Depends(require_roles("supervisor","admin"))):
    people = db.query(func.count(models.Person.id)).scalar() or 0
    households = db.query(func.count(models.Household.id)).scalar() or 0
    pending_cpf = db.query(func.count(models.Person.id)).filter(models.Person.pending_cpf == True).scalar() or 0
    conflicts = db.query(func.count(models.Conflict.id)).scalar() or 0
    return {"people": people, "households": households, "pending_cpf": pending_cpf, "conflicts": conflicts}

@router.get("/pending-cpf")
def pending_cpf(db: Session = Depends(get_db), user=Depends(require_roles("supervisor","admin"))):
    rows = db.query(models.Person).filter(models.Person.pending_cpf == True).order_by(models.Person.updated_at.desc()).limit(500).all()
    return [{
        "uuid": p.uuid,
        "full_name": p.full_name,
        "ipm": p.ipm,
        "phone": p.phone,
        "bairro": p.bairro,
        "pending_reason": p.pending_reason,
        "updated_at": p.updated_at.isoformat(),
    } for p in rows]

@router.get("/conflicts")
def conflicts(db: Session = Depends(get_db), user=Depends(require_roles("supervisor","admin"))):
    rows = db.query(models.Conflict).order_by(models.Conflict.created_at.desc()).limit(500).all()
    return [{
        "created_at": c.created_at.isoformat(),
        "device_id": c.device_id,
        "actor_email": c.actor_email,
        "entity_type": c.entity_type,
        "entity_uuid": c.entity_uuid,
        "reason": c.reason,
        "client_item_id": c.client_item_id,
    } for c in rows]
