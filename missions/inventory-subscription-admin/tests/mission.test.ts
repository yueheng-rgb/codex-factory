// Mission Test Suite — Inventory Subscription Admin
// Covers: Admin (5 invariants), Ecommerce (5 invariants), SaaS (4 invariants) + 10 negative controls
import { describe, it, expect, beforeEach } from "vitest";
import { reset, products, auditLog, users, tenants } from "../src/db/store.js";
import * as auth from "../src/services/auth.service.js";
import * as product from "../src/services/product.service.js";
import * as tenantSvc from "../src/services/tenant.service.js";
import { ERR } from "../src/types/index.js";

beforeEach(() => { reset(); });

// ======================== ADMIN PACK (5 invariants) ========================
describe("Admin: admin_required_for_admin_routes", () => {
  it("rejects null user", () => { const r = auth.authenticate(null); expect("error" in r && r.error===ERR.UNAUTHORIZED).toBe(true); });
  it("rejects invalid user", () => { const r = auth.authenticate("bad"); expect("error" in r && r.error===ERR.UNAUTHORIZED).toBe(true); });
  it("allows valid admin", () => { const r = auth.authenticate("adm_1"); expect("error" in r).toBe(false); });
});

describe("Admin: role_permission_must_be_enforced", () => {
  it("allows correct perm", () => { const r = auth.checkPerm("adm_1","product:read"); expect("error" in r).toBe(false); });
  it("rejects missing perm", () => { const r = auth.checkPerm("vw_1","product:write"); expect("error" in r && r.error===ERR.FORBIDDEN).toBe(true); });
  it("SUPER_ADMIN passes all", () => { const r = auth.checkPerm("su_1","any:perm"); expect("error" in r).toBe(false); });
});

describe("Admin: ordinary_admin_cannot_escalate_role", () => {
  it("blocks ADMIN to SUPER_ADMIN", () => { const r = auth.changeRole("adm_1","adm_1","SUPER_ADMIN"); expect("error" in r && r.error===ERR.ROLE_ESCALATION).toBe(true); });
  it("blocks OPERATOR to ADMIN", () => { const r = auth.changeRole("op_1","vw_1","ADMIN"); expect("error" in r && r.error===ERR.ROLE_ESCALATION).toBe(true); });
  it("allows SUPER_ADMIN escalation", () => { const r = auth.changeRole("su_1","vw_1","ADMIN"); expect("error" in r).toBe(false); });
});

describe("Admin: destructive_action_requires_confirmation", () => {
  it("rejects delete without token", () => {
    product.createProduct("adm_1", {name:"X",price:10,inventory:5,tenantId:"t1"});
    const p = [...products.values()][0];
    const r = product.changeStatus("adm_1",p.id,"DELETED");
    expect("error" in r && r.error===ERR.CONFIRMATION).toBe(true);
  });
  it("allows delete with token", () => {
    product.createProduct("adm_1", {name:"Y",price:10,inventory:5,tenantId:"t1"});
    const p = [...products.values()][0];
    const r = product.changeStatus("adm_1",p.id,"DELETED",`confirm-delete-${p.id}`);
    expect("error" in r).toBe(false);
  });
});

describe("Admin: audit_log_required_for_sensitive_actions", () => {
  it("creates audit on product create", () => {
    product.createProduct("adm_1", {name:"A",price:10,inventory:1,tenantId:"t1"});
    expect(auditLog.some(e=>e.action==="PRODUCT_CREATED")).toBe(true);
  });
  it("creates audit on role change", () => {
    auth.changeRole("su_1","vw_1","OPERATOR");
    expect(auditLog.some(e=>e.action==="ROLE_CHANGED")).toBe(true);
  });
});

