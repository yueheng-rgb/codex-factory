import { Product, UserRole } from "../types.js";
import { products, generateId } from "../db/store.js";

// Ecommerce Pack Invariants enforced:
//   price_non_negative, price_not_zero_unless_explicit_free,
//   archived_product_not_sellable,
//   user_cannot_modify_price, admin_required_for_price_change

export interface CreateProductInput {
  name: string;
  price: number;
  isFree?: boolean;
  inventory?: number;
}

export interface UpdateProductInput {
  name?: string;
  price?: number;
  isFree?: boolean;
  inventory?: number;
  status?: string;
}

export function createProduct(input: CreateProductInput, userId: string): Product | { error: string } {
  if (!input.name || input.name.trim().length === 0) {
    return { error: "INVALID_NAME: Product name is required" };
  }
  // INVARIANT: price_non_negative
  if (input.price < 0) {
    return { error: "PRICE_NEGATIVE: Product price must be non-negative" };
  }
  // INVARIANT: price_not_zero_unless_explicit_free
  if (input.price === 0 && !input.isFree) {
    return { error: "PRICE_ZERO_NO_FREE: Zero price requires explicit free indicator (isFree: true)" };
  }
  const product: Product = {
    id: generateId("prod"),
    name: input.name.trim(),
    price: input.price,
    isFree: input.isFree ?? (input.price === 0),
    inventory: input.inventory ?? 0,
    status: "DRAFT",
    createdBy: userId,
    createdAt: new Date().toISOString(),
    updatedAt: new Date().toISOString()
  };
  products.set(product.id, product);
  return product;
}

export function getProduct(id: string): Product | null {
  return products.get(id) ?? null;
}

export function listProducts(page = 1, pageSize = 20): { items: Product[]; total: number; page: number; pageSize: number } {
  const all = Array.from(products.values());
  const start = (page - 1) * pageSize;
  return {
    items: all.slice(start, start + pageSize),
    total: all.length,
    page,
    pageSize
  };
}

export function updateProduct(
  id: string, input: UpdateProductInput, userId: string, userRole: UserRole
): Product | { error: string } {
  const product = products.get(id);
  if (!product) return { error: "NOT_FOUND: Product not found" };

  // INVARIANT: archived_product_not_sellable (archived products cannot be modified)
  if (product.status === "ARCHIVED") {
    return { error: "ARCHIVED_NOT_MUTABLE: Archived products cannot be modified" };
  }

  // INVARIANT: price changes
  if (input.price !== undefined) {
    // INVARIANT: user_cannot_modify_price
    if (userRole !== "ADMIN") {
      return { error: "FORBIDDEN_PRICE_CHANGE: Non-admin users cannot modify product price" };
    }
    // INVARIANT: price_non_negative
    if (input.price < 0) {
      return { error: "PRICE_NEGATIVE: Product price must be non-negative" };
    }
    // INVARIANT: price_not_zero_unless_explicit_free
    if (input.price === 0 && !(input.isFree ?? product.isFree)) {
      return { error: "PRICE_ZERO_NO_FREE: Zero price requires explicit free indicator" };
    }
    product.price = input.price;
  }

  if (input.name !== undefined) {
    if (input.name.trim().length === 0) {
      return { error: "INVALID_NAME: Product name is required" };
    }
    product.name = input.name.trim();
  }
  if (input.isFree !== undefined) product.isFree = input.isFree;
  if (input.inventory !== undefined) product.inventory = input.inventory;
  if (input.status !== undefined) {
    const validStatuses = ["DRAFT", "ACTIVE", "ARCHIVED"];
    if (!validStatuses.includes(input.status)) {
      return { error: "INVALID_STATUS: Status must be DRAFT, ACTIVE, or ARCHIVED" };
    }
    product.status = input.status as Product["status"];
  }
  product.updatedAt = new Date().toISOString();
  products.set(id, product);
  return product;
}
