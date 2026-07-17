"""InventoryOps Portal Lite — Vanilla Codex RUN-A"""
from fastapi import FastAPI, Query, HTTPException
from pydantic import BaseModel
from typing import Optional
import sqlite3, os

app = FastAPI(title="InventoryOps Portal Lite")
DB = "inventory.db"

def get_db():
    conn = sqlite3.connect(DB)
    conn.row_factory = sqlite3.Row
    return conn

def init_db():
    conn = get_db()
    conn.executescript("""
        CREATE TABLE IF NOT EXISTS products (id INTEGER PRIMARY KEY, name TEXT, sku TEXT UNIQUE, quantity INTEGER DEFAULT 0, location TEXT, status TEXT DEFAULT 'active');
        CREATE TABLE IF NOT EXISTS suppliers (id INTEGER PRIMARY KEY, name TEXT, contact TEXT);
        CREATE TABLE IF NOT EXISTS stock_movements (id INTEGER PRIMARY KEY, product_id INTEGER, direction TEXT, quantity INTEGER, reason TEXT, timestamp DATETIME DEFAULT CURRENT_TIMESTAMP);
        CREATE TABLE IF NOT EXISTS orders (id INTEGER PRIMARY KEY, product_id INTEGER, quantity INTEGER, requester TEXT, status TEXT DEFAULT 'pending');
    """)
    conn.commit(); conn.close()

init_db()

class Product(BaseModel): name: str; sku: str; quantity: int = 0; location: str = ""; status: str = "active"
class Supplier(BaseModel): name: str; contact: str = ""
class StockMovement(BaseModel): product_id: int; direction: str; quantity: int; reason: str = ""
class Order(BaseModel): product_id: int; quantity: int; requester: str; status: str = "pending"

@app.get("/products")
def list_products(page: int=1, size: int=20, status: Optional[str]=None, location: Optional[str]=None, sort: str="name"):
    conn=get_db(); q="SELECT * FROM products WHERE 1=1"; params=[]
    if status: q+=" AND status=?"; params.append(status)
    if location: q+=" AND location=?"; params.append(location)
    q+=f" ORDER BY {sort} LIMIT ? OFFSET ?"; params+=[size,(page-1)*size]
    rows=conn.execute(q,params).fetchall(); conn.close()
    return [dict(r) for r in rows]

@app.post("/products")
def create_product(p: Product):
    conn=get_db();
    try: conn.execute("INSERT INTO products(name,sku,quantity,location,status) VALUES(?,?,?,?,?)",[p.name,p.sku,p.quantity,p.location,p.status]); conn.commit(); pid=conn.execute("SELECT last_insert_rowid()").fetchone()[0]; conn.close(); return {"id":pid}
    except sqlite3.IntegrityError: conn.close(); raise HTTPException(400,"SKU already exists")

@app.delete("/products/{pid}")
def delete_product(pid: int):
    conn=get_db(); p=conn.execute("SELECT quantity FROM products WHERE id=?",[pid]).fetchone()
    if not p: conn.close(); raise HTTPException(404)
    if p["quantity"]>0: conn.close(); raise HTTPException(400,f"Cannot delete: stock={p['quantity']}>0")
    conn.execute("DELETE FROM products WHERE id=?",[pid]); conn.commit(); conn.close(); return {"deleted":pid}

@app.get("/suppliers"); def list_suppliers(): conn=get_db(); rows=conn.execute("SELECT * FROM suppliers").fetchall(); conn.close(); return [dict(r) for r in rows]
@app.post("/suppliers"); def create_supplier(s: Supplier): conn=get_db(); conn.execute("INSERT INTO suppliers(name,contact) VALUES(?,?)",[s.name,s.contact]); conn.commit(); pid=conn.execute("SELECT last_insert_rowid()").fetchone()[0]; conn.close(); return {"id":pid}

@app.get("/stock-movements"); def list_movements(): conn=get_db(); rows=conn.execute("SELECT * FROM stock_movements ORDER BY timestamp DESC LIMIT 50").fetchall(); conn.close(); return [dict(r) for r in rows]
@app.post("/stock-movements"); def create_movement(m: StockMovement): conn=get_db(); conn.execute("INSERT INTO stock_movements(product_id,direction,quantity,reason) VALUES(?,?,?,?)",[m.product_id,m.direction,m.quantity,m.reason]); conn.execute("UPDATE products SET quantity=quantity+? WHERE id=?",[m.quantity if m.direction=='in' else -m.quantity,m.product_id]); conn.commit(); conn.close(); return {"ok":True}

@app.get("/orders"); def list_orders(): conn=get_db(); rows=conn.execute("SELECT * FROM orders ORDER BY id DESC LIMIT 50").fetchall(); conn.close(); return [dict(r) for r in rows]
@app.post("/orders"); def create_order(o: Order): conn=get_db(); conn.execute("INSERT INTO orders(product_id,quantity,requester,status) VALUES(?,?,?,?)",[o.product_id,o.quantity,o.requester,o.status]); conn.commit(); pid=conn.execute("SELECT last_insert_rowid()").fetchone()[0]; conn.close(); return {"id":pid}

if __name__=="__main__": import uvicorn; uvicorn.run(app,host="0.0.0.0",port=8000)
