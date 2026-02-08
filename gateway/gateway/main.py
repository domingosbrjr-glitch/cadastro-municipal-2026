import os, json, sqlite3
from datetime import datetime
from fastapi import FastAPI, Request
import requests

UPSTREAM_URL = os.getenv("UPSTREAM_URL", "http://localhost:8000")
DB_PATH = os.getenv("GATEWAY_DB", "gateway_queue.sqlite3")

app = FastAPI(title="Cadastro Gateway Local", version="0.4.0")

def conn():
    c = sqlite3.connect(DB_PATH)
    c.execute("""
    CREATE TABLE IF NOT EXISTS queue(
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      created_at TEXT NOT NULL,
      path TEXT NOT NULL,
      headers TEXT NOT NULL,
      body BLOB NOT NULL,
      status TEXT NOT NULL DEFAULT 'pending',
      last_error TEXT NOT NULL DEFAULT ''
    )
    """)
    c.commit()
    return c

@app.get("/health")
def health():
    return {"ok": True, "upstream": UPSTREAM_URL}

def _store(path: str, headers: dict, body: bytes):
    c = conn()
    c.execute("INSERT INTO queue(created_at,path,headers,body,status) VALUES (?,?,?,?,?)",
              (datetime.utcnow().isoformat(), path, json.dumps(headers), body, "pending"))
    c.commit()
    c.close()

@app.post("/sync/push")
async def store_sync(req: Request):
    body = await req.body()
    headers = {k:v for k,v in req.headers.items() if k.lower() in ["authorization","content-type"]}
    _store("/sync/push", headers, body)
    return {"stored": True}

@app.post("/attachments/upload")
async def store_att(req: Request):
    body = await req.body()
    headers = {k:v for k,v in req.headers.items() if k.lower() in ["authorization","content-type"]}
    _store("/attachments/upload", headers, body)
    return {"stored": True}

@app.post("/flush")
def flush():
    c = conn()
    rows = c.execute("SELECT id,path,headers,body FROM queue WHERE status='pending' ORDER BY id ASC LIMIT 50").fetchall()
    sent = 0
    for qid, path, headers, body in rows:
        try:
            h = json.loads(headers)
            r = requests.post(UPSTREAM_URL + path, data=body, headers=h, timeout=15)
            if r.status_code < 300:
                c.execute("UPDATE queue SET status='sent', last_error='' WHERE id=?", (qid,))
                sent += 1
            else:
                c.execute("UPDATE queue SET last_error=? WHERE id=?", (f"http_{r.status_code}", qid))
        except Exception as e:
            c.execute("UPDATE queue SET last_error=? WHERE id=?", (type(e).__name__, qid))
    c.commit()
    c.close()
    return {"sent": sent, "checked": len(rows)}

@app.get("/queue")
def queue():
    c = conn()
    stats = {r[0]: r[1] for r in c.execute("SELECT status,COUNT(*) FROM queue GROUP BY status").fetchall()}
    last = [dict(id=r[0],created_at=r[1],path=r[2],status=r[3],last_error=r[4])
            for r in c.execute("SELECT id,created_at,path,status,last_error FROM queue ORDER BY id DESC LIMIT 20").fetchall()]
    c.close()
    return {"stats": stats, "last": last}
