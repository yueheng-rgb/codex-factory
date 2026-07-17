// Shared types for NexusDesk Enterprise Lite

export type UserRole = 'admin' | 'manager' | 'agent' | 'client' | 'viewer';

export interface User {
  id: string;
  email: string;
  name: string;
  role: UserRole;
  organizationId: string | null;
  createdAt: string;
  updatedAt: string;
}

export interface AuthPayload {
  userId: string;
  email: string;
  role: UserRole;
  organizationId: string | null;
}

export type TicketStatus = 'new' | 'triaged' | 'assigned' | 'waiting_customer' | 'resolved' | 'closed';
export type TicketPriority = 'low' | 'medium' | 'high' | 'urgent';
export type ApprovalStatus = 'pending' | 'approved' | 'rejected';
export type TaskStatus = 'todo' | 'in_progress' | 'review' | 'done';

export interface Client {
  id: string; name: string; email: string; phone?: string;
  organizationId: string; createdAt: string; updatedAt: string;
}
export interface Project {
  id: string; name: string; description?: string; status: 'active' | 'archived';
  organizationId: string; leadId: string; createdAt: string; updatedAt: string;
}
export interface Task {
  id: string; title: string; description?: string; status: TaskStatus;
  priority: TicketPriority; projectId: string; assigneeId?: string;
  dueDate?: string; createdAt: string; updatedAt: string;
}
export interface Ticket {
  id: string; title: string; description?: string; status: TicketStatus;
  priority: TicketPriority; projectId: string; assigneeId?: string;
  clientId?: string; createdAt: string; updatedAt: string;
}
export interface Approval {
  id: string; ticketId: string; type: string; status: ApprovalStatus;
  requestedById: string; approvedById?: string; comment?: string;
  createdAt: string; updatedAt: string;
}
export interface Article {
  id: string; title: string; content: string; category: string;
  authorId: string; organizationId: string; createdAt: string; updatedAt: string;
}
export interface Notification {
  id: string; userId: string; type: string; title: string; message: string;
  read: boolean; link?: string; createdAt: string;
}
export interface AuditEntry {
  id: string; userId: string; action: string; entityType: string;
  entityId: string; changes: string; createdAt: string;
}
export interface AutomationRule {
  id: string; name: string; trigger: string; conditions: string;
  actions: string; enabled: boolean; organizationId: string;
  createdAt: string; updatedAt: string;
}
export interface ApiResponse<T> { success: boolean; data?: T; error?: string; }
export interface PaginatedResponse<T> extends ApiResponse<T[]> { total: number; page: number; pageSize: number; }
