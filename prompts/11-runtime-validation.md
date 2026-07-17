# Runtime Validation — 运行验证提示词

> 当一个由 starter 复制出的项目完成最小改造后，用它做真实运行验证。

## 限定条件

- 只允许操作指定测试项目目录
- 禁止操作真实业务项目
- 禁止下载 Chromium / Playwright
- 禁止接真实数据库 / 真实认证
- 禁止乱加依赖解决结构问题

## 执行步骤

### 1. 进入目标目录
```bash
cd <target-project-path>
```

### 2. npm install
```bash
npm install
```
记录：是否成功、是否有 peer / security warning、是否生成 package-lock.json。

### 3. npm run typecheck
```bash
npm run typecheck
```
如果失败：
- 判断是业务改造引入的问题，还是 starter 源模板问题
- 优先修复测试项目
- 如果是 starter 源模板缺陷，记录为 defect 并同步修复原 starter

### 4. npm run build
```bash
npm run build
```
如果失败：
- 判断失败原因（BOM / 类型错误 / 缺失文件 / 配置问题）
- 不引入新框架 / 新依赖 / 真实 DB / 真实认证
- 只做必要修复
- 如果是 starter 源模板问题，同步修复原 starter

### 5. npm run dev（短启动）
```bash
npm run dev
```
- 启动后观察 5-10 秒，确认无立即崩溃
- 确认输出本地地址（如 `http://localhost:3000`）
- 立即停止服务（Ctrl+C 或 kill 进程）
- 不要长时间运行
- 不要打开浏览器

## 问题分类

| 来源 | 特征 | 处理方式 |
|------|------|---------|
| **generated project issue** | 业务改造引入的类型错误、文案缺失 | 修复测试项目 |
| **starter source defect** | 源模板包本身无法 build/typecheck | 同步修复原 starter |
| **copy script defect** | 复制后 BOM、文件缺失、替换不完整 | 修复脚本 + 重新 dry-run |
| **dependency / environment** | Node/npm 版本兼容、网络问题 | 报告用户 |

## 输出验证报告

完成后输出简短报告：
- 各步骤结果（pass/fail）
- 发现的问题及分类
- 修复内容（如有）
- 下一步建议

---

## Runtime Validation 完成后必须更新

1. `C:\Codex_App_Factory\RUNTIME_VALIDATION_REPORT.md` — 新增验证案例记录
2. `C:\Codex_App_Factory\README.md` — 更新 Phase 状态
3. 如发现 starter 缺陷，更新 `STARTER_QUALITY_CHECKLIST.md`
4. 在 checklist 中标记该 starter 是否已经 runtime validate
5. 如发现工厂级问题（脚本 BOM / 组件灵活性等），同步修复源 starter 并记录
