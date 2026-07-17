# Database Schema Design

## 用途
设计专业的数据库 Schema：实体、审计字段、索引、唯一约束、事务边界。
特别关注：次数/余额/库存/额度的安全操作。

## 使用场景
- 设计数据表时
- 涉及金额、次数、库存等敏感操作时

## 每张表的基础字段
```sql
CREATE TABLE xxx (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  -- 业务字段
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  deleted_at TIMESTAMPTZ           -- 软删除
);
```

## 四类表的区分

| 表类型 | 用途 | 特点 | 示例 |
|--------|------|------|------|
| **当前状态表** | 记录实体的当前状态 | 会被 UPDATE | users, products, user_quota |
| **事件记录表** | 记录已发生的事件 | 只 INSERT，不 UPDATE | generation_history, orders |
| **修正记录表** | 记录对状态的手动修正 | 只 INSERT | quota_adjustments |
| **审计日志表** | 记录敏感操作 | 只 INSERT，用于追溯 | audit_logs, api_logs |

## 安全操作模式

### 次数/余额/库存/额度操作（必须防负数 + 防重复）

```sql
-- ❌ 错误做法：先读再写（有竞态条件）
SELECT quota_used FROM users WHERE id = ?;
-- 如果够用
UPDATE users SET quota_used = quota_used + 1 WHERE id = ?;

-- ✅ 正确做法：用条件 UPDATE + 检查 affected rows
UPDATE users
SET quota_used = quota_used + 1
WHERE id = ? AND quota_used + 1 <= quota_total;
-- 如果 affected rows = 0 → 额度不足

-- ✅ 或者用事务 + 行级锁
BEGIN;
SELECT quota_used FROM users WHERE id = ? FOR UPDATE;
-- 判断
UPDATE users SET quota_used = quota_used + 1 WHERE id = ?;
COMMIT;
```

### 唯一约束（防止重复）
```sql
-- 用户名唯一
ALTER TABLE users ADD CONSTRAINT uq_users_username UNIQUE (username);

-- 用户 + 类型唯一（每人每种记录只能有一条）
ALTER TABLE user_settings ADD CONSTRAINT uq_user_type UNIQUE (user_id, type);
```

### 索引原则
- 所有外键加索引
- 频繁查询的字段加索引
- 分页排序的字段加索引
- 唯一约束自带索引，不用额外加

## 常见错误
- ❌ 表没有 created_at / updated_at
- ❌ 先 SELECT 再 UPDATE（竞态条件）
- ❌ 没有唯一约束（重复数据）
- ❌ 涉及金额用 FLOAT（用 DECIMAL 或 INTEGER 存分）
- ❌ 软删除的字段不加索引
- ❌ 状态用字符串不用枚举

## 输出格式
```
## 数据库设计

### 表列表
1. [表名] — [说明]
   - 字段列表
   - 索引
   - 唯一约束

### 关系图
[表A] 1:N [表B]
[表B] M:N [表C]

### 安全操作
- [操作]：[保护方式]
```
