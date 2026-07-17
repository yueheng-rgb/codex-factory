import Fastify from "fastify";
import { registerProductRoutes } from "./routes/products.js";
import { registerOrderRoutes } from "./routes/orders.js";

const app = Fastify({ logger: false });

app.get("/health", async () => {
  return { ok: true, data: { service: "ecommerce-runtime-validation", version: "1.0.0" } };
});

registerProductRoutes(app);
registerOrderRoutes(app);

const port = parseInt(process.env.PORT || "3200");
app.listen({ port, host: "0.0.0.0" }, (err, address) => {
  if (err) {
    console.error("Failed to start:", err);
    process.exit(1);
  }
  console.log(`Ecommerce Validation Testbed running at ${address}`);
  console.log("Endpoints: /health, /api/products, /api/orders, /api/payment-callback, /api/audit-log");
});

export default app;
