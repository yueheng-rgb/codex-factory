"""Tests for InventoryOps Portal Lite"""
import pytest; from fastapi.testclient import TestClient; from backend.main import app
client=TestClient(app)
def test_list_products(): r=client.get("/products"); assert r.status_code==200
def test_create_product(): r=client.post("/products",json={"name":"Test","sku":"TST-001","quantity":10,"location":"WH-A"}); assert r.status_code==200
def test_duplicate_sku(): client.post("/products",json={"name":"Dup","sku":"DUP-001","quantity":5}); r=client.post("/products",json={"name":"Dup2","sku":"DUP-001","quantity":3}); assert r.status_code==400
def test_delete_with_stock(): r=client.post("/products",json={"name":"Stocked","sku":"STK-001","quantity":100}); pid=r.json()["id"]; r2=client.delete(f"/products/{pid}"); assert r2.status_code==400
def test_delete_zero_stock(): r=client.post("/products",json={"name":"Empty","sku":"EMP-001","quantity":0}); pid=r.json()["id"]; r2=client.delete(f"/products/{pid}"); assert r2.status_code==200
def test_suppliers(): r=client.get("/suppliers"); assert r.status_code==200
def test_orders(): r=client.get("/orders"); assert r.status_code==200
