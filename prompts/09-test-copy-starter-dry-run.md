# Dry-Run 复制测试提示词

> 用于测试复制脚本，不安装依赖、不运行 build。

---

## 执行要求

### 步骤 1：选择 Starter
从当前可用的 starter 中选择一个：

- `vite-react-content-site`
- `next-fullstack-admin`

### 步骤 2：执行 Dry-Run 复制

使用复制脚本复制到测试目录：

```powershell
# Windows
C:\Codex_App_Factory\scripts\create-project-from-starter.ps1 `
  -StarterName "next-fullstack-admin" `
  -TargetPath "C:\Codex_Test_Projects\test-admin" `
  -ProjectName "test-admin" `
  -Force
```

```bash
# macOS/Linux
~/Codex_App_Factory/scripts/create-project-from-starter.sh \
  --starter next-fullstack-admin \
  --target ~/Codex_Test_Projects/test-admin \
  --name "test-admin" \
  --force
```

### 步骤 3：验证复制结果

- [ ] 目标目录已创建
- [ ] `package.json` 存在，name 已替换为 `test-admin`
- [ ] `README.md` 存在，不含 `PROJECT_NAME` 占位符
- [ ] `AGENTS.md` 存在
- [ ] `PROJECT_BRIEF.md` 存在
- [ ] `node_modules` **不存在**
- [ ] `.next` / `dist` / `build` **不存在**
- [ ] 搜索目标目录中是否还有残余 `PROJECT_NAME`（应为 0）

### 步骤 4：不要做的事

- ❌ 不运行 `npm install`
- ❌ 不运行 `npm run dev`
- ❌ 不运行 `npm run build`
- ❌ 不修改任何业务内容

### 步骤 5：输出验证报告

```
## Dry-Run 测试报告

- Starter: [name]
- 目标: [path]
- PROJECT_NAME 替换: ✅ / ❌
- package.json name: ✅ / ❌
- node_modules 不存在: ✅ / ❌
- 构建产物不存在: ✅ / ❌
- 残余 PROJECT_NAME: [count]
- 结论: 复制脚本正常 / 有问题
```

### 步骤 6：清理
测试完成后可删除 `C:\Codex_Test_Projects\`。

---

## 测试场景

建议测试以下场景：

1. **正常复制** — starter 存在，目标不存在
2. **拒绝覆盖** — 目标已存在，不用 -Force（应报错）
3. **强制覆盖** — 目标已存在，用 -Force（应成功）
4. **不存在的 starter** — 传入不存在的 starter 名称（应报错并列出可用 starter）
