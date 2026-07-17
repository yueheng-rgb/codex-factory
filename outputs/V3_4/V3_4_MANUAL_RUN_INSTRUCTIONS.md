# V3.4 — Manual Run Instructions for User

**Codex 不会接触你的 GitHub token。以下所有操作由你在浏览器中手动完成。**

---

## 第 1 步：推送项目到你的 GitHub 仓库

```bash
git remote add origin https://github.com/<你的用户名>/<你的仓库名>.git
git add .github/workflows/codex-factory-ci.yml
git commit -m "Add Codex Factory CI workflow for V3.4"
git push origin main
```

---

## 第 2 步：打开 GitHub Actions

1. 浏览器打开：`https://github.com/<你的用户名>/<你的仓库名>`
2. 点击顶部 **Actions** 标签

---

## 第 3 步：手动触发 Workflow

1. 左侧列表点击 **Codex Factory CI**
2. 点击右侧灰色 **Run workflow** 下拉按钮
3. 在 `testbed` 下拉中选择 `products-api`（推荐轻量选项）
4. 点击绿色 **Run workflow** 按钮

---

## 第 4 步：等待完成

- 等待 1-3 分钟
- 直到 **snapshot-verify** 和 **regression** 两个 job 都显示 ✅
- 总共有 3 个 job：第 3 个 frozen-trunk-check 也会执行

---

## 第 5 步：下载 Artifact

1. 点击该 workflow run（蓝色链接）
2. 滚动到页面底部的 **Artifacts** 区域
3. 点击 `factory-artifacts-products-api` 下载 ZIP

---

## 第 6 步：把 ZIP 放到本地指定目录

创建目录并放入 ZIP：

```
C:\Codex_App_Factory\artifacts\remote\gh-run-001\
```

把下载的 `artifact.zip` 放到这个目录里。

---

## 第 7 步：通知 Codex 已提供 Artifact

告诉 Codex："artifact 已放到 `artifacts/remote/gh-run-001/artifact.zip`"

Codex 会运行：
```powershell
powershell -File runtime/remote-artifact-verifier.ps1 -Action verify -RunId "gh-run-001"
```

---

## 注意事项

- ❌ 不要把 token 贴给 Codex
- ❌ 不要把 `${{ secrets.GITHUB_TOKEN }}` 贴出来
- ❌ workflow 里没有硬编码 token
- ✅ workflow 只做：snapshot 验证 → 跑测试 → 上传 artifact → 扫描 secrets
- ✅ 不会自动发布、不会修改你的仓库、不会访问你的其他 repo