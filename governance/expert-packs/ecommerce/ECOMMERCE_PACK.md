# Ecommerce Expert Pack v1.0.0
# Codex Factory R5.1

## Status: ACTIVE (Pilot)

The Ecommerce Expert Pack is the first domain-specific capability pack for Codex Factory.
It provides surface templates, risk rules, business invariants, test patterns, engine
recommendations, and benchmark cases for ecommerce projects.

## Domain Scope

### Covered Modules
- **Product Catalog**: Product CRUD, categories, search, filtering
- **Inventory**: Stock tracking, adjustments, audit trail
- **Shopping Cart**: Add/remove items, quantity changes
- **Orders**: Order creation, status flow, total calculation
- **Payment Callbacks**: Idempotent payment processing
- **Admin Management**: Product/inventory/order admin dashboard
- **User Account / Auth**: Roles, permissions, protected endpoints
- **Promotions / Discounts** (optional): Coupon codes, flash sales

### NOT Covered (Non-Claims)
- PCI-DSS compliance certification
- Real payment gateway integration code
- Tax calculation logic
- Shipping/logistics integration
- Multi-currency support
- GDPR/data-privacy compliance
- Production deployment configuration

## Surface Templates

| Template | Surfaces | Risk | Typical Use Case |
|----------|----------|------|------------------|
| ecom-storefront-only | public-web | LOW | Product browsing without transactions |
| ecom-admin-only | admin-web, api-service, database | HIGH | Backend product/inventory management |
| ecom-fullstore | public-web, admin-web, api-service, database, background-worker, docs-release | CRITICAL | Complete ecommerce platform |
| ecom-miniapp-store | miniapp, admin-web, api-service, database, background-worker, docs-release | L_CLASS | Mini-program ecommerce |
| ecom-marketplace-lite | public-web, admin-web, api-service, database, background-worker, docs-release | L_CLASS | Multi-vendor marketplace |

## Risk Rules (8 domain-specific rules)

| Rule | Trigger | Level |
|------|---------|-------|
| ECOM-R001 | price modify/change/update | CRITICAL |
| ECOM-R002 | payment/checkout/wechat_pay/alipay | CRITICAL |
| ECOM-R003 | inventory adjust/change | CRITICAL |
| ECOM-R004 | order create/submit/confirm | HIGH |
| ECOM-R005 | refund/cancel order/payment | CRITICAL |
| ECOM-R006 | discount/coupon/promotion | HIGH |
| ECOM-R007 | user role/permission/admin | CRITICAL |
| ECOM-R008 | product create/add/publish | MEDIUM |

## Business Invariants (12)

| # | Invariant | Severity |
|---|-----------|----------|
| 1 | price_non_negative | CRITICAL |
| 2 | price_not_zero_unless_explicit_free | CRITICAL |
| 3 | inventory_non_negative | CRITICAL |
| 4 | order_total_matches_items | CRITICAL |
| 5 | payment_idempotency_required | CRITICAL |
| 6 | paid_order_cannot_be_modified_without_refund_flow | CRITICAL |
| 7 | cancelled_order_cannot_be_paid | CRITICAL |
| 8 | archived_product_not_sellable | HIGH |
| 9 | user_cannot_modify_price | CRITICAL |
| 10 | admin_required_for_price_change | CRITICAL |
| 11 | stock_delta_must_be_audited | HIGH |
| 12 | refund_amount_cannot_exceed_paid_amount | CRITICAL |

## Activation Keywords

Chinese: 商城, 电商, 商店, 店铺, 商品, 购物, 购物车, 订单, 支付, 退款, 库存, 促销, 优惠券, 折扣, 商品管理, 订单系统, 支付回调, 商品展示, 库存管理

English: ecommerce, shop, store, product catalog, shopping cart, order system, payment callback, checkout, inventory, wechat pay, alipay, refund, discount, coupon

## Integration

Activated packs inject into Foundation RC at these points:
1. Surface Plan — domain surface templates override generic defaults
2. Risk Classifier — domain risk rules supplement generic rules
3. Business Invariant Engine — domain invariants added to invariant spec
4. External Engine Broker — domain engine requirements augment engine plan
5. Automated Gate Detector — domain test requirements supplement test gates
6. Risk Enforcement Gate — domain audit points add human review requirements

## Benchmark Cases (4)

| ID | Scenario | Type | Risk |
|----|----------|------|------|
| ECOM-B1 | Product display page | Runnable | LOW |
| ECOM-B2 | Inventory admin backend | Runnable | HIGH |
| ECOM-B3 | Full store + payments | Design Only | CRITICAL |
| ECOM-B4 | Miniapp store + admin | Design Only | L_CLASS |
