// === R2.9 Products API Regression Tests (15 tests) ===
const BASE = "http://localhost:3400";
let passed = 0; let failed = 0;
const results = [];

async function test(name, fn) {
  try {
    await fn();
    passed++; results.push({ name, status: "PASS" });
    console.log(`  PASS: ${name}`);
  } catch (e) {
    failed++; results.push({ name, status: "FAIL", error: e.message });
    console.log(`  FAIL: ${name} — ${e.message}`);
  }
}

function assert(cond, msg) { if (!cond) throw new Error(msg || "assertion failed"); }

async function run() {
  console.log("=== R2.9 Products API Regression (15 tests) ===\n");

  let createdId, inactiveId;

  // T1: List products
  await test("T1: GET /api/products returns list with pagination", async () => {
    const r = await fetch(`${BASE}/api/products?limit=5`);
    assert(r.status === 200, `status ${r.status}`);
    const j = await r.json();
    assert(Array.isArray(j.data), "data is array");
    assert(j.data.length <= 5, `data length ${j.data.length}`);
    assert(typeof j.pagination.total === "number", "total missing");
    assert(j.pagination.total >= 50, `total ${j.pagination.total} < 50`);
  });

  // T2: Filter by category
  await test("T2: GET /api/products?category=electronics filters correctly", async () => {
    const r = await fetch(`${BASE}/api/products?category=electronics`);
    assert(r.status === 200, `status ${r.status}`);
    const j = await r.json();
    assert(j.data.length > 0, "no electronics found");
    assert(j.data.every(p => p.category === "electronics"), "non-electronics in results");
    assert(j.filters.applied.category === "electronics", "filter metadata wrong");
  });

  // T3: Detail success
  await test("T3: GET /api/products/:id returns product detail", async () => {
    const list = await (await fetch(`${BASE}/api/products?limit=1`)).json();
    const id = list.data[0].id;
    const r = await fetch(`${BASE}/api/products/${id}`);
    assert(r.status === 200, `status ${r.status}`);
    const j = await r.json();
    assert(j.data.id === id, "wrong product");
    assert(j.data.name, "name missing");
    assert(typeof j.data.price === "number", "price not number");
  });

  // T4: Detail 404
  await test("T4: GET /api/products/99999 returns 404", async () => {
    const r = await fetch(`${BASE}/api/products/99999`);
    assert(r.status === 404, `status ${r.status}`);
    const j = await r.json();
    assert(j.error, "no error body");
    assert(j.error.code === 404, `error code ${j.error.code}`);
  });

  // T5: Create success
  await test("T5: POST /api/products creates product", async () => {
    const r = await fetch(`${BASE}/api/products`, {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({ name: "R2.9 Test Product", category: "electronics", price: 99.99 }),
    });
    assert(r.status === 201, `status ${r.status}`);
    const j = await r.json();
    assert(j.data.id, "no id");
    assert(j.data.name === "R2.9 Test Product", "name mismatch");
    assert(j.data.status === "active", "default status not active");
    createdId = j.data.id;
  });

  // T6: Missing fields rejected
  await test("T6: POST /api/products missing required fields returns 400", async () => {
    const r = await fetch(`${BASE}/api/products`, {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({ name: "No Category" }),
    });
    assert(r.status === 400, `status ${r.status}`);
  });

  // T7: Unknown fields (Fastify strips by default with additionalProperties:false)
  await test("T7: POST /api/products unknown fields stripped (Fastify default)", async () => {
    const r = await fetch(`${BASE}/api/products`, {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({ name: "Extra Field Test", category: "books", price: 29.99, bogus: "should-be-removed" }),
    });
    assert(r.status === 201, `status ${r.status}`);
    const j = await r.json();
    assert(!j.data.bogus, "unknown field not stripped");
    assert(j.data.name === "Extra Field Test", "name mismatch");
  });

  // T8: Update success + updated_at
  await test("T8: PATCH /api/products/:id updates product and sets updated_at", async () => {
    const r = await fetch(`${BASE}/api/products/${createdId}`, {
      method: "PATCH",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({ name: "R2.9 Updated Product", price: 149.99 }),
    });
    assert(r.status === 200, `status ${r.status}`);
    const j = await r.json();
    assert(j.data.name === "R2.9 Updated Product", "name not updated");
    assert(j.data.price === 149.99, "price not updated");
    assert(j.data.updated_at, "updated_at missing");
    console.log(`      updated_at: ${j.data.updated_at}`);
  });

  // T9: Update unknown field rejected
  await test("T9: PATCH /api/products/:id unknown field rejected", async () => {
    const r = await fetch(`${BASE}/api/products/${createdId}`, {
      method: "PATCH",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({ hacker_field: "evil" }),
    });
    // Fastify strips unknown with additionalProperties:false, so body becomes empty
    // Then minProperties:1 catches it → 400
    assert(r.status === 400, `status ${r.status}`);
  });

  // T10: Update 404
  await test("T10: PATCH /api/products/99999 returns 404", async () => {
    const r = await fetch(`${BASE}/api/products/99999`, {
      method: "PATCH",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({ name: "nope" }),
    });
    assert(r.status === 404, `status ${r.status}`);
    const j = await r.json();
    assert(j.error, "no error body");
  });

  // T11: Status active → inactive
  await test("T11: PATCH /api/products/:id/status active→inactive works", async () => {
    const r = await fetch(`${BASE}/api/products/${createdId}/status`, {
      method: "PATCH",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({ status: "inactive" }),
    });
    assert(r.status === 200, `status ${r.status}`);
    const j = await r.json();
    assert(j.data.status === "inactive", `status is ${j.data.status}`);
    inactiveId = createdId;
  });

  // T12: Status inactive → archived
  await test("T12: PATCH /api/products/:id/status inactive→archived works", async () => {
    const r = await fetch(`${BASE}/api/products/${inactiveId}/status`, {
      method: "PATCH",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({ status: "archived" }),
    });
    assert(r.status === 200, `status ${r.status}`);
    const j = await r.json();
    assert(j.data.status === "archived", `status is ${j.data.status}`);
  });

  // T13: Status archived → active blocked
  await test("T13: PATCH /api/products/:id/status archived→active blocked (409)", async () => {
    const r = await fetch(`${BASE}/api/products/${inactiveId}/status`, {
      method: "PATCH",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({ status: "active" }),
    });
    assert(r.status === 409, `status ${r.status}`);
    const j = await r.json();
    assert(j.error, "no error body");
    assert(j.error.code === 409, `error code ${j.error.code}`);
  });

  // T14: Archived product update blocked
  await test("T14: PATCH /api/products/:id archived product update blocked (409)", async () => {
    const r = await fetch(`${BASE}/api/products/${inactiveId}`, {
      method: "PATCH",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({ name: "Should Fail" }),
    });
    assert(r.status === 409, `status ${r.status}`);
    const j = await r.json();
    assert(j.error.code === 409, `error code ${j.error.code}`);
  });

  // T15: Health check
  await test("T15: GET /health returns ok with product count", async () => {
    const r = await fetch(`${BASE}/health`);
    assert(r.status === 200, `status ${r.status}`);
    const j = await r.json();
    assert(j.status === "ok", "status not ok");
    assert(j.products >= 52, `products ${j.products} < 52`); // 50 seed + 2 created
  });

  console.log(`\n=== RESULTS: ${passed}/${passed + failed} PASS ===`);
  results.forEach(r => console.log(`  ${r.status === "PASS" ? "[PASS]" : "[FAIL]"} ${r.name}${r.error ? " — " + r.error : ""}`));

  if (failed > 0) process.exit(1);
}

run().catch(e => { console.error("TEST RUNNER ERROR:", e.message); process.exit(1); });
