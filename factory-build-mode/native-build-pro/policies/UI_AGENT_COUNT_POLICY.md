# UI Agent Count Audit Policy

## Interpretation
- The Codex right-side agent panel shows **cumulative agent creation records** in the current window/conversation.
- It is **NOT** equal to currently active agent count.
- Agents that have been closed still appear in the panel as historical records.

## Audit Rules
1. **Never use UI count as active agent count.**
2. **Always cross-reference with agent lifecycle registry.**
3. **Pre-close audit**: count active agents from registry, not UI.
4. **Post-close audit**: verify all registered agents have close receipts.
5. **Stale detection**: if registry says active but no output in 10+ minutes, flag as potentially stale.

## BUILD-8 Reference
- UI showed: 3 agents
- Registry showed: 3 spawned, 3 completed, 3 closed
- Verdict: MATCH — UI count equals registry creation count (all closed)
