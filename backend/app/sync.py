from fastapi import APIRouter, Depends, Query
from sqlalchemy.orm import Session
from datetime import datetime
from .db import get_db
from .auth import require_roles
from . import models, schemas
from .utils import is_valid_cpf, normalize_cpf

router = APIRouter(prefix="/sync", tags=["sync"])

def audit(db: Session, actor: str, action: str, entity_type: str, entity_uuid: str, detail: dict):
    db.add(models.AuditLog(
        actor_email=actor,
        action=action,
        entity_type=entity_type,
        entity_uuid=entity_uuid,
        detail=detail,
        created_at=datetime.utcnow()
    ))

def snapshot_person(p: models.Person) -> dict:
    return {"uuid": p.uuid, "cpf": p.cpf, "ipm": p.ipm, "pending_cpf": p.pending_cpf, "full_name": p.full_name, "version": p.version}

def snapshot_household(h: models.Household) -> dict:
    return {"uuid": h.uuid, "bairro": h.bairro, "referencia": h.referencia, "version": h.version}

def record_conflict(db: Session, device_id: str, actor: str, item: schemas.SyncItem, reason: str, server_snapshot: dict):
    db.add(models.Conflict(
        device_id=device_id,
        actor_email=actor,
        entity_type=item.entity_type,
        entity_uuid=item.entity_uuid,
        reason=reason,
        client_item_id=item.client_item_id,
        client_payload=item.payload,
        server_snapshot=server_snapshot,
        created_at=datetime.utcnow()
    ))

@router.post("/push", response_model=schemas.SyncPushOut)
def sync_push(payload: schemas.SyncPushIn, db: Session = Depends(get_db), user=Depends(require_roles("agent","supervisor","admin","support"))):
    results = []
    for item in payload.items:
        if item.entity_type == "household":
            results.append(_apply_household(payload.device_id, item, db, user.email))
        else:
            results.append(_apply_person(payload.device_id, item, db, user.email))
    db.commit()
    return schemas.SyncPushOut(results=results)

@router.get("/pull", response_model=schemas.SyncPullOut)
def sync_pull(
    since: str = Query("", description="ISO8601 timestamp. Retorna registros atualizados após esse tempo."),
    limit: int = Query(500, ge=1, le=5000),
    db: Session = Depends(get_db),
    user=Depends(require_roles("agent","supervisor","admin","support")),
):
    dt = None
    if since:
        try:
            dt = datetime.fromisoformat(since.replace("Z","+00:00")).replace(tzinfo=None)
        except Exception:
            dt = None

    qh = db.query(models.Household)
    qp = db.query(models.Person)
    if dt:
        qh = qh.filter(models.Household.updated_at > dt)
        qp = qp.filter(models.Person.updated_at > dt)

    households = qh.order_by(models.Household.updated_at.asc()).limit(limit).all()
    people = qp.order_by(models.Person.updated_at.asc()).limit(limit).all()

    return schemas.SyncPullOut(
        server_time=datetime.utcnow().isoformat(),
        households=[schemas.HouseholdOut(
            uuid=h.uuid,
            territory=h.territory,
            bairro=h.bairro,
            logradouro=h.logradouro,
            numero=h.numero,
            referencia=h.referencia,
            version=h.version,
            updated_at=h.updated_at.isoformat(),
        ) for h in households],
        people=[schemas.PersonOut(
            uuid=p.uuid,
            household_uuid=p.household_uuid,
            cpf=p.cpf,
            ipm=p.ipm,
            pending_cpf=p.pending_cpf,
            pending_reason=p.pending_reason,
            full_name=p.full_name,
            mother_name=p.mother_name,
            birth_date=p.birth_date,
            phone=p.phone,
            bairro=p.bairro,
            referencia=p.referencia,
            general=p.general or {},
            assistance=p.assistance or {},
            version=p.version,
            updated_at=p.updated_at.isoformat(),
        ) for p in people],
    )

def _apply_household(device_id: str, item: schemas.SyncItem, db: Session, actor: str) -> schemas.SyncResult:
    h = db.query(models.Household).filter(models.Household.uuid == item.entity_uuid).first()
    if item.op == "create" and h:
        record_conflict(db, device_id, actor, item, "household_exists", snapshot_household(h))
        return schemas.SyncResult(client_item_id=item.client_item_id, status="conflict", server_version=h.version, reason="household_exists")
    if not h:
        h = models.Household(uuid=item.entity_uuid)
        db.add(h)

    if item.base_version and h.version != item.base_version:
        record_conflict(db, device_id, actor, item, "version_mismatch", snapshot_household(h))
        return schemas.SyncResult(client_item_id=item.client_item_id, status="conflict", server_version=h.version, reason="version_mismatch")

    p = item.payload
    for k in ["territory","bairro","logradouro","numero","referencia"]:
        if k in p:
            setattr(h, k, p.get(k) or "")
    h.version = (h.version or 0) + 1
    h.updated_at = datetime.utcnow()
    audit(db, actor, "sync_upsert", "household", h.uuid, {"device_id": device_id, "client_item": item.client_item_id, "version": h.version})
    return schemas.SyncResult(client_item_id=item.client_item_id, status="accepted", server_version=h.version)

def _apply_person(device_id: str, item: schemas.SyncItem, db: Session, actor: str) -> schemas.SyncResult:
    person = db.query(models.Person).filter(models.Person.uuid == item.entity_uuid).first()
    if item.op == "create" and person:
        record_conflict(db, device_id, actor, item, "person_exists", snapshot_person(person))
        return schemas.SyncResult(client_item_id=item.client_item_id, status="conflict", server_version=person.version, reason="person_exists")

    if not person:
        person = models.Person(uuid=item.entity_uuid, household_uuid=item.payload.get("household_uuid",""))
        db.add(person)

    if item.base_version and person.version != item.base_version:
        record_conflict(db, device_id, actor, item, "version_mismatch", snapshot_person(person))
        return schemas.SyncResult(client_item_id=item.client_item_id, status="conflict", server_version=person.version, reason="version_mismatch")

    p = item.payload
    cpf = normalize_cpf(p.get("cpf",""))
    pending_cpf = bool(p.get("pending_cpf", False))

    if cpf:
        if not is_valid_cpf(cpf):
            return schemas.SyncResult(client_item_id=item.client_item_id, status="rejected", reason="cpf_invalid")
        other = db.query(models.Person).filter(models.Person.cpf == cpf, models.Person.uuid != person.uuid).first()
        if other:
            record_conflict(db, device_id, actor, item, "cpf_already_exists", snapshot_person(person))
            return schemas.SyncResult(client_item_id=item.client_item_id, status="conflict", server_version=person.version, reason="cpf_already_exists")

    for k in ["household_uuid","full_name","mother_name","birth_date","phone","bairro","referencia","ipm","pending_reason"]:
        if k in p:
            setattr(person, k, p.get(k) or "")

    person.cpf = cpf
    person.pending_cpf = pending_cpf if not cpf else False

    if "general" in p and isinstance(p["general"], dict):
        person.general = p["general"]
    if "assistance" in p and isinstance(p["assistance"], dict):
        person.assistance = p["assistance"]

    person.version = (person.version or 0) + 1
    person.updated_at = datetime.utcnow()
    audit(db, actor, "sync_upsert", "person", person.uuid, {"device_id": device_id, "client_item": item.client_item_id, "version": person.version})
    return schemas.SyncResult(client_item_id=item.client_item_id, status="accepted", server_version=person.version)
