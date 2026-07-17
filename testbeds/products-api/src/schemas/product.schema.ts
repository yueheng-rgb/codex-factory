/**
 * Product schema validation ¡ª rejects unknown fields
 */
import type { ProductInput, ProductUpdate } from "../types/index.js";

const ALLOWED_CREATE_FIELDS = ["name", "description", "price", "category"];
const ALLOWED_UPDATE_FIELDS = ["name", "description", "price", "category"];

export interface ValidationResult {
  valid: boolean;
  errors: Array<{ field: string; message: string }>;
}

export function validateProductInput(body: Record<string, unknown>): ValidationResult {
  const errors: Array<{ field: string; message: string }> = [];

  // Reject unknown fields
  for (const key of Object.keys(body)) {
    if (!ALLOWED_CREATE_FIELDS.includes(key)) {
      errors.push({ field: key, message: `Unknown field: "${key}" is not allowed` });
    }
  }
  if (errors.length > 0) return { valid: false, errors };

  // Required fields
  if (!body.name || typeof body.name !== "string" || body.name.trim().length < 2) {
    errors.push({ field: "name", message: "name is required (min 2 chars)" });
  }
  if (!body.description || typeof body.description !== "string" || body.description.trim().length < 2) {
    errors.push({ field: "description", message: "description is required (min 2 chars)" });
  }
  if (body.price === undefined || body.price === null || typeof body.price !== "number" || body.price < 0) {
    errors.push({ field: "price", message: "price is required and must be >= 0" });
  }
  if (!body.category || typeof body.category !== "string" || body.category.trim().length < 2) {
    errors.push({ field: "category", message: "category is required (min 2 chars)" });
  }

  return { valid: errors.length === 0, errors };
}

export function validateProductUpdate(body: Record<string, unknown>): ValidationResult {
  const errors: Array<{ field: string; message: string }> = [];

  // Reject unknown fields
  for (const key of Object.keys(body)) {
    if (!ALLOWED_UPDATE_FIELDS.includes(key)) {
      errors.push({ field: key, message: `Unknown field: "${key}" is not allowed` });
    }
  }
  if (errors.length > 0) return { valid: false, errors };

  if (body.name !== undefined && (typeof body.name !== "string" || body.name.trim().length < 2)) {
    errors.push({ field: "name", message: "name must be >= 2 chars" });
  }
  if (body.description !== undefined && (typeof body.description !== "string" || body.description.trim().length < 2)) {
    errors.push({ field: "description", message: "description must be >= 2 chars" });
  }
  if (body.price !== undefined && (typeof body.price !== "number" || body.price < 0)) {
    errors.push({ field: "price", message: "price must be >= 0" });
  }
  if (body.category !== undefined && (typeof body.category !== "string" || body.category.trim().length < 2)) {
    errors.push({ field: "category", message: "category must be >= 2 chars" });
  }

  return { valid: errors.length === 0, errors };
}