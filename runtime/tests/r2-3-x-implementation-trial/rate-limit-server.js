const fastify = require("fastify")({ logger: false });

async function start() {
  await fastify.register(require("@fastify/rate-limit"), {
    max: 3,                      // LOW global for testing
    timeWindow: 60000,           // 1 minute in ms
    trustProxy: true,
    keyGenerator: (req) => req.ip,
    onExceeded: (req, reply) => {
      reply.code(429).send({ error: "Too Many Requests", message: "Rate limit exceeded." });
    },
  });

  fastify.get("/api/data", async () => ({ data: "ok" }));

  fastify.post("/login", {
    config: {
      rateLimit: { max: 2, timeWindow: 60000 }
    },
    handler: async (request, reply) => {
      const { username, password } = request.body || {};
      if (username === "admin" && password === "password123") {
        return { token: "ok" };
      }
      return reply.status(401).send({ error: "Invalid" });
    },
  });

  fastify.get("/health", async () => ({ status: "ok" }));

  await fastify.listen({ port: 3300 });
  console.log("ready");
}

start().catch(e => { console.error(e.message); process.exit(1); });
