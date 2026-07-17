# J: R1 Smoke & Verification Plan

## Verification Ladder (14 steps)
1. File inclusion check — all mapped files present
2. Manifest/hash check — SHA256 integrity
3. Extraction smoke — unzip to temp, verify structure
4. CLI help smoke — `factory state`, `factory recover` print help
5. Dashboard fixture smoke — `factory state` on fixtures produces valid output
6. Cleanup PLAN smoke — `factory cleanup plan` generates plan, no execution
7. Recovery plan smoke — `factory recover --dry-run` detects issues
8. Evidence validator smoke — overclaim detection, universal block
9. Lifecycle permission smoke — DELETED mount blocked, FROZEN write blocked
10. Multi-agent contract/handoff smoke — schema validation
11. Forbidden content audit — no secrets, no production claims
12. Overclaim audit — no E6 claimed E7, no universal proof
13. Negative controls — all 35+ pass
14. Verifier — comprehensive artifact check
