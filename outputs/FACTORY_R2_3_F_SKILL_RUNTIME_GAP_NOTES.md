# FACTORY R2.3-F Skill Runtime Gap Notes

## Current CAP-SKILL-004 Status

- **Registry status:** VERIFIED (R2.3-B entry)
- **Pipeline status:** verified (R2.3-E: passed 6-stage import)
- **Package status:** verified (R2.3-F: skill.json v1.0.0)
- **Behavior status:** fixture-verified only — NOT runtimeVerified
- **Instructions:** 4811 chars loaded from SKILL.md

## Known Gaps

### GAP-001: Not runtimeVerified
- CAP-SKILL-004 status is `verified`, not `runtimeVerified`
- Reason: Behavior verification used fixture + regex simulation, not live agent execution
- Risk: LOW — skill content is loadable and gate-controlled; real agent verification is deferred
- Resolution: R2.3-G — exercise with real agent on project with actual AGENTS.md files

### GAP-002: Single-skill loading only
- Skill context injector loads skills one at a time
- No multi-skill conflict detection (if two skills have contradictory allowedTools)
- Risk: LOW for MVP; MEDIUM for production
- Resolution: R2.3-G — implement skill conflict matrix

### GAP-003: No skill version migration
- skill.json version 1.0.0 has no upgrade path to 1.1.0
- Rollback exists but forward-migration does not
- Risk: LOW (only one skill package)

### GAP-004: Security extraction regex is simplified
- Behavior sim uses basic regex for command/rule extraction
- Real extraction should use structured parsing (Markdown section headers)
- Risk: LOW — sim demonstrates behavioral difference, not production extraction

### GAP-005: Quarantine test uses registry-only capability
- CAP-MCP-014 has no skill package directory, so loader rejects on "dir not found" before reaching quarantine check
- The quarantine status gate IS tested on skill.json.status=quarantine path
- Risk: LOW — both paths lead to rejection; directory check is just earlier

### GAP-006: Usage ledger is append-only, no query API for trends
- `Get-SkillUsage` supports basic filtering by skillId/agentId
- No aggregation, no time-series queries
- Risk: LOW for MVP

## Does R2.3-F Allow Entry to Batch Skill Import?

**NOT YET.** Batch import requires:
1. At least one skill at `runtimeVerified` or `verified` with runtime behavior evidence — PARTIALLY MET (verified + fixture evidence, not runtimeVerified)
2. Multi-skill conflict detection — NOT MET
3. Version migration path — NOT MET

Recommendation: R2.3-G should promote one skill to runtimeVerified via real agent exercise before enabling batch import.
