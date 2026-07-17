// Admin System Runtime Validation — Types
// Source: governance/expert-packs/admin-system/admin-system-pack.json v1.0.0

export type Role = "SUPER_ADMIN" | "ADMIN" | "OPERATOR" | "VIEWER";

export interface AdminUser {
  id: string;
  username: string;
  role: Role;
  permissions: string[];
  createdAt: string;
}

export type ResourceStatus = "DRAFT" | "ACTIVE" | "SUSPENDED" | "ARCHIVED" | "DELETED";
export const ALLOWED_STATUS_TRANSITIONS: Record<ResourceStatus, ResourceStatus[]> = {
  "DRAFT": ["ACTIVE", "DELETED"],
  "ACTIVE": ["SUSPENDED", "ARCHIVED", "DELETED"],
  "SUSPENDED": ["ACTIVE", "DELETED"],
  "ARCHIVED": ["ACTIVE", "DELETED"],
  "DELETED": []
};

export interface AdminResource {
  id: string;
  name: string;
  description: string;
  status: ResourceStatus;
  protectedData: string;
  createdBy: string;
  createdAt: string;
  updatedAt: string;
  deletedAt: string | null;
}

export interface AuditLogEntry {
  id: string;
  actorId: string;
  actorRole: Role;
  action: string;
  targetType: string;
  targetId: string;
  details: string;
  timestamp: string;
  result: "SUCCESS" | "REJECTED";
}

export type ConfirmationToken = string;

export interface BatchOperationRequest {
  filter?: { field: string; value: string };
  ids?: string[];
  maxAffected: number;
  confirmationToken: ConfirmationToken;
}

export interface BatchOperationResult {
  affectedCount: number;
  errors: string[];
}

export interface ExportRequest {
  format: "csv" | "json";
  fields: string[];
}

// Validation error codes mapped to invariants
export const ERROR_CODES = {
  UNAUTHORIZED: "ADMIN_REQUIRED",
  FORBIDDEN: "ROLE_PERMISSION_DENIED",
  ROLE_ESCALATION_BLOCKED: "ROLE_ESCALATION_BLOCKED",
  CONFIRMATION_REQUIRED: "CONFIRMATION_REQUIRED",
  INVALID_STATUS_TRANSITION: "INVALID_STATUS_TRANSITION",
  PROTECTED_FIELD: "PROTECTED_FIELD_ACCESS",
  BATCH_SCOPE_EXCEEDED: "BATCH_SCOPE_EXCEEDED",
  AUDIT_LOG_MISSING: "AUDIT_LOG_MISSING",
  EXPORT_PERMISSION_REQUIRED: "EXPORT_PERMISSION_REQUIRED",
  IMPORT_VALIDATION_FAILED: "IMPORT_VALIDATION_FAILED",
  PAGINATION_LIMIT_EXCEEDED: "PAGINATION_LIMIT_EXCEEDED",
  SEARCH_FILTER_INVALID: "SEARCH_FILTER_INVALID",
} as const;
