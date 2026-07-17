import { FastifyInstance } from "fastify";
import { createOrder, getOrder, processPayment, processRefund, cancelOrder } from "../services/order.service.js";

function getUserId(request: { headers: Record<string, string | undefined> }): string {
  return request.headers["x-user-id"] || "anon";
}

export function registerOrderRoutes(app: FastifyInstance): void {
  app.post("/api/orders", async (request, reply) => {
    const body = request.body as { items: { productId: string; quantity: number }[] };
    const result = createOrder(body, getUserId(request));
    if ("error" in result) {
      const [code, ...msg] = result.error.split(": ");
      reply.code(400);
      return { ok: false, error: { code, message: msg.join(": ") } };
    }
    reply.code(201);
    return { ok: true, data: result };
  });

  app.get("/api/orders/:id", async (request) => {
    const { id } = request.params as { id: string };
    const order = getOrder(id);
    if (!order) return { statusCode: 404, ...{ ok: false, error: { code: "NOT_FOUND", message: "Order not found" } } };
    return { ok: true, data: order };
  });

  app.post("/api/payment-callback", async (request, reply) => {
    const body = request.body as { transactionId: string; orderId: string; amount: number };
    const result = processPayment({
      transactionId: body.transactionId,
      orderId: body.orderId,
      amount: body.amount,
      timestamp: new Date().toISOString()
    });
    if ("error" in result) {
      const [code, ...msg] = result.error.split(": ");
      reply.code(400);
      return { ok: false, error: { code, message: msg.join(": ") } };
    }
    return { ok: true, data: result.order };
  });

  app.post("/api/orders/:id/refund", async (request, reply) => {
    const { id } = request.params as { id: string };
    const body = request.body as { amount: number };
    const result = processRefund(id, body.amount);
    if ("error" in result) {
      const [code, ...msg] = result.error.split(": ");
      reply.code(400);
      return { ok: false, error: { code, message: msg.join(": ") } };
    }
    return { ok: true, data: result };
  });

  app.post("/api/orders/:id/cancel", async (request, reply) => {
    const { id } = request.params as { id: string };
    const result = cancelOrder(id);
    if ("error" in result) {
      const [code, ...msg] = result.error.split(": ");
      reply.code(400);
      return { ok: false, error: { code, message: msg.join(": ") } };
    }
    return { ok: true, data: result };
  });
}
