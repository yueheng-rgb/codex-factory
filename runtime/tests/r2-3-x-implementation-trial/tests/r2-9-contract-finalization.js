// === R2.9 Products API Contract Finalization Tests (18 tests) ===
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
  console.log("=== R2.9 Products API Contract Finalization (18 tests) ===\n");

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
  });

  // T4: Detail 404 — unified error format
  await test("T4: GET /api/products/99999 returns 404 unified error", async () => {
    const r = await fetch(`${BASE}/api/products/99999`);
    assert(r.status === 404, `status ${r.status}`);
    const j = await r.json();
    assert(j.error, "no error wrapper");
    assert(j.error.code === 404, `error code ${j.error.code}`);
    assert(j.error.message, "no error message");
  });

  // T5: Create success
  await test("T5: POST /api/products creates product", async () => {
    const r = await fetch(`${BASE}/api/products`, {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({ name: "R2.9 Contract Test", category: "electronics", price: 99.99 }),
    });
    assert(r.status === 201, `status ${r.status}`);
    const j = await r.json();
    assert(j.data.id, "no id");
    createdId = j.data.id;
  });

  // T6: Missing required field — unified 400
  await test("T6: POST /api/products missing required field returns 400 unified error", async () => {
    const r = await fetch(`${BASE}/api/products`, {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({ name: "No Category" }),
    });
    assert(r.status === 400, `status ${r.status}`);
    const j = await r.json();
    assert(j.error, "no error wrapper");
    assert(j.error.code === 400, `code ${j.error.code}`);
    assert(j.error.message.includes("required"), "message should mention required");
    assert(Array.isArray(j.error.details), "details should be array");
  });

  // T7: POST unknown field — REJECTED 400 (not stripped)
  await test("T7: POST /api/products unknown field returns 400 (rejected, not stripped)", async () => {
    const r = await fetch(`${BASE}/api/products`, {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({ name: "Extra Field", category: "books", price: 29.99, bogus: "evil" }),
    });
    assert(r.status === 400, `status ${r.status} — unknown field should be rejected, not stripped`);
    const j = await r.json();
    assert(j.error, "no error wrapper");
    assert(j.error.code === 400, `code ${j.error.code}`);
    assert(j.error.message.includes("additional"), "message should mention additional properties");
  });

  // T8: PATCH update success + updated_at
  await test("T8: PATCH /api/products/:id updates product and sets updated_at", async () => {
    const r = await fetch(`${BASE}/api/products/${createdId}`, {
      method: "PATCH",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({ name: "R2.9 Contract Updated", price: 149.99 }),
    });
    assert(r.status === 200, `status ${r.status}`);
    const j = await r.json();
    assert(j.data.name === "R2.9 Contract Updated", "name not updated");
    assert(j.data.price === 149.99, "price not updated");
    assert(j.data.updated_at, "updated_at missing");
    console.log(`      updated_at: ${j.data.updated_at}`);
  });

  // T9: PATCH unknown field — REJECTED 400
  await test("T9: PATCH /api/products/:id unknown field returns 400 (rejected)", async () => {
    const r = await fetch(`${BASE}/api/products/${createdId}`, {
      method: "PATCH",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({ hacker_field: "nope" }),
    });
    assert(r.status === 400, `status ${r.status} — unknown field should be rejected`);
    const j = await r.json();
    assert(j.error, "no error wrapper");
    assert(j.error.code === 400, `code ${j.error.code}`);
    assert(j.error.message.includes("additional"), "should mention additional properties");
  });

  // T10: PATCH type error — unified 400
  await test("T10: PATCH /api/products/:id type error returns 400 unified error", async () => {
    const r = await fetch(`${BASE}/api/products/${createdId}`, {
      method: "PATCH",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({ price: "not-a-number" }),
    });
    assert(r.status === 400, `status ${r.status}`);
    const j = await r.json();
    assert(j.error, "no error wrapper");
    assert(j.error.code === 400, `code ${j.error.code}`);
  });

  // T11: PATCH update 404 — unified error
  await test("T11: PATCH /api/products/99999 returns 404 unified error", async () => {
    const r = await fetch(`${BASE}/api/products/99999`, {
      method: "PATCH",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({ name: "nope" }),
    });
    assert(r.status === 404, `status ${r.status}`);
    const j = await r.json();
    assert(j.error, "no error wrapper");
    assert(j.error.code === 404, `code ${j.error.code}`);
  });

  // T12: Status active → inactive
  await test("T12: PATCH /api/products/:id/status active→inactive works", async () => {
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

  // T13: Status inactive → archived
  await test("T13: PATCH /api/products/:id/status inactive→archived works", async () => {
    const r = await fetch(`${BASE}/api/products/${inactiveId}/status`, {
      method: "PATCH",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({ status: "archived" }),
    });
    assert(r.status === 200, `status ${r.status}`);
    const j = await r.json();
    assert(j.data.status === "archived", `status is ${j.data.status}`);
  });

  // T14: Status archived→active blocked — 409 unified error
  await test("T14: PATCH status archived→active blocked returns 409 unified error", async () => {
    const r = await fetch(`${BASE}/api/products/${inactiveId}/status`, {
      method: "PATCH",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({ status: "active" }),
    });
    assert(r.status === 409, `status ${r.status}`);
    const j = await r.json();
    assert(j.error, "no error wrapper");
    assert(j.error.code === 409, `code ${j.error.code}`);
    assert(j.error.message.includes("Invalid"), "message should mention invalid transition");
  });

  // T15: Archived product update blocked — 409 unified error
  await test("T15: PATCH archived product update blocked returns 409 unified error", async () => {
    const r = await fetch(`${BASE}/api/products/${inactiveId}`, {
      method: "PATCH",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({ name: "Should Fail" }),
    });
    assert(r.status === 409, `status ${r.status}`);
    const j = await r.json();
    assert(j.error.code === 409, `code ${j.error.code}`);
    assert(j.error.message.includes("archived"), "message should mention archived");
  });

  // T16: PATCH id param type error — unified 400
  await test("T16: GET /api/products/abc param type error returns 400 unified error", async () => {
    const r = await fetch(`${BASE}/api/products/abc`);
    assert(r.status === 400, `status ${r.status}`);
    const j = await r.json();
    assert(j.error, "no error wrapper");
    assert(j.error.code === 400, `code ${j.error.code}`);
    assert(Array.isArray(j.error.details), "details should be array");
  });

  // T17: PATCH empty body rejected — 400
  await test("T17: PATCH /api/products/:id empty body returns 400", async () => {
    const fresh = await (await fetch(`${BASE}/api/products?limit=1&sort=id&order=desc`)).json();
    const id = fresh.data[0].id;
    const r = await fetch(`${BASE}/api/products/${id}`, {
      method: "PATCH",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({}),
    });
    assert(r.status === 400, `status ${r.status}`);
  });

  // T18: Health check
  await test("T18: GET /health returns ok with product count", async () => {
    const r = await fetch(`${BASE}/health`);
    assert(r.status === 200, `status ${r.status}`);
    const j = await r.json();
    assert(j.status === "ok", "status not ok");
    assert(j.products >= 53, `products ${j.products} < 53`);
  });

  console.log(`\n=== RESULTS: ${passed}/${passed + failed} PASS ===`);
  results.forEach(r => console.log(`  [${r.status}] ${r.name}${r.error ? " — " + r.error : ""}`));

  // Summary checks
  const unknownRejected = results.find(r => r.name.includes("T7"));
  const unifiedErrors = results.filter(r => r.name.includes("unified error") || r.name.includes("unified"));
  console.log(`\nUnknown field rejection: ${unknownRejected?.status === "PASS" ? "VERIFIED" : "FAILED"}`);
  console.log(`Unified error format checks: ${unifiedErrors.filter(r => r.status === "PASS").length}/${unifiedErrors.length} PASS`);

  if (failed > 0) process.exit(1);
}

run().catch(e => { console.error("TEST RUNNER ERROR:", e.message); process.exit(1); });
