"""
JPDC CRM API Server - FastAPI Backend
Jinxi Seaview City (金禧海景城) Sales Management
"""
from fastapi import FastAPI, HTTPException, Query, Header, Depends
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel
import sqlite3, os, hashlib, json
from typing import Optional
from datetime import datetime

DB_PATH = os.path.join(os.path.dirname(os.path.abspath(__file__)), "jpdc.db")

app = FastAPI(title="JPDC CRM API", version="2.0.0")

app.add_middleware(CORSMiddleware, allow_origins=["*"], allow_methods=["*"], allow_headers=["*"])

# ── DB Helpers ──────────────────────────────────────────────

def get_conn():
    conn = sqlite3.connect(DB_PATH)
    conn.row_factory = sqlite3.Row
    return conn

def row_to_dict(row):
    return dict(row) if row else {}

# ── Auth Models ─────────────────────────────────────────────

class LoginRequest(BaseModel):
    username: str
    password: str

def verify_user(username: str, password: str) -> dict | None:
    conn = get_conn()
    cur = conn.cursor()
    cur.execute("""SELECT u.*, r.name as role_name, r.can_view_all, r.can_edit, 
        r.can_manage_users, r.can_export, r.can_view_financial 
        FROM users u JOIN roles r ON u.role_id = r.id 
        WHERE u.username=? AND u.password_hash=? AND u.active=1""",
        (username, password))
    row = cur.fetchone()
    conn.close()
    
    if row:
        user = dict(row)
        cur2 = get_conn().cursor()
        cur2.execute("UPDATE users SET last_login=? WHERE id=?", (datetime.now().isoformat(), user['id']))
        cur2.connection.commit()
        cur2.connection.close()
        return user
    return None

def check_permission(username: str, permission: str) -> bool:
    conn = get_conn()
    cur = conn.cursor()
    cur.execute("""SELECT r.{0} FROM users u JOIN roles r ON u.role_id = r.id 
        WHERE u.username=? AND u.active=1""".format(permission), (username,))
    row = cur.fetchone()
    conn.close()
    return bool(row and row[0])

# ── Auth Endpoints ──────────────────────────────────────────

@app.post("/api/login")
def login(req: LoginRequest):
    user = verify_user(req.username, req.password)
    if not user:
        raise HTTPException(401, "Invalid credentials")
    token = hashlib.sha256(f"{req.username}:{datetime.now().isoformat()}:jpdc_secret".encode()).hexdigest()
    return {
        "success": True,
        "token": token,
        "user": {
            "username": user['username'],
            "display_name": user['display_name'],
            "role": user['role_name'],
            "permissions": {
                "can_edit": bool(user['can_edit']),
                "can_manage_users": bool(user['can_manage_users']),
                "can_export": bool(user['can_export']),
                "can_view_financial": bool(user['can_view_financial']),
            }
        }
    }

# ── Health ─────────────────────────────────────────────────

@app.get("/api/health")
def health():
    conn = get_conn()
    cur = conn.cursor()
    cur.execute("SELECT COUNT(*) FROM units")
    units = cur.fetchone()[0]
    cur.execute("SELECT value FROM sync_meta WHERE key='last_import'")
    last = cur.fetchone()
    conn.close()
    return {
        "status": "ok",
        "total_units": units,
        "last_sync": last[0] if last else None,
        "timestamp": datetime.now().isoformat()
    }

# ── Dashboard ───────────────────────────────────────────────

