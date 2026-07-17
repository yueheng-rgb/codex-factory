import Fastify from "fastify";
import { registerSaaSRoutes } from "./routes/all.js";
const app = Fastify({ logger: false });
registerSaaSRoutes(app);
const port = parseInt(process.env.PORT || "3300");
app.listen({ port, host: "0.0.0.0" }, (err) => {
  if (err) { console.error(err); process.exit(1); }
  console.log(`SaaS Validation Testbed running at http://localhost:${port}`);
});
export default app;
