// Core types for ecommerce runtime validation testbed

export type ProductStatus = "DRAFT" | "ACTIVE" | "ARCHIVED";
export type OrderStatus = "PENDING" | "PAID" | "CANCELLED" | "REFUNDED";
export type UserRole = "ADMIN" | "USER";

export interface Product {
  id: string;
  name: string;
  price: number;
  isFree: boolean;
  inventory: number;
  status: ProductStatus;
  createdBy: string;
  createdAt: string;
  updatedAt: string;
}

export interface InventoryAudit {
  id: string;
  productId: string;
  previousQuantity: number;
  newQuantity: number;
  delta: number;
  operatorId: string;
  reason: string;
  timestamp: string;
}

export interface OrderItem {
  productId: string;
  productName: string;
  unitPrice: number;
  quantity: number;
}

export interface Order {
  id: string;
  userId: string;
  items: OrderItem[];
  totalAmount: number;
  status: OrderStatus;
  paymentId: string | null;
  paidAmount: number;
  createdAt: string;
  updatedAt: string;
}

export interface PaymentCallback {
  transactionId: string;
  orderId: string;
  amount: number;
  timestamp: string;
}

export interface ApiResponse<T = unknown> {
  ok: boolean;
  data?: T;
  error?: {
    code: string;
    message: string;
  };
}

export const VALID_ORDER_TRANSITIONS: Record<OrderStatus, OrderStatus[]> = {
  PENDING: ["PAID", "CANCELLED"],
  PAID: ["REFUNDED"],
  CANCELLED: [],
  REFUNDED: []
};
