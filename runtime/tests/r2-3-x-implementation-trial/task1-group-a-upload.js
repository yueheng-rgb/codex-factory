// === TASK 1 GROUP A: Fastify Upload — No Search Baseline ===
// UNSURE items: API surface of @fastify/multipart v8+
// Using model knowledge only — may contain incorrect API

const fastify = require("fastify")({ logger: false });
const path = require("path");
const fs = require("fs");
const crypto = require("crypto");

const UPLOAD_DIR = path.join(__dirname, "uploads", "group-a");
fs.mkdirSync(UPLOAD_DIR, { recursive: true });

const ALLOWED_TYPES = ["image/png", "image/jpeg", "image/gif", "application/pdf"];

async function start() {
  // UNSURE: Is the option key 'limits.fileSize' or just 'fileSize' or 'limits' with 'fileSize' inside?
  // Guessing based on general Fastify plugin pattern:
  await fastify.register(require("@fastify/multipart"), {
    limits: {
      fileSize: 5 * 1024 * 1024, // 5MB — UNSURE if correct key
    },
  });

  // UNSURE: Is it request.file() or request.parts() or request.files()?
  // Guessing request.file() based on older fastify-multipart docs:
  fastify.post("/upload", async (request, reply) => {
    try {
      // UNSURE: Does this return a single file or an async iterator?
      const data = await request.file();

      if (!data) {
        return reply.status(400).send({ error: "No file uploaded" });
      }

      // Validate MIME type
      if (!ALLOWED_TYPES.includes(data.mimetype)) {
        return reply.status(400).send({ error: "File type not allowed" });
      }

      // Sanitize filename — basic approach, may miss path traversal edge cases
      const safeName = crypto.randomUUID() + "-" + path.basename(data.filename);
      const destPath = path.join(UPLOAD_DIR, safeName);

      // UNSURE: Is toBuffer() available? Or must we use the stream?
      const buffer = await data.toBuffer();
      await fs.promises.writeFile(destPath, buffer);

      return reply.send({
        url: `/uploads/group-a/${safeName}`,
        filename: data.filename,
        size: buffer.length,
        mimetype: data.mimetype,
      });
    } catch (err) {
      // UNSURE: What specific errors does @fastify/multipart throw?
      if (err.code === "FST_REQ_FILE_TOO_LARGE") {
        return reply.status(413).send({ error: "File too large" });
      }
      return reply.status(500).send({ error: "Upload failed" });
    }
  });

  await fastify.listen({ port: 3100 });
  console.log("Group A upload server on port 3100");
}

start().catch((err) => {
  console.error("Group A startup failed:", err.message);
  process.exit(1);
});

