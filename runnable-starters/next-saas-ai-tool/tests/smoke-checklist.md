# Smoke Checklist — next-saas-ai-tool

> `npm run dev` 后逐项检查。

## 页面
- [ ] `/` 落地页可见
- [ ] `/login` 可打开
- [ ] 登录失败显示错误
- [ ] `/dashboard` 显示额度卡片
- [ ] `/tool` 可打开
- [ ] 空主题点击生成 → 不提交（前端校验）
- [ ] 输入主题点击生成 → 按钮变"生成中..."
- [ ] 生成成功 → 显示结果
- [ ] 剩余次数减少
- [ ] 重复点击不重复提交
- [ ] `/history` 可见生成记录
- [ ] `/history` 空状态显示
- [ ] `/account` 显示额度信息

## API
- [ ] `GET /api/health` → `{ok:true}`
- [ ] `POST /api/auth/login` 正确凭证 → token
- [ ] `POST /api/auth/login` 错误 → UNAUTHORIZED
- [ ] `POST /api/generate` 无 topic → VALIDATION_ERROR
- [ ] `POST /api/generate` 正确 → 返回结果 + remaining
- [ ] `GET /api/usage` → total/used
- [ ] `GET /api/history` → 分页结构
- [ ] API 错误格式统一

## 安全
- [ ] 前端代码无 API Key
- [ ] 前端代码无 hardcoded secret
- [ ] `.env.example` 无真实密钥

## 构建
- [ ] `npm run typecheck` 通过
- [ ] `npm run build` 通过