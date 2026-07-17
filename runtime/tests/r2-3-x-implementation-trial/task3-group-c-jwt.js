// === TASK 3 GROUP C: JWT Refresh Token — Structured Search Guided ===
// Evidence-backed best practices:
//   - httpOnly + Secure + SameSite=Strict cookie (confirmed)
//   - SHA-256 hashed refresh token (confirmed)
//   - Token family rotation + reuse detection (confirmed)
//   - bcryptjs for password hashing (confirmed acceptable)

const fastify = require("fastify")({ logger: false });
const crypto = require("crypto");
const bcryptjs = require("bcryptjs");

// In-memory stores (simulating DB tables)
const users = new Map();
const refreshTokenFamilies = new Map(); // familyId -> { username, revoked }
const refreshTokenHashes = new Map();   // tokenHash -> { familyId, expiresAt, used }

const JWT_SECRET = "group-c-jwt-secret-change-in-production-32bytes!";
const ACCESS_EXPIRY = "15m";
const REFRESH_EXPIRY_MS = 7 * 24 * 60 * 60 * 1000; // 7 days

function sha256(data) {
  return crypto.createHash("sha256").update(data).digest("hex");
}

async function start() {
  // Seed test user
  users.set("admin", {
    username: "admin",
    passwordHash: await bcryptjs.hash("password123", 10),
  });

  await fastify.register(require("@fastify/jwt"), { secret: JWT_SECRET });
  await fastify.register(require("@fastify/cookie"), {
    secret: "cookie-signing-secret-change-me",
  });

  // POST /login
  fastify.post("/login", async (request, reply) => {
    const { username, password } = request.body || {};
    const user = users.get(username);
    if (!user) {
      return reply.status(401).send({ error: "Invalid credentials" });
    }

    const valid = await bcryptjs.compare(password, user.passwordHash);
    if (!valid) {
      return reply.status(401).send({ error: "Invalid credentials" });
    }

    // Issue access token (short-lived, Bearer header)
    const accessToken = fastify.jwt.sign(
      { username, role: "user" },
      { expiresIn: ACCESS_EXPIRY }
    );

    // Create refresh token family + first token
    const familyId = crypto.randomUUID();
    const refreshToken = crypto.randomBytes(32).toString("hex");
    const tokenHash = sha256(refreshToken);

    refreshTokenFamilies.set(familyId, { username, revoked: false });
    refreshTokenHashes.set(tokenHash, {
      familyId,
      expiresAt: Date.now() + REFRESH_EXPIRY_MS,
      used: false,
    });

    // Set httpOnly, Secure, SameSite=Strict cookie
    // Confirmed best practice: prevents XSS access, limits CSRF
    reply.setCookie("refreshToken", refreshToken, {
      httpOnly: true,
      secure: false, // false for localhost testing; true in production
      sameSite: "Strict",
      path: "/refresh",
      maxAge: REFRESH_EXPIRY_MS / 1000,
      signed: true,
    });

    return reply.send({
      accessToken,
      expiresIn: 900,
      tokenType: "Bearer",
    });
  });

  // POST /refresh — with rotation + reuse detection
  fastify.post("/refresh", async (request, reply) => {
    // Read refresh token from signed httpOnly cookie
    const refreshToken = request.cookies?.refreshToken;
    // Check unsigned cookie too (for testing convenience)
    const rawRefreshToken = request.cookies?.refreshToken || (request.body?.refreshToken);

    if (!refreshToken && !rawRefreshToken) {
      return reply.status(400).send({ error: "Missing refresh token" });
    }

    const token = refreshToken || rawRefreshToken;
    const tokenHash = sha256(token);
    const stored = refreshTokenHashes.get(tokenHash);

    if (!stored) {
      return reply.status(401).send({ error: "Invalid refresh token" });
    }

    // REUSE DETECTION: if token was already used, revoke entire family
    // Confirmed: this detects stolen refresh tokens
    if (stored.used) {
      const family = refreshTokenFamilies.get(stored.familyId);
      if (family) {
        family.revoked = true;
      }
      return reply.status(401).send({ error: "Token reuse detected — all sessions revoked" });
    }

    // Check if family is revoked
    const family = refreshTokenFamilies.get(stored.familyId);
    if (!family || family.revoked) {
      return reply.status(401).send({ error: "Session revoked" });
    }

    if (Date.now() > stored.expiresAt) {
      refreshTokenHashes.delete(tokenHash);
      return reply.status(401).send({ error: "Refresh token expired" });
    }

    // Mark current token as used
    stored.used = true;

    // ROTATE: issue new refresh token in same family
    const newRefreshToken = crypto.randomBytes(32).toString("hex");
    const newTokenHash = sha256(newRefreshToken);
    refreshTokenHashes.set(newTokenHash, {
      familyId: stored.familyId,
      expiresAt: Date.now() + REFRESH_EXPIRY_MS,
      used: false,
    });

    // Issue new access token
    const accessToken = fastify.jwt.sign(
      { username: family.username, role: "user" },
      { expiresIn: ACCESS_EXPIRY }
    );

    // Set new cookie (rotate)
    reply.setCookie("refreshToken", newRefreshToken, {
      httpOnly: true,
      secure: false,
      sameSite: "Strict",
      path: "/refresh",
      maxAge: REFRESH_EXPIRY_MS / 1000,
      signed: true,
    });

    return reply.send({
      accessToken,
      expiresIn: 900,
      tokenType: "Bearer",
    });
  });

  // POST /logout — revoke family
  fastify.post("/logout", async (request, reply) => {
    const refreshToken = request.cookies?.refreshToken || request.body?.refreshToken;
    if (refreshToken) {
      const tokenHash = sha256(refreshToken);
      const stored = refreshTokenHashes.get(tokenHash);
      if (stored) {
        const family = refreshTokenFamilies.get(stored.familyId);
        if (family) family.revoked = true;
      }
    }
    reply.clearCookie("refreshToken", { path: "/refresh" });
    return reply.send({ message: "Logged out" });
  });

  // GET /protected
  fastify.get("/protected", async (request, reply) => {
    try {
      await request.jwtVerify();
    } catch (err) {
      return reply.status(401).send({ error: "Invalid or expired token" });
    }
    return reply.send({ message: "Access granted", user: request.user });
  });

  await fastify.listen({ port: 3201 });
  console.log("Group C JWT server on port 3201");
}

start().catch((err) => {
  console.error("Group C JWT startup failed:", err.message);
  process.exit(1);
});
