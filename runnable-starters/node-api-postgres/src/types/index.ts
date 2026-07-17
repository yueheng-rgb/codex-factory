/**
 * Shared types for the API service starter
 */

export interface PaginationParams {
  page: number;
  pageSize: number;
}

export interface PaginatedResult<T> {
  items: T[];
  page: number;
  pageSize: number;
  total: number;
  totalPages: number;
}

// ============ Users ============

export interface MockUser {
  id: string;
  username: string;
  password: string;
  role: "admin" | "user";
  displayName: string;
}

// ============ Records (generic CRUD resource) ============

export type RecordStatus = "pending" | "in_progress" | "completed" | "cancelled";

export interface BusinessRecord {
  id: string;
  title: string;
  description: string;
  status: RecordStatus;
  createdBy: string;
  createdByName: string;
  createdAt: string;
  updatedAt: string;
  remark?: string;
}

// ============ Legacy (preserved for admin route) ============

export interface CheckinRecord {
  id: string;
  userId: string;
  checkinDate: string;
  createdAt: string;
}

export interface AuditLogEntry {
  id: string;
  actorId: string;
  action: string;
  targetType: string;
  targetId: string;
  result: "success" | "failure";
  errorCode?: string;
  detail?: string;
  createdAt: string;
}

export interface IdempotencyEntry {
  key: string;
  userId: string;
  operation: string;
  result: unknown;
  createdAt: number;
  expiresAt: number;
}

export interface ApiRequestLogEntry {
  id: string;
  method: string;
  path: string;
  statusCode: number;
  durationMs: number;
  userId?: string;
  ip?: string;
  createdAt: string;
}