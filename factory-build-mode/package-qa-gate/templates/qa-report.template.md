# Package QA Gate Report
**Gate Version**: {{GATE_VERSION}}
**Timestamp**: {{TIMESTAMP}}
**Package**: {{PACKAGE_PATH}}
**Profile**: {{PROFILE_PATH}}
**Overall Status**: {{OVERALL_STATUS}}

---

## BLOCKING Findings ({{BLOCKING_COUNT}})

{{#BLOCKING_FINDINGS}}
### [{{SEVERITY}}] {{CHECK_NAME}}
- **File**: `{{FILE_PATH}}`{{#LINE_NUMBER}}:{{LINE_NUMBER}}{{/LINE_NUMBER}}
- **Description**: {{DESCRIPTION}}
- **Evidence**: `{{EVIDENCE}}`
- **Suggestion**: {{SUGGESTION}}
{{/BLOCKING_FINDINGS}}

{{^BLOCKING_FINDINGS}}
No blocking findings. ✅
{{/BLOCKING_FINDINGS}}

---

## WARNING Findings ({{WARNING_COUNT}})

{{#WARNING_FINDINGS}}
### [WARNING] {{CHECK_NAME}}
- **File**: `{{FILE_PATH}}`
- **Description**: {{DESCRIPTION}}
- **Suggestion**: {{SUGGESTION}}
{{/WARNING_FINDINGS}}

{{^WARNING_FINDINGS}}
No warnings. ✅
{{/WARNING_FINDINGS}}

---

## INFO ({{INFO_COUNT}})

{{#INFO_FINDINGS}}
- {{CHECK_NAME}}: {{DESCRIPTION}}
{{/INFO_FINDINGS}}

---

## Summary

| Category | BLOCKING | WARNING | INFO | PASS |
|----------|----------|---------|------|------|
| Process Trace | {{PT_B}} | {{PT_W}} | {{PT_I}} | {{PT_P}} |
| Assignment Matching | {{AM_B}} | {{AM_W}} | {{AM_I}} | {{AM_P}} |
| Artifact Completeness | {{AC_B}} | {{AC_W}} | {{AC_I}} | {{AC_P}} |
| Technical Correctness | {{TC_B}} | {{TC_W}} | {{TC_I}} | {{TC_P}} |
| Structural Hygiene | {{SH_B}} | {{SH_W}} | {{SH_I}} | {{SH_P}} |
| **TOTAL** | **{{TOTAL_B}}** | **{{TOTAL_W}}** | **{{TOTAL_I}}** | **{{TOTAL_P}}** |

## Gate Decision

{{#BLOCKED}}
🛑 **BLOCKED** — {{BLOCKING_COUNT}} blocking issue(s) must be resolved before handoff.
{{/BLOCKED}}
{{#PASS_WITH_WARNINGS}}
⚠️ **PASS WITH WARNINGS** — Handoff allowed but review {{WARNING_COUNT}} warning(s).
{{/PASS_WITH_WARNINGS}}
{{#PASS}}
✅ **PASS** — Package ready for handoff.
{{/PASS}}

---
*Package QA Gate v{{GATE_VERSION}} — Read-only gate. Does not modify packages.*
