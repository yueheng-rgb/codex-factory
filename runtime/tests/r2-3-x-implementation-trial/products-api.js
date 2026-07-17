// === Products API v2.0 (R2.9 Stabilization) ===
// Routes unified under /api/products
// Legacy /products alias preserved with redirect note
// Added: PATCH /api/products/:id, unified error format, 14+ tests
// Implementer: project files + existing patterns only. No direct search.

const fastify = require("fastify")({ logger: false, ajv: { customOptions: { removeAdditional: false } } });
const path = require("path");
const Database = require("better-sqlite3");

const DB_PATH = path.join(__dirname, "r2-5-products.db");
const db = new Database(DB_PATH);

// --- Error helper (R2.9: unified format) ---
function errorReply(reply, code, message, details = null) {
  const body = { error: { code, message } };
  if (details) body.error.details = details;
  return reply.status(code).send(body);
}

// --- Unified error handler (R2.9 Contract Finalization) ---
fastify.setErrorHandler((error, request, reply) => {
  // Fastify schema validation errors ¡ú unified format
  if (error.validation) {
    const ctx = error.validationContext || "body";
    const details = error.validation.map(v => ({ path: v.instancePath || `/${ctx}`, message: v.message, keyword: v.keyword }));
    return reply.status(400).send({ error: { code: 400, message: error.message, details } });
  }
  // Already in unified format or pass-through
  if (error.statusCode) {
    return reply.status(error.statusCode).send({ error: { code: error.statusCode, message: error.message } });
  }
  // Fallback
  return reply.status(500).send({ error: { code: 500, message: "Internal server error" } });
});

// --- Schema + Seed ---
db.exec(`
  CREATE TABLE IF NOT EXISTS products (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    name TEXT NOT NULL,
    description TEXT DEFAULT '',
    category TEXT NOT NULL,
    price REAL NOT NULL,
    status TEXT DEFAULT 'active',
    created_at TEXT DEFAULT (datetime('now')),
    updated_at TEXT DEFAULT (datetime('now'))
  );
`);


// Migration: add updated_at if missing (R2.9)
try { db.exec("ALTER TABLE products ADD COLUMN updated_at TEXT DEFAULT (datetime('now'))"); } catch (e) { /* column exists */ }

const count = db.prepare("SELECT COUNT(*) as c FROM products").get();
if (count.c === 0) {
  const cats = ["electronics", "clothing", "books", "home", "sports"];
  const insert = db.prepare("INSERT INTO products (name, description, category, price, status) VALUES (?,?,?,?,?)");
  const tx = db.transaction(() => {
    for (let i = 0; i < 50; i++) {
      const cat = cats[i % cats.length];
      insert.run(`Product ${i + 1}`, `Description for product ${i + 1} in ${cat} category`, cat, Math.round((10 + Math.random() * 200) * 100) / 100, i % 7 === 0 ? "inactive" : "active");
    }
  });
  tx();
}

// --- Constants ---
const ALLOWED_FILTERS = ["category", "status"];
const ALLOWED_SORT = ["id", "name", "price", "created_at", "updated_at"];
const ALLOWED_FIELDS = ["name", "description", "category", "price", "status"];
const REQUIRED_FIELDS = ["name", "category", "price"];
const VALID_TRANSITIONS = { active: ["inactive", "archived"], inactive: ["active", "archived"], archived: [] };

function decodeCursor(cursor) {
  try { return JSON.parse(Buffer.from(cursor, "base64").toString("utf8")); }
  catch { return null; }
}
function encodeCursor(item, sortField) {
  return Buffer.from(JSON.stringify({ id: item.id, [sortField]: item[sortField] })).toString("base64");
}

