/**
 * Product service ¡ª business logic layer
 */
import type { Product, ProductStatus } from "../types/index.js";
import * as repo from "../repositories/product-repository.js";
import { validateProductInput, validateProductUpdate } from "../schemas/product.schema.js";

const VALID_STATUSES: ProductStatus[] = ["active", "inactive", "discontinued"];
const STATUS_TRANSITIONS: Record<ProductStatus, ProductStatus[]> = {
  active: ["inactive", "discontinued"],
  inactive: ["active", "discontinued"],
  discontinued: [],
};

export function listProducts(params: { page: number; pageSize: number; search?: string; category?: string; status?: string }) {
  return repo.list(params);
}

export function getProduct(id: string): Product | null {
  return repo.getById(id);
}

export function createProduct(body: Record<string, unknown>): { data?: Product; error?: { code: string; message: string; details?: Array<{ field: string; message: string }> } } {
  const validation = validateProductInput(body);
  if (!validation.valid) {
    return { error: { code: "VALIDATION_ERROR", message: "Input validation failed", details: validation.errors } };
  }
  const product = repo.create(body as { name: string; description: string; price: number; category: string });
  return { data: product };
}

export function updateProduct(id: string, body: Record<string, unknown>): { data?: Product; error?: { code: string; message: string; details?: Array<{ field: string; message: string }> } } {
  const existing = repo.getById(id);
  if (!existing) return { error: { code: "NOT_FOUND", message: `Product "${id}" not found` } };

  const validation = validateProductUpdate(body);
  if (!validation.valid) {
    return { error: { code: "VALIDATION_ERROR", message: "Input validation failed", details: validation.errors } };
  }
  if (Object.keys(body).length === 0) {
    return { error: { code: "VALIDATION_ERROR", message: "No fields to update" } };
  }

  const updated = repo.update(id, body as { name?: string; description?: string; price?: number; category?: string });
  return updated ? { data: updated } : { error: { code: "NOT_FOUND", message: `Product "${id}" not found` } };
}

export function updateProductStatus(id: string, status: string): { data?: Product; error?: { code: string; message: string } } {
  const existing = repo.getById(id);
  if (!existing) return { error: { code: "NOT_FOUND", message: `Product "${id}" not found` } };

  if (!VALID_STATUSES.includes(status as ProductStatus)) {
    return { error: { code: "VALIDATION_ERROR", message: `Invalid status "${status}". Valid: ${VALID_STATUSES.join(", ")}` } };
  }

  const allowed = STATUS_TRANSITIONS[existing.status];
  if (!allowed.includes(status as ProductStatus)) {
    return { error: { code: "VALIDATION_ERROR", message: `Cannot transition from "${existing.status}" to "${status}". Allowed: ${allowed.join(", ") || "none"}` } };
  }

  const updated = repo.updateStatus(id, status as ProductStatus);
  return updated ? { data: updated } : { error: { code: "NOT_FOUND", message: `Product "${id}" not found` } };
}