from pydantic import BaseModel
from typing import Optional, Any, Dict, List, Literal

class Token(BaseModel):
    access_token: str
    token_type: str = "bearer"

class RegisterIn(BaseModel):
    email: str
    password: str
    role: str = "admin"

class LoginIn(BaseModel):
    email: str
    password: str

SyncOp = Literal["create","update"]
EntityType = Literal["person","household"]

class SyncItem(BaseModel):
    client_item_id: str
    entity_type: EntityType
    entity_uuid: str
    op: SyncOp
    payload: Dict[str, Any]
    base_version: int = 0

class SyncPushIn(BaseModel):
    device_id: str
    items: List[SyncItem]

class SyncResult(BaseModel):
    client_item_id: str
    status: Literal["accepted","conflict","rejected"]
    server_version: Optional[int] = None
    reason: Optional[str] = None

class SyncPushOut(BaseModel):
    results: List[SyncResult]

class HouseholdOut(BaseModel):
    uuid: str
    territory: str = ""
    bairro: str = ""
    logradouro: str = ""
    numero: str = ""
    referencia: str = ""
    version: int = 1
    updated_at: str = ""

class PersonOut(BaseModel):
    uuid: str
    household_uuid: str
    cpf: str = ""
    ipm: str = ""
    pending_cpf: bool = False
    pending_reason: str = ""
    full_name: str = ""
    mother_name: str = ""
    birth_date: str = ""
    phone: str = ""
    bairro: str = ""
    referencia: str = ""
    general: Dict[str, Any] = {}
    assistance: Dict[str, Any] = {}
    version: int = 1
    updated_at: str = ""

class SyncPullOut(BaseModel):
    server_time: str
    households: List[HouseholdOut]
    people: List[PersonOut]
