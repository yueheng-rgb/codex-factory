// Mini Inventory Admin — Server Entry Point
import Fastify from "fastify";
import { registerRoutes } from "./routes/inventory.js";

const PORT = parseInt(process.env.PORT || "3100", 10);

const app = Fastify({ logger: false });

// CORS for admin web surface
app.addHook("onRequest", async (_request, reply) => {
  reply.header("Access-Control-Allow-Origin", "*");
  reply.header("Access-Control-Allow-Methods", "GET,POST,PATCH,DELETE,OPTIONS");
  reply.header("Access-Control-Allow-Headers", "Content-Type");
  if (_request.method === "OPTIONS") {
    await reply.status(204).send();
  }
});

registerRoutes(app);

app.listen({ port: PORT, host: "0.0.0.0" }, (err, address) => {
  if (err) {
    console.error("Failed to start:", err);
    process.exit(1);
  }
  console.log(`Mini Inventory Admin running at ${address}`);
  console.log(`  Health: ${address}/health`);
  console.log(`  Items:  ${address}/api/items`);
});
