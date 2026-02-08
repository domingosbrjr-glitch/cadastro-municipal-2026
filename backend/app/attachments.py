import os
from datetime import datetime
from fastapi import APIRouter, UploadFile, File, Form, Depends, HTTPException
from sqlalchemy.orm import Session
from .db import get_db
from .settings import settings
from .auth import require_roles
from . import models

router = APIRouter(prefix="/attachments", tags=["attachments"])

@router.post("/upload")
async def upload_attachment(
    uuid: str = Form(...),
    entity_type: str = Form(...),
    entity_uuid: str = Form(...),
    purpose: str = Form(""),
    file: UploadFile = File(...),
    db: Session = Depends(get_db),
    user=Depends(require_roles("agent","supervisor","admin","support")),
):
    os.makedirs(settings.upload_dir, exist_ok=True)
    raw = await file.read()
    if len(raw) > 5 * 1024 * 1024:
        raise HTTPException(status_code=400, detail="File too large")

    safe_name = f"{uuid}_{file.filename}".replace("/", "_")
    path = os.path.join(settings.upload_dir, safe_name)
    with open(path, "wb") as f:
        f.write(raw)

    att = models.Attachment(
        uuid=uuid,
        entity_type=entity_type,
        entity_uuid=entity_uuid,
        purpose=purpose,
        mime=file.content_type or "application/octet-stream",
        size_bytes=len(raw),
        storage_path=path,
        created_at=datetime.utcnow(),
    )
    db.add(att)
    db.commit()
    return {"ok": True, "uuid": uuid, "size": len(raw)}
