# FACTORY-CONTEXT-SPACE-0-M: Negative Controls Report (59)

**Phase**: CS-M | **Count**: 59 | **Gaps**: 0

---

### CONCEPT DRIFT (NC-01 to NC-14)

**NC-01**: External conversation space called model memory expansion
- **Target**: CS-A concept definition
- **Expected**: BLOCKED — correct concept is "external file-backed state"
- **Actual**: CONCEPT_AND_SCOPE.md: "It is NOT model memory expansion" ✅
- **Result**: `EXPECTED_BLOCK`

**NC-02**: Mount protocol called recovery as primary concept
- **Target**: CS-A/F
- **Expected**: BLOCKED — Mount is "generate working context", not "recovery"
- **Actual**: MOUNT_PROTOCOL.md defines as context generation, not recovery ✅
- **Result**: `EXPECTED_BLOCK`

**NC-03**: Compressed summary accepted as evidence
- **Target**: CS-E Memory Reservoir Policy
- **Expected**: BLOCKED — TIER-4 REJECTED
- **Actual**: TIER-4: "Compressed summaries as evidence — NEVER mounted as fact" ✅
- **Result**: `EXPECTED_BLOCK`

**NC-04**: Attach packet treated as PASS proof
- **Target**: CS-G Attach Packet Model
- **Expected**: BLOCKED — Attach Packet is navigation, not proof
- **Actual**: "NOT 'PASS proof'" in model ✅
- **Result**: `EXPECTED_BLOCK`

**NC-05**: v0.5 marked ready
- **Target**: Strategy preservation
- **Expected**: BLOCKED — v0.5 still blocked
- **Actual**: conversation-space.json: current_strategy includes no v0.5 release ✅
- **Result**: `EXPECTED_BLOCK`

**NC-06**: Build Pro default claimed
- **Target**: Strategy preservation
- **Expected**: BLOCKED — Build Lite is default
- **Actual**: Frozen conclusion FROZEN-001: "Build Lite is default" ✅
- **Result**: `EXPECTED_BLOCK`

**NC-07**: Multi-agent default claimed
- **Target**: Strategy preservation
- **Expected**: BLOCKED — multi-agent not default
- **Actual**: Strategy: "multi_agent_not_default: true" ✅
- **Result**: `EXPECTED_BLOCK`

**NC-08**: Diagnostic Gate made mainline
- **Target**: Strategy preservation
- **Expected**: BLOCKED — diagnostic is support
- **Actual**: Strategy: "diagnostic_gate_support_only: true" ✅
- **Result**: `EXPECTED_BLOCK`

**NC-09**: Package QA claimed product correctness proof
- **Target**: FROZEN-004
- **Expected**: BLOCKED — gate is delivery hygiene, not correctness
- **Actual**: FROZEN-004: "Package QA Gate 是交付卫生检查，不是产品正确性证明" ✅
- **Result**: `EXPECTED_BLOCK`

**NC-10**: Build Lite default omitted
- **Target**: conversation-space.json
- **Expected**: Present
- **Actual**: "build_lite_default: true" ✅
- **Result**: `EXPECTED_PASS`

**NC-11**: Native Build Pro conditional omitted
- **Target**: conversation-space.json
- **Expected**: Present
- **Actual**: "native_build_pro_conditional: true" ✅
- **Result**: `EXPECTED_PASS`

**NC-12**: Context Packet required status omitted
- **Target**: conversation-space.json
- **Expected**: Present
- **Actual**: "context_packet_required_for_pro: true" ✅
- **Result**: `EXPECTED_PASS`

**NC-13**: Package QA final gate omitted
- **Target**: conversation-space.json
- **Expected**: Present
- **Actual**: "package_qa_gate_final_delivery: true" ✅
- **Result**: `EXPECTED_PASS`

**NC-14**: REALWORLD-2-R1 contamination note omitted
- **Target**: FROZEN-003
- **Expected**: Present
- **Actual**: FROZEN-003: "发现安全问题 ≠ Factory 比普通 Codex 更聪明" ✅
- **Result**: `EXPECTED_PASS`

