# 从 Starter 创建项目提示词

> 在确认了应用类型和 starter 后使用。

---

基于我们选择的 starter（[starter 名称]），请创建项目脚手架。

## 执行要求

### 1. 参考 Starter
先读取 `C:\Codex_App_Factory\starters\[starter名称].md`，严格按照其中定义的：
- 技术栈
- 目录结构
- 核心模块

### 2. 创建项目
- 初始化项目（package.json, tsconfig, 等）
- 安装依赖
- 创建目录结构
- 配置数据库连接（如果适用）
- 创建 .env.example

### 3. 验证
- 项目能通过 `npm install` 安装依赖
- 能通过 `npm run dev` 启动（或等实现后再启动）
- .gitignore 正确配置

### 4. 输出
- 创建的文件列表
- 目录结构树
- 下一步：哪些文件需要实现
