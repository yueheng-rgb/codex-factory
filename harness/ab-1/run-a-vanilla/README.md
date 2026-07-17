# InventoryOps Portal Lite

## Install
pip install fastapi uvicorn pytest

## Run
cd backend && python main.py

## Test
pytest tests/ -v

## API Endpoints
- GET /products?page=1&size=20&status=active&sort=name
- POST /products
- DELETE /products/{id}
- GET /suppliers
- POST /suppliers
- GET /stock-movements
- POST /stock-movements
- GET /orders
- POST /orders
