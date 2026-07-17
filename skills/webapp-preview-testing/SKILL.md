# WebApp Preview & Testing

## 用途
确保每个 Web 项目都能本地运行和预览。
至少设计最小 smoke test，验证核心按钮、表单、页面跳转。

## 使用场景
- Web 项目开发完成后
- 需要验证功能是否正常时

## 本地运行/预览要求

### 每个项目必须有
- [ ] 明确的启动命令（一条命令）
- [ ] README 中写清楚如何运行
- [ ] .env.example（环境变量模板）
- [ ] 不需要特殊配置就能启动

### 标准启动流程
```bash
# 所有项目都应支持
npm install
cp .env.example .env   # 可选：修改配置
npm run dev             # 启动开发服务器
```

## 最小 Smoke Test

### 必须验证的核心路径
1. **页面能打开** — 无 404、无白屏、无 JS 报错
2. **核心按钮可点击** — 主 CTA、提交按钮有响应
3. **表单可提交** — 提交后有反馈（成功/失败）
4. **页面跳转正常** — 链接和导航能跳转且不丢参数
5. **数据能加载** — 列表/详情页能正常展示数据

### Smoke Test 检查清单
```
□ 首页打开无报错
□ 响应式布局正确（375px / 768px / 1440px）
□ 核心 CTA 按钮可点击
□ 登录功能（如果有）：
  □ 登录页可打开
  □ 输入错误密码有错误提示
  □ 输入正确密码能登录
  □ 登录后跳转正确
□ 列表功能（如果有）：
  □ 列表有数据时正常展示
  □ 空列表有 empty 状态
  □ 分页能正常翻页
  □ 搜索能正常筛选
□ 表单功能（如果有）：
  □ 必填校验有提示
  □ 提交成功有反馈
  □ 提交失败有反馈
  □ 重复提交被阻止
□ 权限（如果有）：
  □ 无权限时显示 403 或提示
  □ 无权限时不显示不该有的按钮
```

## Playwright 测试（推荐）

### 最小测试文件
```typescript
// tests/smoke.spec.ts
import { test, expect } from '@playwright/test';

test('首页正常加载', async ({ page }) => {
  await page.goto('/');
  await expect(page).toHaveTitle(/XX系统/);
  // 无控制台报错（可选）
});

test('登录流程', async ({ page }) => {
  await page.goto('/login');
  await page.fill('[name="username"]', 'admin');
  await page.fill('[name="password"]', 'wrong');
  await page.click('button[type="submit"]');
  await expect(page.locator('.error')).toBeVisible();
  
  await page.fill('[name="password"]', 'correct');
  await page.click('button[type="submit"]');
  await expect(page).toHaveURL('/dashboard');
});
```

## 常见错误
- ❌ 没有 .env.example
- ❌ 启动命令不写在 README 里
- ❌ 依赖硬编码的本地路径
- ❌ 只测了 Chrome 页面没测移动端
- ❌ 完全不测试，依赖"看起来能用"

## 输出格式
```
## 测试验证报告

### 运行方式
```bash
npm install
npm run dev
```

### Smoke Test 结果
- [ ] 首页加载
- [ ] 登录功能
- [ ] 核心 CRUD
- [ ] 移动端适配

### 已知问题
- ...
```