// ======================== ECOMMERCE PACK (5 invariants) ========================
describe("Ecommerce: price_non_negative", () => {
  it("rejects negative price", () => { const r = product.createProduct("adm_1",{name:"X",price:-1,inventory:1,tenantId:"t1"}); expect("error" in r && r.error===ERR.PRICE_NEGATIVE).toBe(true); });
  it("allows zero price", () => { const r = product.createProduct("adm_1",{name:"Free",price:0,inventory:1,tenantId:"t1"}); expect("error" in r).toBe(false); });
  it("rejects negative price update", () => {
    product.createProduct("adm_1",{name:"X",price:10,inventory:1,tenantId:"t1"});
    const r = product.updatePrice("adm_1",[...products.values()][0].id,-5);
    expect("error" in r && r.error===ERR.PRICE_NEGATIVE).toBe(true);
  });
});

describe("Ecommerce: inventory_non_negative", () => {
  it("allows positive inventory", () => { const r = product.createProduct("adm_1",{name:"X",price:10,inventory:100,tenantId:"t1"}); expect("error" in r).toBe(false); });
  it("rejects negative inventory create", () => { const r = product.createProduct("adm_1",{name:"X",price:10,inventory:-1,tenantId:"t1"}); expect("error" in r && r.error===ERR.INVENTORY_NEGATIVE).toBe(true); });
});

describe("Ecommerce: stock_delta_must_be_audited", () => {
  it("records inventory adjustments", () => {
    product.createProduct("adm_1",{name:"X",price:10,inventory:10,tenantId:"t1"});
    const pid = [...products.values()][0].id;
    product.adjustInventory("adm_1",pid,-3,"sale");
    expect(auditLog.some(e=>e.action==="INVENTORY_ADJUSTED")).toBe(true);
  });
});

describe("Ecommerce: archived_product_not_sellable", () => {
  it("rejects inventory adjust on archived", () => {
    product.createProduct("adm_1",{name:"A",price:10,inventory:5,tenantId:"t1"});
    const p = [...products.values()][0];
    product.changeStatus('su_1',p.id,'ACTIVE'); product.changeStatus('su_1',p.id,'ARCHIVED');
    const r = product.adjustInventory("adm_1",p.id,1,"restock");
    expect("error" in r && r.error===ERR.STALE_DATA).toBe(true);
  });
});

describe("Ecommerce: admin_required_for_price_change", () => {
  it("rejects operator price change", () => {
    product.createProduct("adm_1",{name:"X",price:10,inventory:1,tenantId:"t1"});
    const r = product.updatePrice("op_1",[...products.values()][0].id,20);
    expect("error" in r && r.error===ERR.PROTECTED_FIELD).toBe(true);
  });
});

// ======================== SAAS PACK (4 invariants) ========================
describe("SaaS: tenant_data_isolation", () => {
  it("rejects cross-tenant product create", () => {
    const r = product.createProduct("adm_1",{name:"X",price:10,inventory:1,tenantId:"t2"});
    expect("error" in r && r.error===ERR.TENANT_ISOLATION).toBe(true);
  });
  it("rejects viewing other tenant data by non-admin", () => {
    const r = tenantSvc.getTenant("adm_1","t2");
    expect("error" in r && r.error===ERR.TENANT_ISOLATION).toBe(true);
  });
});

describe("SaaS: subscription_status_controls_access", () => {
  it("blocks expired tenant", () => {
    tenants.set("t1",{...tenants.get("t1")!, subscriptionStatus:"EXPIRED"});
    const r = auth.authenticate("adm_1");
    expect("error" in r && r.error===ERR.SUBSCRIPTION_EXPIRED).toBe(true);
  });
});

describe("SaaS: usage_quota_non_negative", () => {
  it("rejects negative quota", () => { const r = tenantSvc.checkQuota("t1",-1); expect("error" in r && r.error===ERR.QUOTA_EXCEEDED).toBe(true); });
  it("allows normal quota", () => { const r = tenantSvc.checkQuota("t1",100); expect("error" in r).toBe(false); });
});

describe("SaaS: quota_decrement_must_be_atomic", () => {
  it("blocks exceeding quota", () => { const r = tenantSvc.checkQuota("t1",99999); expect("error" in r && r.error===ERR.QUOTA_EXCEEDED).toBe(true); });
});

