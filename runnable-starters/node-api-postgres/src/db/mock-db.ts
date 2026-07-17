/**
 * Mock database ¡ª in-memory demo data
 * Replace with PostgreSQL + Prisma/Drizzle for production.
 */
import type { CheckinRecord, AuditLogEntry, IdempotencyEntry, ApiRequestLogEntry, MockUser, BusinessRecord } from "../types/index.js";

// ============ Users ============
export const MOCK_USERS: MockUser[] = [
  { id: "u-001", username: "admin", password: "admin123", role: "admin", displayName: "Admin" },
  { id: "u-002", username: "user", password: "user123", role: "user", displayName: "User" },
];

// ============ Records (generic CRUD) ============
export const mockRecords: BusinessRecord[] = [
  {
    id: "rec-001",
    title: "Sample Record 1",
    description: "First sample record for demo",
    status: "pending",
    createdBy: "u-002",
    createdByName: "User",
    createdAt: new Date("2026-06-15T09:00:00+08:00").toISOString(),
    updatedAt: new Date("2026-06-15T09:00:00+08:00").toISOString(),
  },
  {
    id: "rec-002",
    title: "Sample Record 2",
    description: "Second sample record in progress",
    status: "in_progress",
    createdBy: "u-001",
    createdByName: "Admin",
    createdAt: new Date("2026-06-16T10:00:00+08:00").toISOString(),
    updatedAt: new Date("2026-06-16T12:00:00+08:00").toISOString(),
  },
];

// ============ Legacy checkins ============
export const mockCheckins: CheckinRecord[] = [
  { id: "chk-001", userId: "u-002", checkinDate: "2026-06-15", createdAt: new Date("2026-06-15T09:00:00+08:00").toISOString() },
  { id: "chk-002", userId: "u-002", checkinDate: "2026-06-16", createdAt: new Date("2026-06-16T08:30:00+08:00").toISOString() },
];

// ============ Audit ============
export const mockAuditLogs: AuditLogEntry[] = [
  { id: "audit-001", actorId: "u-002", action: "CHECKIN", targetType: "checkin", targetId: "chk-001", result: "success", createdAt: new Date("2026-06-15T09:00:00+08:00").toISOString() },
];

// ============ Idempotency ============
export const mockIdempotencyEntries: IdempotencyEntry[] = [];

// ============ API logs ============
export const mockApiLogs: ApiRequestLogEntry[] = [];