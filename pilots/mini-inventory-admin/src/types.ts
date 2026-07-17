// Mini Inventory Admin — Core Types
export interface Item {
  id: string;
  name: string;
  description: string;
  price: number;          // invariant: >= 0, > 0 unless explicit_free
  explicitFree: boolean;  // if true, price=0 is allowed
  inventory: number;      // invariant: >= 0
  category: string;
  status: ItemStatus;     // invariant: only valid transitions
  createdAt: string;
  updatedAt: string;
}

export type ItemStatus = "DRAFT" | "ACTIVE" | "DISCONTINUED" | "ARCHIVED";

export const VALID_STATUS_TRANSITIONS: Record<ItemStatus, ItemStatus[]> = {
  DRAFT:         ["ACTIVE", "DISCONTINUED", "ARCHIVED"],
  ACTIVE:        ["DISCONTINUED", "ARCHIVED"],
  DISCONTINUED:  ["ACTIVE", "ARCHIVED"],
  ARCHIVED:      [], // archived_entity_not_mutable invariant
};

export const PROTECTED_FIELDS = ["id", "createdAt", "updatedAt"] as const;

export interface PaginatedResult<T> {
  items: T[];
  page: number;
  pageSize: number;
  total: number;
  totalPages: number;
}

export interface ApiResponse<T> {
  ok: boolean;
  data?: T;
  error?: ApiError;
}

export interface ApiError {
  code: string;
  message: string;
  details?: Record<string, unknown>;
}