@app.get("/api/dashboard")
def dashboard():
    conn = get_conn()
    cur = conn.cursor()
    
    # Unit stats
    cur.execute("SELECT status, COUNT(*) FROM units WHERE status != '' GROUP BY status")
    by_status = {row[0]: row[1] for row in cur.fetchall()}
    
    cur.execute("SELECT tower, COUNT(*) FROM units GROUP BY tower")
    by_tower = {row[0]: row[1] for row in cur.fetchall()}
    
    cur.execute("SELECT unit_type, COUNT(*) FROM units WHERE unit_type != '' GROUP BY unit_type")
    by_type = {row[0]: row[1] for row in cur.fetchall()}
    
    total = sum(by_tower.values())
    sold = by_status.get('已售', 0) + by_status.get('Sold', 0) + by_status.get('已售(LATE)', 0)
    available = by_status.get('可售', 0) + by_status.get('Available', 0)
    
    # Overdue
    cur.execute("SELECT COUNT(*), SUM(total_paid) FROM overdue_warnings")
    overdue = cur.fetchone()
    
    # Returned
    cur.execute("SELECT COUNT(*) FROM returned_units")
    returned = cur.fetchone()[0]
    
    # Tower detail: available + sold per tower
    tower_detail = {}
    for t in ['A', 'E']:
        cur.execute("SELECT COUNT(*) FROM units WHERE tower=? AND status IN ('可售','可售 (NEW)')", (t,))
        avail = cur.fetchone()[0]
        cur.execute("SELECT COUNT(*) FROM units WHERE tower=? AND status IN ('已售','Sold','已售(LATE)')", (t,))
        sold_t = cur.fetchone()[0]
        tower_detail[t] = {"available": avail, "sold": sold_t, "total": by_tower.get(t, 0)}

    # Problem
    cur.execute("SELECT COUNT(*) FROM problem_units")
    problem = cur.fetchone()[0]
    
    conn.close()
    
    return {
        "total_units": total,
        "sold": sold,
        "available": available,
        "sold_rate": round(sold/total*100, 1) if total else 0,
        "by_tower": by_tower,
        "by_type": by_type,
        "by_status": by_status,
        "by_tower_detail": tower_detail,
        "overdue_count": overdue[0],
        "overdue_amount": overdue[1] or 0,
        "returned_count": returned,
        "problem_count": problem,
    }

# ── Units ───────────────────────────────────────────────────

@app.get("/api/units")
def list_units(
    tower: Optional[str] = None,
    status: Optional[str] = None,
    unit_type: Optional[str] = None,
    search: Optional[str] = None,
    page: int = 1,
    limit: int = 50,
):
    conn = get_conn()
    cur = conn.cursor()
    
    conditions = []
    params = []
    
    if tower:
        conditions.append("tower = ?")
        params.append(tower)
    if status:
        conditions.append("status = ?")
        params.append(status)
    if unit_type:
        conditions.append("unit_type = ?")
        params.append(unit_type)
    if search:
        conditions.append("(unit_no LIKE ? OR floor_num LIKE ?)")
        params.extend([f"%{search}%", f"%{search}%"])
    
    where = "WHERE " + " AND ".join(conditions) if conditions else ""
    
    cur.execute(f"SELECT COUNT(*) FROM units {where}", params)
    total = cur.fetchone()[0]
    
    offset = (page - 1) * limit
    cur.execute(f"SELECT * FROM units {where} ORDER BY tower, floor_num, unit_no LIMIT ? OFFSET ?",
        params + [limit, offset])
    rows = [dict(r) for r in cur.fetchall()]
    conn.close()
    
    return {"total": total, "page": page, "limit": limit, "data": rows}

@app.get("/api/units/{unit_id}")
def get_unit(unit_id: int):
    conn = get_conn()
    cur = conn.cursor()
    cur.execute("SELECT * FROM units WHERE id=?", (unit_id,))
    row = cur.fetchone()
    conn.close()
    if not row:
        raise HTTPException(404, "Unit not found")
    return dict(row)

# ── Unit Status Summary by Type ─────────────────────────────

@app.get("/api/units/inventory")
def inventory(tower: Optional[str] = None):
    conn = get_conn()
    cur = conn.cursor()
    
    if tower:
        cur.execute("""SELECT unit_type, status, COUNT(*) as cnt 
            FROM units WHERE tower=? AND unit_type != '' AND status != ''
            GROUP BY unit_type, status""", (tower,))
    else:
        cur.execute("""SELECT unit_type, status, COUNT(*) as cnt 
            FROM units WHERE unit_type != '' AND status != ''
            GROUP BY unit_type, status""")
    
    rows = cur.fetchall()
    conn.close()
    
    result = {}
    for r in rows:
        utype = r[0]
        if utype not in result:
            result[utype] = {"type": utype, "total": 0, "statuses": {}}
        result[utype]["statuses"][r[1]] = r[2]
        result[utype]["total"] += r[2]
    
    return list(result.values())

