// Core types for SaaS runtime validation testbed

export type SubscriptionStatus = "ACTIVE" | "EXPIRED" | "CANCELLED";
export type WorkspaceStatus = "ACTIVE" | "DELETED";
export type UserRole = "ADMIN" | "MEMBER";

export interface Tenant {
  id: string;
  name: string;
  status: WorkspaceStatus;
  createdAt: string;
}

export interface User {
  id: string;
  email: string;
  role: UserRole;
  tenantId: string;
}

export interface Subscription {
  id: string;
  tenantId: string;
  plan: string;
  status: SubscriptionStatus;
  quotaTotal: number;
  quotaRemaining: number;
  expiresAt: string;
}

export interface GenerationRequest {
  tenantId: string;
  userId: string;
  model: string;
  prompt: string;
}

export interface GenerationResult {
  id: string;
  tenantId: string;
  userId: string;
  model: string;
  prompt: string;
  output: string;
  tokenCount: number;
  cost: number;
  createdAt: string;
}

export interface ApiKey {
  id: string;
  tenantId: string;
  key: string;
  maskedKey: string;
  provider: string;
  createdAt: string;
}

export interface BillingEvent {
  eventId: string;
  tenantId: string;
  type: string;
  amount: number;
  timestamp: string;
}

export interface ApiResponse<T = unknown> {
  ok: boolean;
  data?: T;
  error?: { code: string; message: string };
}
