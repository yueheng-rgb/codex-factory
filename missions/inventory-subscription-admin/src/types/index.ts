// Mission Project: Inventory Subscription Admin — Types
// Expert Packs: admin-system, ecommerce, saas-tool

export type Role = "SUPER_ADMIN" | "ADMIN" | "OPERATOR" | "VIEWER";
export type TenantTier = "FREE" | "STARTER" | "PRO" | "ENTERPRISE";
export type SubscriptionStatus = "ACTIVE" | "EXPIRED" | "CANCELLED" | "TRIAL";
export type ProductStatus = "DRAFT" | "ACTIVE" | "SUSPENDED" | "ARCHIVED" | "DELETED";

export interface AdminUser { id: string; username: string; role: Role; tenantId: string; permissions: string[]; }
export interface Tenant { id: string; name: string; tier: TenantTier; subscriptionStatus: SubscriptionStatus; quotaLimit: number; quotaUsed: number; }
export interface Product { id: string; name: string; price: number; isFree: boolean; inventory: number; status: ProductStatus; tenantId: string; createdBy: string; createdAt: string; updatedAt: string; deletedAt: string | null; }
export interface InventoryAdjustment { productId: string; delta: number; reason: string; operatorId: string; timestamp: string; }
export interface AuditEntry { id: string; actorId: string; action: string; targetType: string; targetId: string; details: string; timestamp: string; tenantId: string; }

export const ALLOWED_STATUS: Record<ProductStatus, ProductStatus[]> = {
  DRAFT: ["ACTIVE","DELETED"], ACTIVE: ["SUSPENDED","ARCHIVED","DELETED"],
  SUSPENDED: ["ACTIVE","DELETED"], ARCHIVED: ["ACTIVE","DELETED"], DELETED: []
};

export const ERR = {
  UNAUTHORIZED: "ADMIN_REQUIRED", FORBIDDEN: "PERMISSION_DENIED",
  ROLE_ESCALATION: "ROLE_ESCALATION_BLOCKED", CONFIRMATION: "CONFIRMATION_REQUIRED",
  INVALID_STATUS: "INVALID_STATUS_TRANSITION", PROTECTED_FIELD: "PROTECTED_FIELD",
  PRICE_NEGATIVE: "PRICE_NEGATIVE", INVENTORY_NEGATIVE: "INVENTORY_NEGATIVE",
  QUOTA_EXCEEDED: "QUOTA_EXCEEDED", TENANT_ISOLATION: "TENANT_ISOLATION_VIOLATION",
  SUBSCRIPTION_EXPIRED: "SUBSCRIPTION_EXPIRED", AUDIT_MISSING: "AUDIT_LOG_MISSING",
  STALE_DATA: "STALE_REFERENCE", BATCH_SCOPE: "BATCH_SCOPE_EXCEEDED"
} as const;