# ── Overdue Warnings ────────────────────────────────────────

@app.get("/api/overdue")
def list_overdue(risk: Optional[str] = None):
    conn = get_conn()
    cur = conn.cursor()
    if risk:
        cur.execute("SELECT * FROM overdue_warnings WHERE risk_level LIKE ? ORDER BY days_stopped DESC", (f"%{risk}%",))
    else:
        cur.execute("SELECT * FROM overdue_warnings ORDER BY days_stopped DESC")
    rows = [dict(r) for r in cur.fetchall()]
    conn.close()
    return rows

# ── Sold Clients ────────────────────────────────────────────

@app.get("/api/sold")
def list_sold(tower: Optional[str] = None):
    conn = get_conn()
    cur = conn.cursor()
    if tower:
        cur.execute("SELECT * FROM sold_clients WHERE tower=? ORDER BY floor_num, unit_no", (tower,))
    else:
        cur.execute("SELECT * FROM sold_clients ORDER BY tower, floor_num, unit_no")
    rows = [dict(r) for r in cur.fetchall()]
    conn.close()
    return rows

# ── Payment Details ─────────────────────────────────────────

@app.get("/api/payments")
def list_payments(buyer: Optional[str] = None):
    conn = get_conn()
    cur = conn.cursor()
    if buyer:
        cur.execute("SELECT * FROM payment_details WHERE buyer_name LIKE ? ORDER BY tower, unit_no", (f"%{buyer}%",))
    else:
        cur.execute("SELECT * FROM payment_details ORDER BY tower, unit_no")
    rows = [dict(r) for r in cur.fetchall()]
    conn.close()
    return rows

@app.get("/api/payments/summary")
def payment_summary():
    conn = get_conn()
    cur = conn.cursor()
    cur.execute("SELECT COUNT(*) as total_clients, SUM(tr1_amount)+SUM(tr2_amount)+SUM(tr3_amount)+SUM(tr4_amount)+SUM(tr5_amount)+SUM(tr6_amount)+SUM(tr7_amount)+SUM(tr8_amount) as total_collected FROM payment_details")
    row = cur.fetchone()
    conn.close()
    return dict(row)

# ── Returned Units ──────────────────────────────────────────

@app.get("/api/returned")
def list_returned():
    conn = get_conn()
    cur = conn.cursor()
    cur.execute("SELECT * FROM returned_units ORDER BY tower, floor_num")
    rows = [dict(r) for r in cur.fetchall()]
    conn.close()
    return rows

# ── Problem Units ───────────────────────────────────────────

@app.get("/api/problems")
def list_problems():
    conn = get_conn()
    cur = conn.cursor()
    cur.execute("SELECT * FROM problem_units ORDER BY tower, floor_num")
    rows = [dict(r) for r in cur.fetchall()]
    conn.close()
    return rows

# ── Management ──────────────────────────────────────────────

@app.get("/api/users")
def list_users():
    conn = get_conn()
    cur = conn.cursor()
    cur.execute("""SELECT u.id, u.username, u.display_name, u.role_id, r.name as role_name, u.active, u.last_login 
        FROM users u JOIN roles r ON u.role_id = r.id ORDER BY u.id""")
    rows = [dict(r) for r in cur.fetchall()]
    conn.close()
    return rows

@app.get("/api/roles")
def list_roles():
    conn = get_conn()
    cur = conn.cursor()
    cur.execute("SELECT * FROM roles")
    rows = [dict(r) for r in cur.fetchall()]
    conn.close()
    return rows

# ── Run ─────────────────────────────────────────────────────

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8001)