// ======================== NEGATIVE CONTROLS (10) ========================
describe("NC1: Unauthenticated admin route", () => {
  it("BLOCKED", () => { const r = auth.authenticate(null); expect("error" in r).toBe(true); });
});
describe("NC2: Viewer writes product", () => {
  it("BLOCKED", () => { const r = product.createProduct("vw_1",{name:"X",price:1,inventory:1,tenantId:"t1"}); expect("error" in r && r.error===ERR.FORBIDDEN).toBe(true); });
});
describe("NC3: Operator escalates self", () => {
  it("BLOCKED", () => { const r = auth.changeRole("op_1","op_1","SUPER_ADMIN"); expect("error" in r && r.error===ERR.ROLE_ESCALATION).toBe(true); });
});
describe("NC4: Delete without confirmation", () => {
  it("BLOCKED", () => {
    product.createProduct("adm_1",{name:"X",price:1,inventory:1,tenantId:"t1"});
    const r = product.changeStatus("adm_1",[...products.values()][0].id,"DELETED");
    expect("error" in r && r.error===ERR.CONFIRMATION).toBe(true);
  });
});
describe("NC5: Negative inventory adjustment", () => {
  it("BLOCKED", () => {
    product.createProduct("adm_1",{name:"X",price:1,inventory:5,tenantId:"t1"});
    const r = product.adjustInventory("adm_1",[...products.values()][0].id,-10,"theft");
    expect("error" in r && r.error===ERR.INVENTORY_NEGATIVE).toBe(true);
  });
});
describe("NC6: Cross-tenant inventory", () => {
  it("BLOCKED", () => {
    product.createProduct("adm_1",{name:"X",price:1,inventory:5,tenantId:"t1"});
    const r = product.createProduct("adm_1",{name:"Y",price:1,inventory:5,tenantId:"t2"});
    expect("error" in r && r.error===ERR.TENANT_ISOLATION).toBe(true);
  });
});
describe("NC7: Expired subscription blocks access", () => {
  it("BLOCKED", () => {
    tenants.set("t1",{...tenants.get("t1")!, subscriptionStatus:"EXPIRED"});
    const r = auth.authenticate("adm_1");
    expect("error" in r && r.error===ERR.SUBSCRIPTION_EXPIRED).toBe(true);
  });
});
describe("NC8: Quota exceeded", () => {
  it("BLOCKED", () => { const r = tenantSvc.checkQuota("t1",99999); expect("error" in r && r.error===ERR.QUOTA_EXCEEDED).toBe(true); });
});
describe("NC9: Operator price change", () => {
  it("BLOCKED", () => {
    product.createProduct("adm_1",{name:"X",price:10,inventory:1,tenantId:"t1"});
    const r = product.updatePrice("op_1",[...products.values()][0].id,5);
    expect("error" in r && r.error===ERR.PROTECTED_FIELD).toBe(true);
  });
});
describe("NC10: Invalid status transition", () => {
  it("BLOCKED", () => {
    product.createProduct("adm_1",{name:"X",price:1,inventory:1,tenantId:"t1"});
    const p = [...products.values()][0];
    const r = product.changeStatus("adm_1",p.id,"ARCHIVED");
    expect("error" in r && r.error===ERR.INVALID_STATUS).toBe(true);
  });
});

// Edge cases
describe("Edge: Status transitions", () => {
  it("DRAFT -> ACTIVE -> SUSPENDED -> ACTIVE -> ARCHIVED", () => {
    product.createProduct("adm_1",{name:"Path",price:1,inventory:1,tenantId:"t1"});
    const p = [...products.values()][0];
    expect("error" in product.changeStatus("adm_1",p.id,"ACTIVE")).toBe(false);
    expect("error" in product.changeStatus("adm_1",p.id,"SUSPENDED")).toBe(false);
    expect("error" in product.changeStatus("adm_1",p.id,"ACTIVE")).toBe(false);
    expect("error" in product.changeStatus("adm_1",p.id,"ARCHIVED")).toBe(false);
  });
});