async function start() {
  // ===== R2.5: GET /api/products (list) =====
  fastify.get("/api/products", {
    schema: {
      querystring: {
        type: "object",
        properties: {
          cursor: { type: "string" }, limit: { type: "integer", minimum: 1, maximum: 100, default: 20 },
          sort: { type: "string", enum: ALLOWED_SORT, default: "id" },
          order: { type: "string", enum: ["asc", "desc"], default: "asc" },
          search: { type: "string", maxLength: 100 },
          category: { type: "string" }, status: { type: "string" },
        },
      },
    },
    handler: async (request, reply) => {
      const { cursor, limit = 20, sort = "id", order = "asc", search, category, status } = request.query;
      let where = []; let params = [];

      if (cursor) {
        const decoded = decodeCursor(cursor);
        if (!decoded) return errorReply(reply, 400, "Invalid cursor", { cursor });
        const op = order === "asc" ? ">" : "<";
        where.push(`(${sort}, id) ${op} (?, ?)`);
        params.push(decoded[sort] || decoded.id, decoded.id);
      }
      if (category) { where.push("category = ?"); params.push(category); }
      if (status) { where.push("status = ?"); params.push(status); }
      if (search) { where.push("(name LIKE ? OR description LIKE ?)"); params.push(`%${search}%`, `%${search}%`); }

      const whereClause = where.length ? "WHERE " + where.join(" AND ") : "";
      const orderClause = `ORDER BY ${sort} ${order}, id ${order}`;

      const rows = db.prepare(`SELECT * FROM products ${whereClause} ${orderClause} LIMIT ?`).all(...params, limit + 1);
      const hasMore = rows.length > limit;
      const data = rows.slice(0, limit);
      const total = db.prepare(`SELECT COUNT(*) as total FROM products ${whereClause}`).get(...params).total;

      return { data, pagination: { nextCursor: hasMore ? encodeCursor(data[data.length - 1], sort) : null, hasMore, total }, filters: { applied: { category: category || null, status: status || null }, search: search || null } };
    },
  });

  // ===== R2.7 F1: GET /api/products/:id =====
  fastify.get("/api/products/:id", {
    schema: { params: { type: "object", required: ["id"], properties: { id: { type: "integer", minimum: 1 } } } },
    handler: async (request, reply) => {
      const product = db.prepare("SELECT * FROM products WHERE id = ?").get(request.params.id);
      if (!product) return errorReply(reply, 404, "Product not found", { id: request.params.id });
      return { data: product };
    },
  });

  // ===== R2.7 F2: POST /api/products =====
  fastify.post("/api/products", {
    schema: {
      body: {
        type: "object", required: REQUIRED_FIELDS,
        properties: {
          name: { type: "string", minLength: 1, maxLength: 200 },
          description: { type: "string", maxLength: 2000, default: "" },
          category: { type: "string", minLength: 1, maxLength: 100 },
          price: { type: "number", minimum: 0, maximum: 999999.99 },
          status: { type: "string", enum: ["active", "inactive"], default: "active" },
        },
        additionalProperties: false,
      },
    },
    handler: async (request, reply) => {
      const body = request.body;
      const fields = []; const values = []; const placeholders = [];
      for (const key of ALLOWED_FIELDS) {
        if (body[key] !== undefined) { fields.push(key); values.push(body[key]); placeholders.push("?"); }
      }
      const result = db.prepare(`INSERT INTO products (${fields.join(", ")}) VALUES (${placeholders.join(", ")})`).run(...values);
      const product = db.prepare("SELECT * FROM products WHERE id = ?").get(result.lastInsertRowid);
      return reply.status(201).send({ data: product });
    },
  });

  // ===== R2.9: PATCH /api/products/:id (update) =====
  // Design: follows POST validation pattern (field whitelist, type check, unknown field rejection).
  // Escalation: no search ¡ª existing validation pattern applied to new endpoint. No new API contract.
  fastify.patch("/api/products/:id", {
    schema: {
      params: { type: "object", required: ["id"], properties: { id: { type: "integer", minimum: 1 } } },
      body: {
        type: "object", minProperties: 1,
        properties: {
          name: { type: "string", minLength: 1, maxLength: 200 },
          description: { type: "string", maxLength: 2000 },
          category: { type: "string", minLength: 1, maxLength: 100 },
          price: { type: "number", minimum: 0, maximum: 999999.99 },
          status: { type: "string", enum: ["active", "inactive"] },
        },
        additionalProperties: false,
      },
    },
    handler: async (request, reply) => {
      const { id } = request.params;
      const product = db.prepare("SELECT * FROM products WHERE id = ?").get(id);
      if (!product) return errorReply(reply, 404, "Product not found", { id });

      // Archived products cannot be updated (design decision: terminal state)
      if (product.status === "archived") {
        return errorReply(reply, 409, "Cannot update archived product", { id, currentStatus: "archived" });
      }

      const body = request.body;
      const sets = []; const values = [];
      for (const key of ALLOWED_FIELDS) {
        if (body[key] !== undefined) { sets.push(`${key} = ?`); values.push(body[key]); }
      }
      if (sets.length === 0) return errorReply(reply, 400, "No valid fields to update");

      sets.push("updated_at = datetime('now')");
      values.push(id);
      db.prepare(`UPDATE products SET ${sets.join(", ")} WHERE id = ?`).run(...values);

      const updated = db.prepare("SELECT * FROM products WHERE id = ?").get(id);
      return { data: updated };
    },
  });

  // ===== R2.7 F3: PATCH /api/products/:id/status =====
  fastify.patch("/api/products/:id/status", {
    schema: {
      params: { type: "object", required: ["id"], properties: { id: { type: "integer", minimum: 1 } } },
      body: { type: "object", required: ["status"], properties: { status: { type: "string", enum: ["active", "inactive", "archived"] } }, additionalProperties: false },
    },
    handler: async (request, reply) => {
      const { id } = request.params;
      const { status: newStatus } = request.body;
      const product = db.prepare("SELECT * FROM products WHERE id = ?").get(id);
      if (!product) return errorReply(reply, 404, "Product not found", { id });

      const allowed = VALID_TRANSITIONS[product.status] || [];
      if (!allowed.includes(newStatus)) {
        return errorReply(reply, 409, "Invalid status transition", { current: product.status, requested: newStatus, allowedTransitions: allowed });
      }

      db.prepare("UPDATE products SET status = ?, updated_at = datetime('now') WHERE id = ?").run(newStatus, id);
      const updated = db.prepare("SELECT * FROM products WHERE id = ?").get(id);
      return { data: updated };
    },
  });

  // ===== R2.9: Legacy alias (redirect note) =====
  fastify.get("/products/:id", async (request, reply) => {
    return reply.redirect(301, `/api/products/${request.params.id}`);
  });
  fastify.post("/products", async (request, reply) => {
    return reply.redirect(307, "/api/products");
  });
  fastify.patch("/products/:id", async (request, reply) => {
    return reply.redirect(307, `/api/products/${request.params.id}`);
  });
  fastify.patch("/products/:id/status", async (request, reply) => {
    return reply.redirect(307, `/api/products/${request.params.id}/status`);
  });

  // ===== HEALTH =====
  fastify.get("/health", async () => ({ status: "ok", products: db.prepare("SELECT COUNT(*) as c FROM products").get().c }));

  await fastify.listen({ port: 3400 });
  console.log("Products API v2.0 on port 3400");
}

start().catch((err) => { console.error(err.message); process.exit(1); });

