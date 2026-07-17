# AGENTS.md — node-api-postgres Starter

## 这是什么

`node-api-postgres` 是一个 Node.js + TypeScript + Fastify 后端 API 骨架。
用于 api-service / backend-service / miniapp-backend / app-backend 类型项目。

## 适合什么项目

- 小程序后端 API
- App 后端接口服务
- 纯 API 服务（HEADless backend）
- PostgreSQL 业务服务
- 需要统一 API 格式 + 权限 + 审计的项目

## 不适合什么项目

- 纯官网/展示页（切换到 `vite-react-content-site`）
- 管理后台全栈（切换到 `next-fullstack-admin`）
- SaaS/AI 工具（切换到 `next-saas-ai-tool`）
- 复杂微服务平台 / 实时通信 / 大文件处理

## 使用前规则

1. **先读取 Codex_App_Factory**：修改此 starter 前，先读取 `C:\Codex_App_Factory`
2. **先走 Project Expertise Flow**：确认项目类型确实是 api-service
3. **第一版只做最小闭环**：mock-db + mock auth + 核心 CRUD
4. **不要马上接真实数据库**：mock-db 先跑通，确认需求后再升级
5. **不要默认加 Redis/队列/微服务**：除非项目体量达到 L/XL
6. **真实项目必须替换**：mock-db → PostgreSQL, mock auth → JWT, mock log → 结构化日志
7. **所有权限必须服务端校验**：中间件级检查，不依赖客户端
8. **所有写操作必须服务端校验输入**：不信任客户端数据
9. **API 格式统一**：`{ ok: true, data }` / `{ ok: false, error: { code, message } }`
10. **mock-db 不是正式数据库**：内存存储，重启丢失