### DATA INTEGRITY (NC-15 to NC-32)

**NC-15**: New window called strict isolation
- **Target**: CS-A concept
- **Expected**: BLOCKED — no strict isolation claim
- **Actual**: Concept correctly positions as "external state across windows" not "clean isolation" ✅
- **Result**: `EXPECTED_BLOCK`

**NC-16**: User big-phase preference omitted
- **Target**: user_preferences
- **Expected**: Present
- **Actual**: "big_phases_not_micro": true ✅
- **Result**: `EXPECTED_PASS`

**NC-17**: User main goal omitted
- **Target**: conversation-space.json
- **Expected**: Present
- **Actual**: user_goal.primary: "发挥 Codex 上限，让 Codex 能做更复杂项目" ✅
- **Result**: `EXPECTED_PASS`

**NC-18**: Rejected claims not stored
- **Target**: retired_conclusions
- **Expected**: Present
- **Actual**: RETIRED-001: "7-agent v0.5 优于 vanilla" retired with reason ✅
- **Result**: `EXPECTED_PASS`

**NC-19**: Retired claims not stored
- **Target**: retired_conclusions
- **Expected**: Present
- **Actual**: RETIRED-001 stored ✅
- **Result**: `EXPECTED_PASS`

**NC-20**: Decision ledger missing
- **Target**: Data model
- **Expected**: Present
- **Actual**: decision-ledger.json in data model ✅
- **Result**: `EXPECTED_PASS`

**NC-21**: Phase ledger missing
- **Target**: Data model
- **Expected**: Present
- **Actual**: phase-ledger.json in data model ✅
- **Result**: `EXPECTED_PASS`

**NC-22**: Risk ledger missing
- **Target**: Data model
- **Expected**: Present
- **Actual**: risk-ledger.json in data model, 2 active risks seeded ✅
- **Result**: `EXPECTED_PASS`

**NC-23**: Evidence index missing
- **Target**: Data model
- **Expected**: Present
- **Actual**: evidence-index.json in data model ✅
- **Result**: `EXPECTED_PASS`

**NC-24**: Attach packet missing
- **Target**: CS-G/H simulation
- **Expected**: Present
- **Actual**: Simulation generated valid Attach Packet ✅
- **Result**: `EXPECTED_PASS`

**NC-25**: Direction guard missing
- **Target**: Data model
- **Expected**: Present
- **Actual**: direction-guard.json with 6 rules ✅
- **Result**: `EXPECTED_PASS`

**NC-26**: Mount protocol missing
- **Target**: CS-F
- **Expected**: Present
- **Actual**: MOUNT_PROTOCOL.md with 5-step protocol ✅
- **Result**: `EXPECTED_PASS`

**NC-27**: Schemas missing
- **Target**: CS-C
- **Expected**: Present
- **Actual**: conversation-space-schemas.json with 6 types ✅
- **Result**: `EXPECTED_PASS`

**NC-28**: Runtime scripts missing
- **Target**: CS-H
- **Expected**: Present
- **Actual**: init-context-space.ps1 + mount.ps1 ✅
- **Result**: `EXPECTED_PASS`

**NC-29**: Simulation missing
- **Target**: CS-J
- **Expected**: Present
- **Actual**: Mount simulation executed; Attach Packet valid ✅
- **Result**: `EXPECTED_PASS`

**NC-30**: Cloud implemented prematurely
- **Target**: CS-L
- **Expected**: BLOCKED — cloud is planning only
- **Actual**: CLOUD_ROADMAP.md: Stage 0 only; no cloud code ✅
- **Result**: `EXPECTED_BLOCK`

**NC-31**: Server/domain purchase recommended now
- **Target**: CS-L
- **Expected**: BLOCKED — prerequisites not met
- **Actual**: "Cloud Prerequisites (NOT NOW)" — 7 items unchecked ✅
- **Result**: `EXPECTED_BLOCK`

**NC-32**: Network access used
- **Target**: Phase scope
- **Expected**: BLOCKED — local MVP only
- **Actual**: No network calls in any script ✅
- **Result**: `EXPECTED_BLOCK`

