"""Tests for InventoryOps Portal Lite — CLASSIFICATION_FIRST policy"""
import pytest; from fastapi.testclient import TestClient; from backend.main import app
client=TestClient(app)
# CLASSIFICATION: unit — tests API behavior with test client
def test_list_products(): r=client.get("/products"); assert r.status_code==200; assert isinstance(r.json(),list)
def test_create_product(): r=client.post("/products",json={"name":"Widget A","sku":"WGT-001","quantity":50,"location":"WH-1"}); assert r.status_code==200; assert "id" in r.json()
def test_duplicate_sku_blocked(): client.post("/products",json={"name":"Dup1","sku":"DUP-X","quantity":5}); r=client.post("/products",json={"name":"Dup2","sku":"DUP-X","quantity":3}); assert r.status_code==400
def test_delete_with_stock_blocked(): r=client.post("/products",json={"name":"Stocked","sku":"STK-A","quantity":100}); pid=r.json()["id"]; r2=client.delete(f"/products/{pid}"); assert r2.status_code==400; assert "SAFETY BLOCK" in r2.json()["detail"]
def test_delete_zero_stock_allowed(): r=client.post("/products",json={"name":"Empty","sku":"EMP-A","quantity":0}); pid=r.json()["id"]; r2=client.delete(f"/products/{pid}"); assert r2.status_code==200
def test_sort_validation(): r=client.get("/products?sort=invalid"); assert r.status_code==400
def test_empty_name_blocked(): r=client.post("/products",json={"name":"  ","sku":"BAD-01"}); assert r.status_code==400
def test_create_supplier(): r=client.post("/suppliers",json={"name":"Acme Corp","contact":"acme@test.com"}); assert r.status_code==200
def test_create_order(): r=client.post("/products",json={"name":"OrdItem","sku":"ORD-01","quantity":20}); pid=r.json()["id"]; r2=client.post("/orders",json={"product_id":pid,"quantity":5,"requester":"user1"}); assert r2.status_code==200
def test_stock_movement_updates_quantity(): r=client.post("/products",json={"name":"Movable","sku":"MOV-01","quantity":10}); pid=r.json()["id"]; client.post("/stock-movements",json={"product_id":pid,"direction":"out","quantity":3,"reason":"test"}); r3=client.get("/products"); found=[p for p in r3.json() if p["id"]==pid]; assert found[0]["quantity"]==7

# CLASSIFICATION: SKIP_ENV — requires live server (skipped in CI)
@pytest.mark.skip(reason="ENV_MISMATCH: requires live uvicorn server")
def test_live_server_smoke(): import requests; r=requests.get("http://localhost:8000/products"); assert r.status_code==200
