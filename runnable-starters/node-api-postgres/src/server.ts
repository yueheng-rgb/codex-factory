/**
 * 服务入口
 * 启动 Fastify 服务器。PORT 默认 3000。
 */

import { buildApp } from "./app.js";

const PORT = parseInt(process.env.PORT || "3000", 10);

async function main() {
  const app = buildApp();

  try {
    await app.listen({ port: PORT, host: "0.0.0.0" });
    console.log(`🚀 Server running at http://localhost:${PORT}`);
    console.log(`   Health: http://localhost:${PORT}/health`);
  } catch (err) {
    console.error("Failed to start server:", err);
    process.exit(1);
  }
}

main();
