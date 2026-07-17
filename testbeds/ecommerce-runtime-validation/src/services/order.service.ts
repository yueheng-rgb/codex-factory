import { Order, OrderItem, OrderStatus, PaymentCallback, VALID_ORDER_TRANSITIONS } from "../types.js";
import { orders, products, processedPayments, generateId } from "../db/store.js";

// Ecommerce Pack Invariants enforced:
//   order_total_matches_items, payment_idempotency_required,
//   paid_order_cannot_be_modified_without_refund_flow,
//   cancelled_order_cannot_be_paid,
//   archived_product_not_sellable (during create),
//   refund_amount_cannot_exceed_paid_amount

export interface CreateOrderInput {
  items: { productId: string; quantity: number }[];
}

export function createOrder(input: CreateOrderInput, userId: string): Order | { error: string } {
  if (!input.items || input.items.length === 0) {
    return { error: "EMPTY_ORDER: Order must have at least one item" };
  }

  const orderItems: OrderItem[] = [];
  let calculatedTotal = 0;

  for (const item of input.items) {
    if (item.quantity <= 0) {
      return { error: "INVALID_QUANTITY: Item quantity must be positive" };
    }
    const product = products.get(item.productId);
    if (!product) {
      return { error: `PRODUCT_NOT_FOUND: Product ${item.productId} not found` };
    }
    // INVARIANT: archived_product_not_sellable
    if (product.status === "ARCHIVED") {
      return { error: `ARCHIVED_NOT_SELLABLE: Product ${item.productId} is archived and cannot be ordered` };
    }
    const lineTotal = product.price * item.quantity;
    calculatedTotal += lineTotal;
    orderItems.push({
      productId: product.id,
      productName: product.name,
      unitPrice: product.price,
      quantity: item.quantity
    });
  }

  // Round to 2 decimal places
  calculatedTotal = Math.round(calculatedTotal * 100) / 100;

  const order: Order = {
    id: generateId("ord"),
    userId,
    items: orderItems,
    totalAmount: calculatedTotal,
    status: "PENDING",
    paymentId: null,
    paidAmount: 0,
    createdAt: new Date().toISOString(),
    updatedAt: new Date().toISOString()
  };
  orders.set(order.id, order);
  return order;
}

export function getOrder(id: string): Order | null {
  return orders.get(id) ?? null;
}

export function processPayment(payment: PaymentCallback): { order: Order } | { error: string } {
  // INVARIANT: payment_idempotency_required
  if (processedPayments.has(payment.transactionId)) {
    const existingOrder = Array.from(orders.values()).find(o => o.paymentId === payment.transactionId);
    return { order: existingOrder! };
  }

  const order = orders.get(payment.orderId);
  if (!order) return { error: "NOT_FOUND: Order not found" };

  // INVARIANT: cancelled_order_cannot_be_paid
  if (order.status === "CANCELLED") {
    return { error: "CANCELLED_CANNOT_PAY: Cancelled orders cannot be paid" };
  }

  if (order.status === "PAID") {
    // Already paid — return existing (idempotent for another callback on same order)
    processedPayments.add(payment.transactionId);
    return { order };
  }

  if (order.status !== "PENDING") {
    return { error: `INVALID_TRANSITION: Cannot pay order in ${order.status} status` };
  }

  // INVARIANT: order_total_matches_items (verify amount matches)
  if (Math.abs(payment.amount - order.totalAmount) > 0.01) {
    return { error: `AMOUNT_MISMATCH: Payment amount ${payment.amount} does not match order total ${order.totalAmount}` };
  }

  order.status = "PAID";
  order.paymentId = payment.transactionId;
  order.paidAmount = payment.amount;
  order.updatedAt = new Date().toISOString();
  processedPayments.add(payment.transactionId);
  orders.set(order.id, order);
  return { order };
}

export function processRefund(orderId: string, amount: number): Order | { error: string } {
  const order = orders.get(orderId);
  if (!order) return { error: "NOT_FOUND: Order not found" };

  // INVARIANT: paid_order_cannot_be_modified_without_refund_flow
  // Refund flow IS the correct path for modifying a paid order

  if (order.status !== "PAID") {
    return { error: `NOT_PAID: Cannot refund order in ${order.status} status` };
  }

  // INVARIANT: refund_amount_cannot_exceed_paid_amount
  if (amount > order.paidAmount) {
    return { error: "REFUND_EXCEEDS_PAID: Refund amount cannot exceed paid amount" };
  }

  if (amount <= 0) {
    return { error: "INVALID_REFUND: Refund amount must be positive" };
  }

  order.status = "REFUNDED";
  order.updatedAt = new Date().toISOString();
  orders.set(order.id, order);
  return order;
}

export function cancelOrder(orderId: string): Order | { error: string } {
  const order = orders.get(orderId);
  if (!order) return { error: "NOT_FOUND: Order not found" };

  if (order.status === "PAID") {
    // INVARIANT: paid_order_cannot_be_modified_without_refund_flow
    return { error: "PAID_CANNOT_CANCEL: Paid orders must go through refund flow, not direct cancellation" };
  }

  if (order.status !== "PENDING") {
    return { error: `INVALID_TRANSITION: Cannot cancel order in ${order.status} status` };
  }

  order.status = "CANCELLED";
  order.updatedAt = new Date().toISOString();
  orders.set(order.id, order);
  return order;
}
