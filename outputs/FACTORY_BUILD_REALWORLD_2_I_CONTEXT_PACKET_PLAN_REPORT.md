# FACTORY-BUILD-REALWORLD-2-I: Context Packet Plan

**Date**: 2026-06-27
**Phase**: I — Context Packet Plan

---

## 1. Context Packet Structure

Planned `.codex-factory/` directory in working copy:

```
.codex-factory/
  project-state.json          # Current project state snapshot
  task-graph.json              # Dependency task graph
  decision-log.json            # Key decisions made
  active-risks.json            # Active risk register
  verifier-history.json        # Verification run history
  requirement-map.json         # Requirements to code mapping
  architecture-map.json        # Architecture component map
  handoff-packet.json          # Handoff summary
```

## 2. Mandatory Contents

| Item | Source | Content |
|------|--------|---------|
| secret_risk | Phase C report | All 22 findings with severity |
| deploy_risk | Phase D report | 7 PRODUCTION_RISK scripts |
| production_safety_boundary | Phases A/D | Evidence lock rules |
| forbidden_actions | Phase A | 14 forbidden actions list |
| rejected_claims | All phases | Claims like "Build Pro default", "multi-agent default" |
| evidence_paths | All phases | Paths to all reports and governance files |
| active_risks | Phases C/D | Rotating secrets, hardcoded credentials |
| no_compressed_summary | Policy | Full reports are evidence; summaries are not |

## 3. Packet Rules

| Rule | Enforcement |
|------|------------|
| No compressed summary as evidence | Original reports are canonical |
| Evidence paths always included | All governance JSONs + output MDs |
| Active risks tracked | Risk register updated per phase |
| Handoff packet self-contained | Can be consumed by next agent |

## 4. Phase I Status: COMPLETE
