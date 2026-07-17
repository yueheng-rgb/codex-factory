# InventoryOps Portal Lite — Architecture Design
## Entity Design
- Product (id, name, sku, quantity, location, status)
- Supplier (id, name, contact)
- StockMovement (id, product_id, direction, quantity, reason, timestamp)
- Order (id, product_id, quantity, requester, status)

## API Outline
- GET    /products           — list with pagination/filter/sort
- POST   /products           — create
- DELETE /products/{id}      — delete (block if stock>0)
- GET    /suppliers          — list
- POST   /suppliers          — create
- GET    /stock-movements    — list
- POST   /stock-movements    — create (updates product stock)
- GET    /orders             — list
- POST   /orders             — create

## Page Tree
- Dashboard (product table, low stock alerts)
- Suppliers (list + add)
- Orders (list + add)
- Stock Movements (log)

## Permission Matrix
- Admin: full CRUD
- Operator: view + update quantity
- Viewer: read-only
