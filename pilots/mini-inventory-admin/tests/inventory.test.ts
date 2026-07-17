// Mini Inventory Admin — API Tests (Business Invariant Coverage)
import { describe, it, expect, beforeEach } from "vitest";
import * as svc from "../src/services/inventory.service.js";
import { reset } from "../src/db/store.js";

beforeEach(() => reset());

describe("CRUD operations", () => {
  it("creates an item successfully", () => {
    const r = svc.createItem({ name: "Widget", price: 9.99, inventory: 100, category: "tools" });
    expect(r.data).toBeDefined();
    expect(r.data!.name).toBe("Widget");
    expect(r.data!.price).toBe(9.99);
    expect(r.data!.inventory).toBe(100);
    expect(r.data!.status).toBe("DRAFT");
  });

  it("lists items with pagination", () => {
    svc.createItem({ name: "A", price: 1, inventory: 10 });
    svc.createItem({ name: "B", price: 2, inventory: 20 });
    const list = svc.listItems({ page: 1, pageSize: 10 });
    expect(list.items.length).toBe(2);
    expect(list.total).toBe(2);
  });

  it("gets item by id", () => {
    const created = svc.createItem({ name: "X", price: 5, inventory: 0 });
    const item = svc.getItem(created.data!.id);
    expect(item).toBeDefined();
    expect(item!.name).toBe("X");
  });

  it("returns 404-style error for missing item", () => {
    const r = svc.updateItem("ITEM-9999", { name: "Nope" });
    expect(r.error).toBeDefined();
    expect(r.error!.code).toBe("NOT_FOUND");
  });

  it("updates an item", () => {
    const created = svc.createItem({ name: "Old", price: 10, inventory: 5 });
    const updated = svc.updateItem(created.data!.id, { name: "New", price: 15 });
    expect(updated.data!.name).toBe("New");
    expect(updated.data!.price).toBe(15);
  });
});

describe("Validation", () => {
  it("rejects empty name", () => {
    const r = svc.createItem({ name: "", price: 10 });
    expect(r.error).toBeDefined();
    expect(r.error!.code).toBe("VALIDATION_ERROR");
  });

  it("rejects unknown fields gracefully (ignores them)", () => {
    const r = svc.createItem({ name: "Item", price: 5, inventory: 0, unknownField: "hack" });
    expect(r.data).toBeDefined();
    expect((r.data as any).unknownField).toBeUndefined();
  });
});

describe("Price invariant: price_non_negative", () => {
  it("rejects negative price", () => {
    const r = svc.createItem({ name: "Bad", price: -1 });
    expect(r.error).toBeDefined();
    expect(r.error!.message).toContain("price_non_negative");
  });

  it("rejects negative price on update", () => {
    const created = svc.createItem({ name: "Item", price: 10 });
    const r = svc.updateItem(created.data!.id, { price: -5 });
    expect(r.error).toBeDefined();
    expect(r.error!.message).toContain("price_non_negative");
  });
});

describe("Price invariant: price_not_zero_unless_explicit_free", () => {
  it("rejects zero price without explicitFree", () => {
    const r = svc.createItem({ name: "Free", price: 0 });
    expect(r.error).toBeDefined();
    expect(r.error!.message).toContain("explicitFree");
  });

  it("allows zero price with explicitFree", () => {
    const r = svc.createItem({ name: "Free", price: 0, explicitFree: true });
    expect(r.data).toBeDefined();
    expect(r.data!.price).toBe(0);
  });
});

describe("Inventory invariant: inventory_non_negative", () => {
  it("rejects negative inventory on create", () => {
    const r = svc.createItem({ name: "Item", price: 5, inventory: -10 });
    expect(r.error).toBeDefined();
    expect(r.error!.message).toContain("inventory_non_negative");
  });

  it("rejects negative inventory on update", () => {
    const created = svc.createItem({ name: "Item", price: 5, inventory: 5 });
    const r = svc.updateItem(created.data!.id, { inventory: -1 });
    expect(r.error).toBeDefined();
    expect(r.error!.message).toContain("inventory_non_negative");
  });

  it("rejects inventory adjustment below zero", () => {
    const created = svc.createItem({ name: "Item", price: 5, inventory: 3 });
    const r = svc.adjustInventory(created.data!.id, -10);
    expect(r.error).toBeDefined();
    expect(r.error!.message).toContain("inventory_non_negative");
  });

  it("allows valid inventory adjustment", () => {
    const created = svc.createItem({ name: "Item", price: 5, inventory: 10 });
    const r = svc.adjustInventory(created.data!.id, 5);
    expect(r.data!.inventory).toBe(15);
  });
});

describe("Status transition invariant: status_transition_allowed", () => {
  it("allows DRAFT to ACTIVE", () => {
    const created = svc.createItem({ name: "Item", price: 5 });
    const r = svc.updateItemStatus(created.data!.id, "ACTIVE");
    expect(r.data!.status).toBe("ACTIVE");
  });

  it("rejects invalid transition ARCHIVED to ACTIVE", () => {
    const created = svc.createItem({ name: "Item", price: 5 });
    svc.updateItemStatus(created.data!.id, "ARCHIVED");
    const r = svc.updateItemStatus(created.data!.id, "ACTIVE");
    expect(r.error).toBeDefined();
    expect(r.error!.message).toContain("status_transition_allowed");
  });
});

describe("Archived entity invariant: archived_entity_not_mutable", () => {
  it("rejects update on archived item", () => {
    const created = svc.createItem({ name: "Item", price: 5 });
    svc.updateItemStatus(created.data!.id, "ARCHIVED");
    const r = svc.updateItem(created.data!.id, { name: "Changed" });
    expect(r.error).toBeDefined();
    expect(r.error!.message).toContain("archived_entity_not_mutable");
  });

  it("rejects inventory adjustment on archived item", () => {
    const created = svc.createItem({ name: "Item", price: 5, inventory: 10 });
    svc.updateItemStatus(created.data!.id, "ARCHIVED");
    const r = svc.adjustInventory(created.data!.id, 1);
    expect(r.error).toBeDefined();
    expect(r.error!.message).toContain("archived_entity_not_mutable");
  });
});

describe("Protected fields invariant: user_cannot_modify_protected_fields", () => {
  it("rejects setting protected field id", () => {
    const r = svc.createItem({ name: "Item", price: 5, id: "hacked-id" });
    expect(r.error).toBeDefined();
    expect(r.error!.message).toContain("user_cannot_modify_protected_fields");
  });

  it("rejects setting protected field createdAt", () => {
    const r = svc.createItem({ name: "Item", price: 5, createdAt: "2020-01-01" });
    expect(r.error).toBeDefined();
    expect(r.error!.message).toContain("user_cannot_modify_protected_fields");
  });
});

describe("Destructive action: hard delete blocked", () => {
  it("rejects hard delete", () => {
    const created = svc.createItem({ name: "Item", price: 5 });
    const r = svc.deleteItem(created.data!.id);
    expect(r.error).toBeDefined();
    expect(r.error!.message).toContain("destructive_action_requires_confirmation");
  });
});
