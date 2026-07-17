/**
 * Products API Testbed ¡ª shared types
 */

export type ProductStatus = "active" | "inactive" | "discontinued";

export interface Product {
  id: string;
  name: string;
  description: string;
  price: number;
  category: string;
  status: ProductStatus;
  createdAt: string;
  updatedAt: string;
}

export interface ProductInput {
  name: string;
  description: string;
  price: number;
  category: string;
}

export interface ProductUpdate {
  name?: string;
  description?: string;
  price?: number;
  category?: string;
}

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