# 事务、幂等、审计 — 正确做法说明

> ⚠️ mock-db 不支持事务。真实项目必须按以下方式做。

## 哪些操作必须使用事务

| 操作 | 错误做法 | 正确做法 |
|------|---------|---------|
| 扣次数 | SELECT → 判断 → UPDATE | 条件 UPDATE（原子） |
| 扣余额 | SELECT → 判断 → UPDATE | 条件 UPDATE + 检查 affected rows |
| 核销 | 先更新状态 → 再记日志 | 事务内：UPDATE + INSERT AuditLog |
| 库存变更 | SELECT → 运算 → UPDATE | UPDATE inventory SET qty = qty - ? WHERE qty >= ? |
| 状态审批 | 先改状态 → 再记日志 | 事务内：UPDATE status + INSERT AuditLog |
| 创建记录 + 审计 | 先 INSERT → 再 INSERT log | 事务内：INSERT record + INSERT audit |
| 幂等请求落库 | 先查 key → 再写结果 | INSERT ON CONFLICT (key) DO NOTHING RETURNING |
| 多表关联写入 | 多个单独 SQL | 一个事务包裹所有写操作 |

## 哪些操作需要幂等

| 场景 | 幂等方式 | 说明 |
|------|---------|------|
| 支付回调 | 数据库唯一约束 key | 同一笔支付只处理一次 |
| 生成任务 | idempotencyKey | 重复提交返回已有结果 |
| 核销提交 | idempotencyKey | 防止重复核销 |
| 签到 | userId + date 唯一约束 | 同一天只签到一次 |
| 重复点击提交 | idempotencyKey | 前端防抖 + 后端幂等双保险 |

## mock-db 不能替代正式数据库

- mock-db 是内存存储，重启后数据全部丢失
- mock-db 不支持事务、并发控制、唯一约束
- mock-db 不能用于真实用户数据、不能上线
- 真实项目必须替换为 PostgreSQL + Prisma/Drizzle

## PostgreSQL 项目应参考

- `postgres-best-practices-wrapper` — PostgreSQL schema、索引、查询、RLS
- `database-consistency-and-transaction` — 事务边界、一致性问题

## 密码存储

```typescript
// ✅ 使用 bcrypt 或 argon2
import bcrypt from "bcrypt";
const hash = await bcrypt.hash(password, 12);
// ❌ 不用 MD5/SHA256/明文
```

## 环境变量

```
# ✅ 密钥只放 .env，不进代码
DATABASE_URL=postgresql://...
JWT_SECRET=随机生成的长字符串
# ❌ 不要硬编码密钥
```
