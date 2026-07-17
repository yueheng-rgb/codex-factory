# RUN-B: Factory Build Lite — InventoryOps Portal Lite
Build a full-stack InventoryOps Portal Lite using Factory Build Lite workflow (install → bootstrap → preflight → build → phase-close):
- CRUD for products (name, sku, quantity, location, status)
- Supplier management (name, contact, products supplied)
- Stock movements (in/out, quantity, reason, timestamp)
- Orders/requests (item, quantity, requester, status)
- REST API with pagination, filtering, sorting
- SQLite database (no external DB)
- Python FastAPI backend
- Simple HTML/JS admin dashboard frontend
- Unit tests (pytest)
- README with install + run
- .env.production.example (empty template)
- Alert when deleting items with stock > 0
Factory Build Lite is active with Security Gate, Package QA Gate, Context Space, and Test Repair Policy.
No real secrets, no deployment, no production DB.
