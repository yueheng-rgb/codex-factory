/**
 * In-memory product repository
 */
import type { Product, ProductStatus, PaginatedResult } from "../types/index.js";

const products: Product[] = [
  { id: "p-001", name: "Widget A", description: "A basic widget", price: 9.99, category: "widgets", status: "active", createdAt: "2026-01-01T00:00:00.000Z", updatedAt: "2026-01-01T00:00:00.000Z" },
  { id: "p-002", name: "Widget B", description: "A premium widget", price: 19.99, category: "widgets", status: "active", createdAt: "2026-01-02T00:00:00.000Z", updatedAt: "2026-01-02T00:00:00.000Z" },
  { id: "p-003", name: "Gadget X", description: "An electronic gadget", price: 49.99, category: "electronics", status: "inactive", createdAt: "2026-01-03T00:00:00.000Z", updatedAt: "2026-02-01T00:00:00.000Z" },
];

export function list(params: { page: number; pageSize: number; search?: string; category?: string; status?: string }): PaginatedResult<Product> {
  let filtered = [...products];
  if (params.search) {
    const kw = params.search.toLowerCase();
    filtered = filtered.filter(p => p.name.toLowerCase().includes(kw) || p.description.toLowerCase().includes(kw));
  }
  if (params.category) filtered = filtered.filter(p => p.category === params.category);
  if (params.status) filtered = filtered.filter(p => p.status === params.status);
  filtered.sort((a, b) => b.createdAt.localeCompare(a.createdAt));
  const total = filtered.length;
  const start = (params.page - 1) * params.pageSize;
  return { items: filtered.slice(start, start + params.pageSize), page: params.page, pageSize: params.pageSize, total, totalPages: Math.ceil(total / params.pageSize) };
}

export function getById(id: string): Product | null {
  return products.find(p => p.id === id) || null;
}

export function create(input: { name: string; description: string; price: number; category: string }): Product {
  const product: Product = { id: `p-${Date.now()}`, ...input, status: "active", createdAt: new Date().toISOString(), updatedAt: new Date().toISOString() };
  products.push(product);
  return product;
}

export function update(id: string, input: { name?: string; description?: string; price?: number; category?: string }): Product | null {
  const idx = products.findIndex(p => p.id === id);
  if (idx === -1) return null;
  products[idx] = { ...products[idx], ...input, updatedAt: new Date().toISOString() };
  return products[idx];
}

export function updateStatus(id: string, status: ProductStatus): Product | null {
  const idx = products.findIndex(p => p.id === id);
  if (idx === -1) return null;
  products[idx] = { ...products[idx], status, updatedAt: new Date().toISOString() };
  return products[idx];
}

export function remove(id: string): boolean {
  const idx = products.findIndex(p => p.id === id);
  if (idx === -1) return false;
  products.splice(idx, 1);
  return true;
}