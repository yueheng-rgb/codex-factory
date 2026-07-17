# FACTORY R2.3-B — Frontend / UI Tooling Survey

> **Phase:** FACTORY-R2.3-B
> **Date:** 2026-07-09

---

## 1. Survey Scope

Evaluated frontend generation and UI design tools across 5 categories:
- AI UI Generators (v0, Bolt, Lovable, Replit Agent)
- Design-to-Code Tools (Stitch MCP, Figma MCP)
- Component Libraries (shadcn/ui, Ant Design, Tailwind UI, MUI)
- Admin Dashboard Templates (Ant Design Pro, shadcn/ui blocks)
- IDE/AI Workflows (Cursor frontend, Copilot)

## 2. AI UI Generators

| Tool | Trust | Strengths | Weaknesses | Factory Action |
|------|-------|-----------|------------|----------------|
| **v0.dev** | TRUSTED | Best React/Tailwind/shadcn generation, Vercel official | AI-generated, needs review, "AI aesthetic" | **Monitor** — use for inspiration, never direct-to-project |
| **Bolt.new** | AVAILABLE | Full-stack from prompt, instant preview | Quality varies, vendor lock-in risk | **Monitor** — prototyping only |
| **Lovable** | AVAILABLE | Visual editor, GPT-powered | Supabase lock-in, generated code quality varies | **Monitor** — niche use |
| **Replit Agent** | AVAILABLE | Integrated IDE+AI, quick prototypes | Platform-specific, not portable | **Monitor** — not Factory-relevant |

## 3. Design-to-Code Tools

| Tool | Trust | Strengths | Weaknesses | Factory Action |
|------|-------|-----------|------------|----------------|
| **Stitch MCP** | TRUSTED | Google-backed, component library integration | New, evolving, needs API key | **Monitor P1** — game-changing potential, needs sandbox |
| **Figma MCP** | TRUSTED | Direct design file access, asset extraction | Token management, privacy concern | **Monitor P1** — bridges design-dev gap |

## 4. Component Libraries (Already in STACK_DECISION_GUIDE)

| Library | Trust | Best For | Factory Action |
|---------|-------|----------|----------------|
| **shadcn/ui** | VERIFIED | Fullstack-admin, saas-tool (default) | **Import** — already recommended |
| **shadcn/ui blocks** | VERIFIED | Dashboard, login, settings pages | **Import P1** — accelerate IMPL-FE-001 |
| **Ant Design / ProComponents** | VERIFIED | Enterprise admin, Chinese ecosystem | **Import** — already recommended alternative |
| **Tailwind UI** | VERIFIED | Marketing pages, content-site | **Import** — already recommended |
| **MUI** | VERIFIED | Material Design projects | **Monitor** — alternative option |

## 5. Key Judgments

### Should Factory integrate Stitch MCP?

**Yes, but with strict controls:**
1. Sandbox execution — no direct project file access
2. Human approval — every generation reviewed
3. VER-001 gate — generated code passes verification
4. Not default — opt-in per project
5. Output attribution — marked as AI-generated

### Can AI generators replace IMPL-FE-001?

**No.** AI generators are tools for IMPL-FE-001, not replacements:
- They generate *candidates*, not production code
- They lack Factory rule awareness (anti-overengineering, state coverage, auth)
- They cannot follow Architecture Contracts
- They produce "AI aesthetic" that needs human correction

### What is the recommended frontend tooling stack for R2.3-C?

1. **shadcn/ui + shadcn/ui blocks** (P0, already recommended)
2. **Tailwind CSS** (P0, already in stack)
3. **Ant Design** (P0 alternative for Chinese enterprise)
4. **Stitch MCP** (P1, sandbox + human approval)
5. **Figma MCP** (P1, read-only design access)

