/**
 * Server entry point
 */
import { buildApp } from "./app.js";

const PORT = parseInt(process.env.PORT || "3001", 10);

async function main() {
  const app = buildApp();
  try {
    await app.listen({ port: PORT, host: "0.0.0.0" });
    console.log(`Products API testbed running at http://localhost:${PORT}`);
    console.log(`  Health: http://localhost:${PORT}/health`);
    console.log(`  Products: http://localhost:${PORT}/api/products`);
  } catch (err) {
    console.error("Failed to start server:", err);
    process.exit(1);
  }
}

main();