# InventoryOps Portal Lite (Factory Build Lite)

## Install
```bash
pip install fastapi uvicorn pytest
```

## Run
```bash
cd backend && python main.py
# Open http://localhost:8000
# Frontend: open frontend/index.html
```

## Test
```bash
pytest tests/ -v
# Tests follow CLASSIFICATION_FIRST policy
# SKIP_ENV tests require live server
```

## API Endpoints
| Method | Path | Description |
|--------|------|-------------|
| GET | /products | List (paginated, filtered, sorted) |
| POST | /products | Create product |
| DELETE | /products/{id} | Delete (blocked if stock>0) |
| GET | /suppliers | List suppliers |
| POST | /suppliers | Create supplier |
| GET | /stock-movements | Movement log |
| POST | /stock-movements | Record movement |
| GET | /orders | List orders |
| POST | /orders | Create order |

## Safety Features
- Delete-with-stock alert (blocked if quantity > 0)
- Sort parameter validation (SQL injection prevention)
- Input validation (empty name/SKU blocked)
- .env.example uses placeholder values only
- SQLite only — no external DB, no production endpoints

## Architecture
See `design/architecture.md` for entity design, API outline, page tree, and permission matrix.
