// === TASK 1 GROUP C: Fastify Upload — Structured Search Guided ===
// Evidence-backed implementation using R2.3-W Group C Evidence Pack
// Sources: fastify/fastify-multipart README, backend.cafe tutorial

const fastify = require("fastify")({ logger: false });
const path = require("path");
const fs = require("fs");
const crypto = require("crypto");

const UPLOAD_DIR = path.join(__dirname, "uploads", "group-c");
fs.mkdirSync(UPLOAD_DIR, { recursive: true });

const ALLOWED_MIMES = [
  "image/png", "image/jpeg", "image/gif", "image/webp",
  "application/pdf", "application/zip",
];

const MAX_FILE_SIZE = 5 * 1024 * 1024; // 5MB

async function start() {
  // Confirmed: limits.fileSize is the correct option key
  // Source: fastify/fastify-multipart official README
  await fastify.register(require("@fastify/multipart"), {
    limits: {
      fileSize: MAX_FILE_SIZE,
      files: 1, // single file per request
    },
  });

  // Confirmed: request.file() is the correct method for single file
  // Returns object with: toBuffer(), file (stream), fields, mimetype, filename
  // Source: fastify/fastify-multipart README
  fastify.post("/upload", async (request, reply) => {
    try {
      const data = await request.file();

      if (!data) {
        return reply.status(400).send({ error: "No file uploaded" });
      }

      // MIME type whitelist validation
      if (!ALLOWED_MIMES.includes(data.mimetype)) {
        return reply.status(400).send({
          error: "File type not allowed",
          allowedTypes: ALLOWED_MIMES,
        });
      }

      // Sanitize filename against path traversal
      // path.basename strips any directory components
      // crypto.randomUUID prevents collisions and hides original name
      const originalName = path.basename(data.filename);
      const safeName = crypto.randomUUID() + "-" + originalName;
      const destPath = path.join(UPLOAD_DIR, safeName);

      // Confirmed: toBuffer() reads entire file into memory
      // For large files, use data.file (stream) with pipeline
      const buffer = await data.toBuffer();

      // Additional check: actual size vs declared
      if (buffer.length > MAX_FILE_SIZE) {
        return reply.status(413).send({ error: "File exceeds maximum size" });
      }

      await fs.promises.writeFile(destPath, buffer);

      return reply.send({
        url: `/uploads/group-c/${safeName}`,
        filename: originalName,
        storedName: safeName,
        size: buffer.length,
        mimetype: data.mimetype,
      });
    } catch (err) {
      // @fastify/multipart throws specific errors for size limits
      if (
        err.code === "FST_REQ_FILE_TOO_LARGE" ||
        err.message?.includes("File too large")
      ) {
        return reply.status(413).send({ error: "File too large" });
      }
      if (err.message?.includes("Unexpected end of form")) {
        return reply.status(400).send({ error: "Incomplete upload" });
      }
      return reply.status(500).send({ error: "Upload failed", detail: err.message });
    }
  });

  await fastify.listen({ port: 3101 });
  console.log("Group C upload server on port 3101");
}

start().catch((err) => {
  console.error("Group C startup failed:", err.message);
  process.exit(1);
});

