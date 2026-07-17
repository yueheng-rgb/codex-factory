# Codex Factory — Internship Resume Packaging

> Target roles: Java Backend / Testing / Project Management / AI Engineering Efficiency intern

---

## 中文简历 Bullets

### 版本 A：后端开发方向（强调工程可靠性）

- 设计并实现 Codex Factory，一个面向 AI 编程助手的工程可靠性验证框架，包含快照验证、CI 制品溯源、证据链审计等 90+ 运行时模块
- 基于 PowerShell Core 构建跨平台验证管道，通过 GitHub Actions 实现 Windows/Linux 双平台一致性验证，解决 AI 生成代码"在我机器上能跑"的信任问题
- 设计严格的快照验证器（Snapshot Verifier），15 项检查全部 PASS，含 SHA256 文件哈希对比、check count 一致性校验、manifest 完整性验证
- 使用 JSON Schema 定义 57 个工程契约（CI 回执、证据包、技能包等），确保 AI 输出可被程序化验证而非依赖人工判断

### 版本 B：测试/质量保证方向（强调验证思维）

- 构建 Codex Factory 验证框架，将软件测试方法论（契约测试、回归测试、快照测试）应用于 AI 编码代理的输出质量保障
- 设计 CI 制品可追溯性管道（CI Artifact Traceability），每个 job 生成远程回执（provider=github_actions, collector_mode=remote_generated），彻底消除"本地模拟结果"的不确定性
- 编写严格模式快照验证器，修复旧版"14 checks 报告 13 PASS + 3 FAIL"的计数不一致 bug，确保 PASS+FAIL+WARN+SKIP = TOTAL
- 通过真实 GitHub Actions 远程运行验证：products-api 23/23 通过，frozen trunk 3/3 SHA256 一致，零 secrets 泄露

### 版本 C：项目管理方向（强调流程与治理）

- 主导 Codex Factory 从 V3.0 到 V3.5 的 6 个迭代版本演进，每个版本有明确的 milestone 和 verification gate
- 建立 1400+ 治理文档体系（决策记录、专家包、策略协议），将 AI 辅助开发的"隐性知识"转化为可复用、可审计的结构化规则
- 设计项目公开化方案：重写英文 README、制定 Public Release Checklist、编写实习简历包装文档，使项目具备公开展示和社区贡献条件
- 管理 GitHub Actions CI/CD 管道，实现 workflow_dispatch 手动触发、跨平台验证、制品自动上传，累计 3 次真实远程运行全部通过

---

## English Resume Bullets

### Version A: Backend / Engineering Reliability

- Designed and built Codex Factory, an engineering reliability framework for AI coding agents, featuring 90+ runtime modules for snapshot verification, CI artifact traceability, and evidence chain auditing
- Built a cross-platform verification pipeline (PowerShell Core + GitHub Actions) that ensures AI-generated code produces identical, verifiable results on Windows and Linux
- Implemented a strict Snapshot Verifier achieving 15/15 checks with SHA256 file hash comparison, check-count consistency validation, and drift detection — eliminating "fake PASS" from AI agent output
- Defined 57 JSON Schema contracts (CI receipts, evidence packs, skill packages) enabling programmatic verification of AI outputs rather than manual inspection

### Version B: Testing / Quality Assurance

- Applied software testing principles (contract testing, regression testing, snapshot testing) to AI coding agent output quality assurance through Codex Factory
- Designed a CI artifact traceability pipeline where every job generates remote receipts (provider=github_actions, collector_mode=remote_generated), eliminating uncertainty from locally-simulated results
- Fixed a critical bug in the snapshot verifier where check counts were inconsistent (14 total ≠ 13 PASS + 3 FAIL), implementing strict PASS+FAIL+WARN+SKIP = TOTAL validation
- Verified on real GitHub Actions runners: 23/23 tests passed, 3/3 frozen trunk files SHA256-matched, zero secrets leaked across 4500+ files

### Version C: Project Management / Governance

- Led Codex Factory through 6 iterative version releases (V3.0–V3.5), each with defined milestones, verification gates, and documented evidence
- Established a 1400+ document governance system (decision records, expert packs, policies, protocols), transforming tacit AI-development knowledge into structured, auditable, and reusable rules
- Orchestrated the public release preparation: authored an English README, created a Public Release Checklist, and packaged internship portfolio documentation
- Managed GitHub Actions CI/CD pipelines with manual workflow_dispatch triggers, cross-platform verification, and automatic artifact uploads — 3 consecutive remote runs, all PASS

---

## 面试讲解版

### 1 分钟版本（电梯演讲）

"我做了一个叫 Codex Factory 的项目，它是一个给 AI 编程助手用的工程可靠性框架。

现在大家都用 AI 写代码，但有一个核心问题：AI 说'做完了'——你怎么验证它真的做对了？

