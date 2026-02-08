from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session
from .db import get_db
from .auth import require_roles
from . import models

router = APIRouter(prefix="/admin", tags=["admin"])

@router.get("/pending-cpf", response_class=None)
def pending_cpf(db: Session = Depends(get_db), user=Depends(require_roles("supervisor","admin"))):
    rows = db.query(models.Person).filter(models.Person.pending_cpf == True).order_by(models.Person.updated_at.desc()).limit(500).all()
    html = ["<html><head><meta charset='utf-8'><title>Pendências CPF</title></head><body>"]
    html.append(f"<h2>Pendências CPF ({len(rows)})</h2>")
    html.append("<table border='1' cellpadding='6' cellspacing='0'>")
    html.append("<tr><th>Nome</th><th>IPM</th><th>Telefone</th><th>Bairro</th><th>Motivo</th><th>Atualizado</th></tr>")
    for p in rows:
        html.append(f"<tr><td>{p.full_name}</td><td>{p.ipm}</td><td>{p.phone}</td><td>{p.bairro}</td><td>{p.pending_reason}</td><td>{p.updated_at}</td></tr>")
    html.append("</table></body></html>")
    return "".join(html)

@router.get("/conflicts", response_class=None)
def conflicts(db: Session = Depends(get_db), user=Depends(require_roles("supervisor","admin"))):
    rows = db.query(models.Conflict).order_by(models.Conflict.created_at.desc()).limit(500).all()
    html = ["<html><head><meta charset='utf-8'><title>Conflitos</title></head><body>"]
    html.append(f"<h2>Conflitos de Sincronização ({len(rows)})</h2>")
    html.append("<table border='1' cellpadding='6' cellspacing='0'>")
    html.append("<tr><th>Quando</th><th>Device</th><th>Usuário</th><th>Tipo</th><th>UUID</th><th>Motivo</th><th>ClientItem</th></tr>")
    for c in rows:
        html.append(f"<tr><td>{c.created_at}</td><td>{c.device_id}</td><td>{c.actor_email}</td><td>{c.entity_type}</td><td>{c.entity_uuid}</td><td>{c.reason}</td><td>{c.client_item_id}</td></tr>")
    html.append("</table></body></html>")
    return "".join(html)
