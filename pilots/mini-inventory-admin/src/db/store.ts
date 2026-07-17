import type { Item, ItemStatus } from "../types.js";

let items: Map<string, Item> = new Map();
let idCounter = 0;

export function generateId(): string {
  return `ITEM-${String(++idCounter).padStart(4, "0")}`;
}

export function getAll(): Item[] {
  return Array.from(items.values());
}

export function getById(id: string): Item | undefined {
  return items.get(id);
}

export function insert(item: Item): void {
  items.set(item.id, item);
}

export function update(id: string, patch: Partial<Item>): Item | undefined {
  const existing = items.get(id);
  if (!existing) return undefined;
  const updated = { ...existing, ...patch, id: existing.id, updatedAt: new Date().toISOString() };
  items.set(id, updated);
  return updated;
}

export function remove(id: string): boolean {
  return items.delete(id);
}

export function reset(): void {
  items = new Map();
  idCounter = 0;
}
