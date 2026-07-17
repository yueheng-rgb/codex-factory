# FACTORY-BUILD-PRO-2 — Effectiveness Analysis

## 1. Can Multi-Round Iteration Work with External Memory?

**Finding: YES, with qualifications.** The decision log, task graph, and verifier history were maintained across all 3 iterations. Memory files were updated at each iteration boundary. However, the overhead of maintaining 8 memory files + 10 context packets + lifecycle records was non-trivial (~15% of total work).

## 2. Does Memory Quality Filter Low-Quality Memory?

**Finding: PARTIALLY PROVEN.** The MEMORY_QUALITY_HIERARCHY.md policy was referenced but not actively enforced by an automated filter. The context packet generator excludes compressed summaries, but there is no automated ingestion filter sweeping .codex-factory/ for L0-L1 content.

## 3. Does Context Packet Provide High-Quality Minimal Context?

**Finding: YES, for role-level context.** The context packet generator produces packets with role-specific required reads, forbidden actions, and evidence paths. Used 5 initial packets + 4 iteration packets + 1 recovery packet = 10 packets total. Word budget enforcement (2000 words) kept packets focused.

## 4. Can Native Agents Maintain Clear Role Boundaries Across Iterations?

**Finding: YES, with lifecycle registry.** The agent lifecycle registry tracked 3 agents with handoffs and close receipts. No orphan agents. Write scope map showed no overlap. All agents used fork_context:false.

## 5. Is Build Pro More Suitable Than Build Lite for Long-Term Projects?

**Finding: CONDITIONALLY.** Build Pro (multi-agent) produces richer output (parallel task graphs, role-specific context packets, lifecycle tracking). But the ~15% overhead makes it unsuitable for simple projects. Build Lite remains the practical default.

## 6. Can Codex Produce Systems Closer to Complex Products Under Harness Constraints?

**Finding: YES, when scoped.** The trial produced a real full-stack application (25 source files, 10 API routes, 10 DB tables, 31 test cases) within harness constraints. No external tools or deployment were used.

## 7. Does This Provide Stronger Evidence for v0.5?

**Finding: NO.** This trial provides evidence that Native Build Pro + Memory Quality + Context Packet infrastructure works for long-horizon projects. But v0.5 release readiness requires: (a) real-world project validation outside factory, (b) automated memory quality enforcement, (c) observability/metrics dashboard, (d) user-facing documentation.

## Strategy

- **Native Build Pro**: Remains CONDITIONAL. Valuable for complex, multi-module, long-horizon projects.
- **Build Lite**: Remains DEFAULT. Sufficient for most projects.
- **Memory Quality + Context Packet**: RECOMMENDED as optional infrastructure layer, not default.
- **v0.5**: BLOCKED. Requires external validation + automated enforcement before release consideration.
- **Multi-agent as default**: REJECTED. Evidence shows conditional value, not universal benefit.
- **Next recommendation**: Real-world trial (non-factory project) to validate findings outside harness.
