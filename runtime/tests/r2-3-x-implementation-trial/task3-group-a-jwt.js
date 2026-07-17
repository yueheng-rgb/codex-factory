// === TASK 3 GROUP A: JWT Refresh Token — No Search Baseline ===
// UNSURE items: refresh storage format, cookie vs header, rotation strategy
// Using model knowledge only

const fastify = require("fastify")({ logger: false });
const crypto = require("crypto");

// In-memory store (simulating DB) — UNSURE about hashing, storing raw for simplicity
const users = new Map();
const refreshTokens = new Map();

// Seed a test user
const bcryptjs = require("bcryptjs");
(async () => {
  users.set("admin", {
    username: "admin",
    passwordHash: await bcryptjs.hash("password123", 10),
  });
})();

const JWT_SECRET = "group-a-jwt-secret-change-in-production";
const ACCESS_EXPIRY = "15m";
const REFRESH_EXPIRY_MS = 7 * 24 * 60 * 60 * 1000; // 7 days

async function start() {
  await fastify.register(require("@fastify/jwt"), { secret: JWT_SECRET });
  await fastify.register(require("@fastify/cookie"));

  // POST /login
  fastify.post("/login", async (request, reply) => {
    const { username, password } = request.body || {};
    const user = users.get(username);
    if (!user) return reply.status(401).send({ error: "Invalid credentials" });

    const valid = await bcryptjs.compare(password, user.passwordHash);
    if (!valid) return reply.status(401).send({ error: "Invalid credentials" });

    // Issue access token
    const accessToken = fastify.jwt.sign(
      { username, role: "user" },
      { expiresIn: ACCESS_EXPIRY }
    );

    // UNSURE: Store refresh as opaque string or hashed?
    // Storing as opaque string for simplicity
    const refreshToken = crypto.randomBytes(32).toString("hex");
    refreshTokens.set(refreshToken, {
      username,
      expiresAt: Date.now() + REFRESH_EXPIRY_MS,
    });

    // UNSURE: httpOnly cookie or just return in body?
    // Returning in body for simplicity
    return reply.send({
      accessToken,
      refreshToken,
      expiresIn: 900, // 15 min in seconds
    });
  });

  // POST /refresh
  fastify.post("/refresh", async (request, reply) => {
    const { refreshToken } = request.body || {};
    if (!refreshToken) return reply.status(400).send({ error: "Missing refresh token" });

    const stored = refreshTokens.get(refreshToken);
    if (!stored) return reply.status(401).send({ error: "Invalid refresh token" });

    if (Date.now() > stored.expiresAt) {
      refreshTokens.delete(refreshToken);
      return reply.status(401).send({ error: "Refresh token expired" });
    }

    // UNSURE: Should we rotate (issue new + revoke old)?
    // Keeping simple — issue new access, keep same refresh
    const accessToken = fastify.jwt.sign(
      { username: stored.username, role: "user" },
      { expiresIn: ACCESS_EXPIRY }
    );

    return reply.send({
      accessToken,
      expiresIn: 900,
    });
  });

  // GET /protected — verify access token
  fastify.get("/protected", async (request, reply) => {
    try {
      await request.jwtVerify();
    } catch (err) {
      return reply.status(401).send({ error: "Invalid or expired token" });
    }
    return reply.send({ message: "Access granted", user: request.user });
  });

  await fastify.listen({ port: 3200 });
  console.log("Group A JWT server on port 3200");
}

start().catch((err) => {
  console.error("Group A JWT startup failed:", err.message);
  process.exit(1);
});
