from fastapi import FastAPI, Depends, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from sqlalchemy.orm import Session
from datetime import datetime
from .settings import settings
from .db import engine, Base, get_db
from . import models, schemas
from .auth import hash_password, verify_password, create_access_token, get_current_user
from .sync import router as sync_router
from .attachments import router as attachments_router
from .admin_pages import router as admin_router
from .admin_api import router as admin_api_router

app = FastAPI(title="Cadastro Municipal Offline API", version="0.4.0")
Base.metadata.create_all(bind=engine)

app.add_middleware(
    CORSMiddleware,
    allow_origins=settings.cors_list() or ["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

@app.get("/health")
def health():
    return {"ok": True, "ts": datetime.utcnow().isoformat()}

@app.post("/auth/register")
def register(payload: schemas.RegisterIn, db: Session = Depends(get_db)):
    existing = db.query(models.User).filter(models.User.email == payload.email).first()
    if existing:
        raise HTTPException(status_code=400, detail="Email already exists")
    u = models.User(email=payload.email, password_hash=hash_password(payload.password), role=payload.role)
    db.add(u)
    db.commit()
    return {"ok": True}

@app.post("/auth/login", response_model=schemas.Token)
def login(payload: schemas.LoginIn, db: Session = Depends(get_db)):
    user = db.query(models.User).filter(models.User.email == payload.email).first()
    if not user or not verify_password(payload.password, user.password_hash):
        raise HTTPException(status_code=401, detail="Invalid credentials")
    token = create_access_token(subject=user.email, role=user.role)
    return schemas.Token(access_token=token)

@app.get("/me")
def me(user=Depends(get_current_user)):
    return {"email": user.email, "role": user.role}

app.include_router(sync_router)
app.include_router(attachments_router)
app.include_router(admin_router)
app.include_router(admin_api_router)
