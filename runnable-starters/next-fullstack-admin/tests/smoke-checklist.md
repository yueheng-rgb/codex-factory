# Smoke Checklist — next-fullstack-admin

> 手动验收清单。运行 `npm run dev` 后逐项检查。
> 以后安装 Playwright 后可升级为自动测试。

## 基础检查

- [ ] `npm run dev` 正常启动，http://localhost:3000
- [ ] `npm run typecheck` 无错误
- [ ] `npm run build` 无错误

## 页面

- [ ] `/` 重定向到 `/dashboard`
- [ ] `/login` 能打开，显示登录表单
- [ ] 空用户名提交 → 显示"请输入用户名"
- [ ] 空密码提交 → 显示"请输入密码"
- [ ] 错误密码 → 显示"用户名或密码错误"
- [ ] admin/admin123 → 登录成功，跳转到 `/dashboard`
- [ ] `/dashboard` 显示统计卡片
- [ ] `/records` 显示记录列表
- [ ] 搜索框输入关键词 → 列表过滤
- [ ] 状态下拉选择 → 列表过滤
- [ ] 清除按钮 → 重置搜索和筛选
- [ ] 点击记录标题 → 进入详情页
- [ ] 详情页显示标题、状态、描述、元信息
- [ ] 修改状态按钮 → 打开确认弹窗
- [ ] 确认修改 → 状态更新
- [ ] 直接访问 `/records/nonexistent` → 显示"记录不存在"
- [ ] `/settings/users` 显示占位内容

## API

- [ ] `GET /api/health` → `{ "ok": true, "data": { "status": "ok" } }`
- [ ] `POST /api/auth/login` 正确凭证 → 返回 token
- [ ] `POST /api/auth/login` 错误凭证 → 返回 `UNAUTHORIZED`
- [ ] `GET /api/records?page=1&limit=20` → 返回分页结构
- [ ] `GET /api/records?search=xxx` → 筛选结果
- [ ] `GET /api/records?status=pending` → 筛选结果
- [ ] `GET /api/records/rec-001` → 返回记录详情
- [ ] `GET /api/records/nonexistent` → `NOT_FOUND`
- [ ] `PATCH /api/records/rec-001` → 状态更新成功
- [ ] API 错误格式统一 `{ ok: false, error: { code, message } }`

## 响应式

- [ ] 375px 下无横向溢出
- [ ] 768px 下布局正常

## 控制台

- [ ] 浏览器控制台无红色错误
