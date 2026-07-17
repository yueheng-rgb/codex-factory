// =============================================================================
// Cross-Pack CPM-001 Shared Domain Types
// Miniapp Ecommerce Admin — merged invariants from 3 packs
// =============================================================================

export interface Product {
  id: string;
  name: string;
  price: number;
  inventory: number;
  status: ProductStatus;
}

export type ProductStatus = "draft" | "active" | "inactive" | "deleted";

export interface Order {
  id: string;
  userId: string;
  items: OrderItem[];
  totalPrice: number;
  status: OrderStatus;
  paymentId?: string;
}

export type OrderStatus = "pending" | "paid" | "shipped" | "completed" | "cancelled";

export interface OrderItem {
  productId: string;
  quantity: number;
  price: number;
}

export interface AdminUser {
  id: string;
  username: string;
  role: "admin" | "super_admin";
}

export interface Session {
  token: string;
  userId: string;
  openid: string;
  role: "user" | "admin" | "super_admin";
  expiresAt: number;
}

export interface PaymentCallback {
  orderId: string;
  paymentId: string;
  amount: number;
  idempotencyKey: string;
}

export interface ApiError {
  error: string;
  code: string;
  [key: string]: unknown;
}

export const VALID_STATUS_TRANSITIONS: Record<OrderStatus, OrderStatus[]> = {
  pending: ["paid", "cancelled"],
  paid: ["shipped", "cancelled"],
  shipped: ["completed"],
  completed: [],
  cancelled: [],
};

export const MINIAPP_APPID = "wx1234567890abcdef";
export const MINIAPP_SECRET = "sk-test-secret-1234567890abcdef";