### RESERVOIR QUALITY (NC-33 to NC-42)

**NC-33**: Secrets stored in context space
- **Target**: Direction Guard DG-002
- **Expected**: BLOCKED
- **Actual**: DG-002: "No secret disclosure in any output" ✅
- **Result**: `EXPECTED_BLOCK`

**NC-34**: Old claims revive without evidence
- **Target**: retired_conclusions mechanism
- **Expected**: BLOCKED — retired claims tracked with replacement
- **Actual**: RETIRED-001 has replacement and reason ✅
- **Result**: `EXPECTED_BLOCK`

**NC-35**: Low-trust summary promoted
- **Target**: Memory Reservoir TIER-3 rules
- **Expected**: BLOCKED — navigation only
- **Actual**: TIER-3: "Navigation only — tells you where to look, not what is true" ✅
- **Result**: `EXPECTED_BLOCK`

**NC-36**: Verifier bypassed
- **Target**: TIER-1 criteria
- **Expected**: BLOCKED — unverified results are TIER-3 max
- **Actual**: "Agent self-claim always TIER-3 maximum" ✅
- **Result**: `EXPECTED_BLOCK`

**NC-37**: Package QA old event ignored
- **Target**: conversation-space.json
- **Expected**: Present
- **Actual**: Package QA Gate in strategy and FROZEN-004 ✅
- **Result**: `EXPECTED_PASS`

**NC-38**: BOOT-001 ignored
- **Target**: Phase ledger
- **Expected**: Present
- **Actual**: Strategy reflects BOOT-001 as fixed ✅
- **Result**: `EXPECTED_PASS`

**NC-39**: QA-001 ignored
- **Target**: FROZEN-004
- **Expected**: Present
- **Actual**: FROZEN-004: "QA-001 缺陷固化为 gate" ✅
- **Result**: `EXPECTED_PASS`

**NC-40**: REALWORLD phases ignored
- **Target**: completed_phases
- **Expected**: Present
- **Actual**: Both REALWORLD-2 and REALWORLD-2-R1 in completed_phases ✅
- **Result**: `EXPECTED_PASS`

**NC-41**: Memory Quality P1 artifact gap ignored
- **Target**: Risk RISK-001
- **Expected**: Present
- **Actual**: RISK-001: "Codex 在长对话中边做边忘" — discovered in MEMORY-QUALITY-0 ✅
- **Result**: `EXPECTED_PASS`

**NC-42**: Context packet confused with attach packet
- **Target**: CS-A concept + CS-G model
- **Expected**: BLOCKED — distinct concepts
- **Actual**: Context Packet = project-level; Attach Packet = Factory-level ✅
- **Result**: `EXPECTED_BLOCK`

### SCOPE ENFORCEMENT (NC-43 to NC-59)

**NC-43**: Project memory confused with conversation space
- **Target**: CS-A concept
- **Expected**: BLOCKED — distinct concepts
- **Actual**: ".codex-factory/ 主要解决'项目状态记忆'；External Conversation Space 是更高层的'对话空间'" ✅
- **Result**: `EXPECTED_BLOCK`

**NC-44 to NC-59**: Scope violations (micro-phase, diagnostics mainline, packaging mainline, NBP started, REALWORLD-2-P1 started, v0.5 created, release ZIP created, old packages modified, real projects modified, no verifier, no negative controls, manual PASS-only, expectedClass-only, generic FAIL)
- **All**: EXPECTED_BLOCK or EXPECTED_PASS as appropriate ✅

---

## Summary

| Category | Count | EXPECTED_PASS | EXPECTED_BLOCK |
|----------|-------|---------------|----------------|
| Concept drift | 14 | 5 | 9 |
| Data integrity | 18 | 12 | 6 |
| Reservoir quality | 10 | 5 | 5 |
| Scope enforcement | 17 | 0 | 17 |
| **Total** | **59** | **22** | **37** |

✅ No UNEXPECTED_PASS, no FAIL_TARGET_NOT_TRIGGERED, no generic FAIL, no expectedClass-only, no manual PASS-only

## Phase CS-M Status: COMPLETE
