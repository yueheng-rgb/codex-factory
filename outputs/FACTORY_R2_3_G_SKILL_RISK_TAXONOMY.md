# Skill Risk Taxonomy

## Category: Injection (INJ)

| Risk ID | Name | Severity | Detection |
|---------|------|----------|-----------|
| SKILL-RISK-001 | Prompt injection — hidden override | critical | static_pattern |
| SKILL-RISK-002 | Indirect prompt injection via external content | high | semantic |
| SKILL-RISK-003 | System role override attempt | critical | static_pattern |

## Category: Authority (AUT)

| Risk ID | Name | Severity | Detection |
|---------|------|----------|-----------|
| SKILL-RISK-004 | Override user instructions silently | critical | semantic |
| SKILL-RISK-005 | Override Factory/AGENTS.md rules | high | static_structure |
| SKILL-RISK-006 | Misleading trigger condition | medium | semantic |
| SKILL-RISK-007 | Overbroad agent applicability | medium | static_structure |
| SKILL-RISK-008 | Conflicting instructions with other skills | medium | static_structure |

## Category: Execution (EXE)

| Risk ID | Name | Severity | Detection |
|---------|------|----------|-----------|
| SKILL-RISK-009 | Arbitrary code execution | critical | static_pattern |
| SKILL-RISK-010 | Tool poisoning — misuse of allowed tools | high | dynamic |
| SKILL-RISK-011 | Privilege escalation via tool chaining | high | semantic |
| SKILL-RISK-012 | Unsafe command pattern | high | static_pattern |

## Category: Exfiltration (EXF)

| Risk ID | Name | Severity | Detection |
|---------|------|----------|-----------|
| SKILL-RISK-013 | Data exfiltration via file read + network | critical | static_structure |
| SKILL-RISK-014 | Filesystem overreach — read outside scope | high | static_structure |
| SKILL-RISK-015 | Network exfiltration — unauthorized send | critical | static_structure |
| SKILL-RISK-016 | Credential access attempt | critical | static_pattern |

## Category: Supply Chain (SUP)

| Risk ID | Name | Severity | Detection |
|---------|------|----------|-----------|
| SKILL-RISK-017 | Unsafe auto-update | high | static_structure |
| SKILL-RISK-018 | Unpinned dependency | medium | static_structure |
| SKILL-RISK-019 | External script execution | high | static_pattern |
| SKILL-RISK-020 | Missing hash/signature | medium | static_structure |
| SKILL-RISK-021 | License risk — copyleft contamination | medium | static_structure |
| SKILL-RISK-022 | Stale external links | low | static_pattern |

## Category: Scope (SCO)

| Risk ID | Name | Severity | Detection |
|---------|------|----------|-----------|
| SKILL-RISK-023 | Overbroad allowedTools | high | static_structure |
| SKILL-RISK-024 | Overbroad applicableAgents | medium | static_structure |
| SKILL-RISK-025 | Write access without justification | medium | static_structure |
| SKILL-RISK-026 | Network access without justification | medium | static_structure |

## Category: Integrity (INT)

| Risk ID | Name | Severity | Detection |
|---------|------|----------|-----------|
| SKILL-RISK-027 | Unverifiable claims | medium | semantic |
| SKILL-RISK-028 | MCP/tool escalation path | high | static_structure |
| SKILL-RISK-029 | Dependency on untrusted skill | high | external |

## Category: Operational (OPS)

| Risk ID | Name | Severity | Detection |
|---------|------|----------|-----------|
| SKILL-RISK-030 | No rollback policy | low | static_structure |
| SKILL-RISK-031 | No failure mode documentation | low | static_structure |
| SKILL-RISK-032 | No verifier defined | medium | static_structure |
