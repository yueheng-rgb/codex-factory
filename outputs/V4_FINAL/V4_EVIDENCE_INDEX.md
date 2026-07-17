# V4 Evidence Index

## Evidence Hierarchy

**Strongest (Real CI + Live)**
- V3.4.2: Strict Remote CI Verification (GitHub Actions, 15/15 PASS)
- V4.4: Real Cross-Window Live Test (3 windows, 8 artifacts, 79 tests)

**Verified (Simulation + Runtime)**
- V4.3: Cross-Window Simulation (boundary violation caught 4/4)
- V4.2: Agent Execution Runtime (11 CLI commands, 3 modes)
- V4.1.1: Task Decomposition (output integrity, 0-byte fixed)

**Supporting (Foundation)**
- V4.0.1: Productization Closure (skill/knowledge/provider)
- V4.4.1: Boundary Refinement (cross-worker patterns)

## All Evidence Entries

| Version | Type | Authenticity | Classification |
|---------|------|-------------|----------------|
| V3.4.2 | CI Remote | REAL_GITHUB_ACTIONS | STRICT_VERIFIED |
| V4.0.1 | Productization | LOCAL_VERIFIED | GAPS_CLOSED |
| V4.1.1 | Reliability | LOCAL_VERIFIED | CLOSED |
| V4.2 | Runtime | LOCAL_VERIFIED | READY |
| V4.3 | Simulation | SIMULATION | VERIFIED |
| V4.4 | Live Test | REAL_LIVE_TEST | VERIFIED (A+) |
| V4.4.1 | Refinement | LOCAL_VERIFIED | CLOSED |

## No Fake Evidence
- All classifications backed by verifiable outputs
- No missing files claimed as present
- No simulation claimed as real
- No placeholder marked as PASS