Codex Factory 通过三层机制解决这个问题：
第一，快照验证——15 项严格检查，每个文件做 SHA256 哈希对比；
第二，CI 制品溯源——每次 GitHub Actions 运行都生成远程回执，证明这不是本地模拟的；
第三，跨机器对比——本地和远程的 manifest 必须完全一致。

最新的 V3.4.2 版本已经在真实 GitHub Actions 上通过了严格验证，23 个 API 测试全部通过，零密钥泄露。"

### 3 分钟版本（技术深度）

"Codex Factory 本质上是一个'不信任 AI 输出'的验证框架。它解决的是 AI 辅助开发的 trust gap。

具体来说，AI 编码代理有几个典型问题：
- Fake PASS：AI 说做完了但其实什么都没验证
- 制品缺失：没有 stdout、没有日志、没有回执
- 证据链薄弱：'相信我，能跑'但没有可追溯的证据
- 本地结果不可信：Windows 上能跑，Linux 上崩溃

我设计了 90 多个 PowerShell 运行时模块来解决这些问题。最核心的是 Snapshot Verifier，它做了 15 项检查包括 manifest 存在性、JSON 解析合法性、文件 SHA256 哈希对比、bundle 数量、claims 状态分布等。

V3.4.2 修复了一个关键 bug：旧版的 check count 不一致——报告说总共 14 项检查，但 PASS+FAIL 加起来是 16。原因是部分检查被重复计数。我重写了 verifier，增加了 count consistency 自检，确保 PASS+FAIL+WARN+SKIP = TOTAL。

另一个技术亮点是 CI 制品可追溯性。之前每次 GitHub Actions 运行，回归测试的输出只存在 job log 里，下载的 artifact 里是本地模拟的旧数据。我在 workflow 里加了 stdout/stderr 捕获、ci-job-receipt 自动生成，每个 job 的 provider 明确标记为 github_actions、collector_mode 为 remote_generated。

对于简历来说，这个项目展示了几个能力：
- 系统设计：从问题识别到架构设计到持续迭代
- 工程质量：严格的验证、跨平台兼容、契约驱动开发
- 工具链：GitHub Actions CI/CD、PowerShell Core、JSON Schema
- 文档能力：英文 README、治理文档、实习包装"

---

## 项目难点 & 技术亮点

| 难点 | 解决方案 | 技术亮点 |
|---|---|---|
| AI 输出不可信 | 三层验证：快照 + 制品 + 跨机器 | 90+ 验证模块，57 JSON Schema |
| Windows/Linux 哈希不一致 | `.gitattributes` LF 规范化 | 49 条 manifest entry 从 CRLF hash 更新为 LF hash |
| "14 checks, 13+3=16" 计数 bug | 重写 verifier，增加 count consistency 自检 | PASS+FAIL+WARN+SKIP = TOTAL 强制校验 |
| npm test 输出没保存到 artifact | workflow 中使用 Tee-Object 捕获 stdout/stderr | 每个 job 生成独立 receipt + result + logs |
| CI 回执是本地模拟的 | 改为 remote_generated，每次运行自动生成 | provider=github_actions 不可伪造 |

---

## 可量化结果

| 指标 | 数值 |
|---|---|
| 运行时模块数 | 90+ PowerShell 脚本 |
| JSON Schema 契约 | 57 个 |
| 治理文档 | 1400+ 文件 |
| 专家包 | 6/6 loadable |
| CI 远程验证运行 | 3 次全部通过 |
| 快照验证通过率 | 15/15 (V3.4.2) |
| 回归测试通过率 | 23/23 (products-api) |
| Secret 扫描覆盖 | 4500+ 文件，零真实密钥 |
| 版本迭代 | V3.0 → V3.5，6 个版本 |

---

## 如何解释"Codex Factory 不是普通 CRUD 项目"

面试官可能会问："这不就是个脚本合集吗？跟普通的 CRUD 项目有什么区别？"

**回答要点：**

1. **问题层级不同**：CRUD 解决的是业务问题（增删改查），Codex Factory 解决的是**元问题**——如何验证 AI 写的代码是否正确。这是 engineering reliability 层面的问题。

2. **验证闭环**：普通项目跑完测试就结束了。Codex Factory 要求**证据链闭环**——代码 → 测试 → CI 运行 → 远程回执 → 快照对比 → 本地验证。每一步都有可追溯的证据。

3. **契约驱动**：57 个 JSON Schema 定义了 AI 输出的"接口契约"。这是 API-first 思维在 AI 工程领域的应用——不是"AI 说什么是什么"，而是"AI 输出必须符合 Schema"。

4. **跨学科**：融合了软件测试（回归、快照、契约测试）、DevOps（CI/CD、制品管理）、安全（secret scan、审计）、治理（决策记录、策略协议）等多个工程领域。

5. **自我验证**：这个框架**验证自己**——最新版本的 CI 运行通过了它自己定义的严格验证。这是一种 eating your own dog food 的工程实践。
