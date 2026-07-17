# R2.3-I Multi-Project Skill Benchmark Report

## Projects

| # | Name | Type | AGENTS.md | Build | Test | Lint |
|---|------|------|:---:|:---:|:---:|:---:|
| P1 | small-nextjs-admin-demo | Next.js admin | 1 file | next build | jest | next lint |
| P2 | small-cli-tool-demo | Node.js CLI | 1 file | node -e | node tests | node -e |
| P3 | small-web-api-demo | Fastify API | 2 files | npm run build | npm test | npm run lint |

## CAP-SKILL-004 Extraction Benchmark

| Project | Files | Build | Test | Lint | Security | Dirs | Forbidden |
|---------|:---:|:---:|:---:|:---:|:---:|:---:|:---:|
| P3 (web-api) | 2 | 1 | 1 | 1 | 10 | 12 | 10 |
| P1 (nextjs) | 1 | 1 | 1 | 1 | 6 | 3 | 5 |
| P2 (cli) | 1 | 1 | 1 | 1 | 4 | 2 | 4 |

### Key Findings

1. **AGENTS.md format consistency matters** — P3 (the only project with structured backtick-quoted directory rules) yielded highest extraction counts
2. **Nested AGENTS.md (P3) doubles file count** — P3 has root + src/AGENTS.md, providing richer extraction
3. **All 3 projects have build/test/lint/handoff** — CAP-SKILL-004's core extraction works across all 3 types
4. **Security boundary detection varies** — Structured "Do NOT" / "must validate" patterns produce higher counts

## Cross-Skill Applicability

| Skill | P1 (Next.js) | P2 (CLI) | P3 (API) |
|-------|:---:|:---:|:---:|
| CAP-SKILL-004 | ✅ AGENTS.md extraction | ✅ AGENTS.md extraction | ✅ AGENTS.md extraction |
| CAP-SKILL-013 | ✅ Anti-overengineering | ✅ Small tool guard | ✅ Small API guard |
| CAP-SKILL-014 | ✅ Type classification | ✅ Type classification | ✅ Type classification |

## Conclusion

CAP-SKILL-004 is effective across 3 different project types. CAP-SKILL-013 and CAP-SKILL-014 are applicable to all 3. CAP-SKILL-015 needs project rule files to be effective and requires further validation.
