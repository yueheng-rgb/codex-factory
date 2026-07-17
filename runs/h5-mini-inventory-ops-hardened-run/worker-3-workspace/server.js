// server.js — HTTP server for H5 mini inventory ops
// Node.js built-ins only (http module, no express).

const http = require("http");
const store = require("./store");
const { saveState, loadState } = require("./persistence");

// ─── Helpers ────────────────────────────────────────────────────────

function sendJSON(res, statusCode, data) {
  const body = JSON.stringify(data);
  res.writeHead(statusCode, {
    "Content-Type": "application/json; charset=utf-8",
    "Access-Control-Allow-Origin": "*",
    "Access-Control-Allow-Methods": "GET, POST, OPTIONS",
    "Access-Control-Allow-Headers": "Content-Type",
  });
  res.end(body);
}

function sendMarkdown(res, statusCode, md) {
  res.writeHead(statusCode, {
    "Content-Type": "text/markdown; charset=utf-8",
    "Access-Control-Allow-Origin": "*",
  });
  res.end(md);
}

function readBody(req) {
  return new Promise((resolve, reject) => {
    const chunks = [];
    req.on("data", (chunk) => chunks.push(chunk));
    req.on("end", () => {
      const raw = Buffer.concat(chunks).toString("utf-8");
      if (!raw.trim()) return resolve(null);
      try {
        resolve(JSON.parse(raw));
      } catch (e) {
        reject(new Error("Invalid JSON body"));
      }
    });
    req.on("error", reject);
  });
}

function parseURL(req) {
  const url = new URL(req.url, `http://${req.headers.host || "localhost"}`);
  return { pathname: url.pathname, searchParams: url.searchParams };
}

function route(method, pathname) {
  return `${method} ${pathname}`;
}

// ─── Route Handlers ─────────────────────────────────────────────────

async function handleHealth(req, res) {
  sendJSON(res, 200, { status: "ok" });
}

async function handleGetItems(req, res) {
  sendJSON(res, 200, store.getItems());
}

async function handleGetStock(req, res) {
  sendJSON(res, 200, store.getStock());
}

async function handleInbound(req, res) {
  const body = await readBody(req);
  if (!body || !body.skuId || body.quantity === undefined) {
    return sendJSON(res, 400, { error: "Missing required fields: skuId, quantity" });
  }
  try {
    const result = store.inbound(body.skuId, body.quantity, body.idempotencyKey || null);
    if (result === null) {
      return sendJSON(res, 200, { status: "idempotent", message: "Already processed" });
    }
    sendJSON(res, 201, result);
  } catch (err) {
    sendJSON(res, 400, { error: err.message });
  }
}

async function handleOutbound(req, res) {
  const body = await readBody(req);
  if (!body || !body.skuId || body.quantity === undefined) {
    return sendJSON(res, 400, { error: "Missing required fields: skuId, quantity" });
  }
  try {
    const result = store.outbound(body.skuId, body.quantity);
    sendJSON(res, 201, result);
  } catch (err) {
    sendJSON(res, 400, { error: err.message });
  }
}

async function handleReserve(req, res) {
  const body = await readBody(req);
  if (!body || !body.skuId || body.quantity === undefined) {
    return sendJSON(res, 400, { error: "Missing required fields: skuId, quantity" });
  }
  try {
    const result = store.reserve(body.skuId, body.quantity);
    sendJSON(res, 201, result);
  } catch (err) {
    sendJSON(res, 400, { error: err.message });
  }
}

async function handleRelease(req, res) {
  const body = await readBody(req);
  if (!body || !body.reservationId) {
    return sendJSON(res, 400, { error: "Missing required field: reservationId" });
  }
  try {
    const result = store.releaseReservation(body.reservationId);
    sendJSON(res, 200, result);
  } catch (err) {
    sendJSON(res, 400, { error: err.message });
  }
}

async function handleTransfer(req, res) {
  const body = await readBody(req);
  if (!body || !body.fromSkuId || !body.toSkuId || body.quantity === undefined) {
    return sendJSON(res, 400, { error: "Missing required fields: fromSkuId, toSkuId, quantity" });
  }
  try {
    const result = store.transfer(body.fromSkuId, body.toSkuId, body.quantity);
    sendJSON(res, 201, result);
  } catch (err) {
    sendJSON(res, 400, { error: err.message });
  }
}

async function handleGetAdjustments(req, res) {
  sendJSON(res, 200, store.getAdjustments());
}

async function handleGetAudit(req, res) {
  sendJSON(res, 200, store.getAudit());
}

async function handleExport(req, res) {
  sendJSON(res, 200, store.exportState());
}

async function handleImport(req, res) {
  const body = await readBody(req);
  if (!body) {
    return sendJSON(res, 400, { error: "Missing state data in body" });
  }
  try {
    store.importState(body);
    sendJSON(res, 200, { status: "imported" });
  } catch (err) {
    sendJSON(res, 400, { error: err.message });
  }
}

async function handleReport(req, res) {
  const md = store.generateReport();
  sendMarkdown(res, 200, md);
}

async function handleOptions(req, res) {
  res.writeHead(204, {
    "Access-Control-Allow-Origin": "*",
    "Access-Control-Allow-Methods": "GET, POST, OPTIONS",
    "Access-Control-Allow-Headers": "Content-Type",
  });
  res.end();
}

// ─── Router ─────────────────────────────────────────────────────────

const routes = {
  [route("GET", "/health")]: handleHealth,
  [route("GET", "/api/items")]: handleGetItems,
  [route("GET", "/api/stock")]: handleGetStock,
  [route("POST", "/api/inbound")]: handleInbound,
  [route("POST", "/api/outbound")]: handleOutbound,
  [route("POST", "/api/reserve")]: handleReserve,
  [route("POST", "/api/release")]: handleRelease,
  [route("POST", "/api/transfer")]: handleTransfer,
  [route("GET", "/api/adjustments")]: handleGetAdjustments,
  [route("GET", "/api/audit")]: handleGetAudit,
  [route("GET", "/api/export")]: handleExport,
  [route("POST", "/api/import")]: handleImport,
  [route("GET", "/api/report.md")]: handleReport,
};

async function handleRequest(req, res) {
  const { pathname } = parseURL(req);
  const key = route(req.method, pathname);

  if (req.method === "OPTIONS") {
    return handleOptions(req, res);
  }

  const handler = routes[key];
  if (handler) {
    try {
      await handler(req, res);
    } catch (err) {
      sendJSON(res, 500, { error: "Internal server error", detail: err.message });
    }
  } else {
    sendJSON(res, 404, { error: `Not found: ${req.method} ${pathname}` });
  }
}

// ─── Start Server ───────────────────────────────────────────────────

/**
 * Start the HTTP server on the given port.
 * @param {number} port
 * @returns {Promise<http.Server>} The running server instance.
 */
function startServer(port) {
  return new Promise((resolve, reject) => {
    const server = http.createServer(handleRequest);
    server.on("error", reject);
    server.listen(port, () => {
      resolve(server);
    });
  });
}

module.exports = { startServer };

// ─── Direct Run ─────────────────────────────────────────────────────
if (require.main === module) {
  const port = parseInt(process.env.PORT || "3456", 10);
  startServer(port)
    .then(() => {
      console.log(`Worker-3 HTTP server listening on http://localhost:${port}`);
      console.log("Routes:");
      for (const r of Object.keys(routes).sort()) {
        console.log(`  ${r}`);
      }
    })
    .catch((err) => {
      console.error("Failed to start server:", err.message);
      process.exit(1);
    });
}
