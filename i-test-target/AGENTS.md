# Harness Safety Invariants (AGENTS.md)

> These rules apply to all Codex sessions within this Harness repository.
> Detailed documentation: docs/harness-rules.md, docs/harness-runbook.md, docs/harness-audit-contract.md

## Hard Constraints

1. **No direct canonical modification**: Never modify app source directly. All changes must go through allowed task workspace paths + integration.
2. **Builder cannot self-verify**: Verification must use an independent test-agent role with separate token.
3. **Task binding required**: Every modification must bind to a taskId, allowedPaths, and baseCanonicalHash.
4. **Evidence completeness**: Every command must capture stdout, stderr, and exitCode.
5. **validate-state ≠ engineering PASS**: validate-state.ps1 checks governance; engineering verification checks functionality. Both must pass.
6. **No capability inflation**: Reports must not claim untested capabilities as proven.
7. **Sidecar meta**: Final ZIP digest must be recorded in external .meta.json, never inside the ZIP.
8. **Cognitive isolation**: Strong cognitive isolation is NOT PROVEN. OS-level isolation is NOT PROVIDED.
