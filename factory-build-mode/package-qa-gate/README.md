# Package QA Gate — Implementation README

## Overview

The **Package QA Gate** is a final delivery quality checkpoint for any ZIP package produced by Codex Factory. It catches issues that build verification misses: process trace residue, assignment conformance, artifact completeness, and technical hygiene.

## Quick Start

```powershell
# Run QA on a package
.\factory-build-mode\package-qa-gate\scripts\package-qa-check.ps1 `
    -PackagePath "C:\path\to\package.zip" `
    -ProfilePath "C:\path\to\profile.json"
```

## Requirements

- PowerShell 5.1+
- Python 3.x (for Python syntax checking)
- The package must be a valid ZIP file

## File Structure

```
factory-build-mode/package-qa-gate/
├── PACKAGE_QA_GATE_SPEC.md          # Full specification
├── SCOPE_CHECKLIST_POLICY.md        # Scope, checklist, policies
├── README.md                        # This file
├── schemas/
│   └── package-qa-schemas.json      # JSON schemas for profiles/results
├── templates/
│   ├── assignment-profile.template.json
│   └── qa-report.template.md
├── profiles/                        # Put your assignment profiles here
├── scripts/
│   └── package-qa-check.ps1         # Main gate script
├── prompts/
│   ├── run-package-qa.prompt.md
│   └── repair-package-qa-findings.prompt.md
└── fixtures/                        # Test fixtures for validation
```

## Exit Codes

| Code | Meaning |
|------|---------|
| 0 | PASS — all BLOCKING checks passed |
| 1 | PASS_WITH_WARNINGS — BLOCKING passed, WARNINGs present |
| 2 | BLOCKED — one or more BLOCKING failures |

## Integration

The Package QA Gate is invoked automatically:
- Before any final ZIP handoff to user
- During staging pack build (in staging-pack.ps1)
- Can be run manually at any time

## Key Principles

- **Read-only**: Never modifies the package under test
- **Gate, not builder**: Reports issues; does not fix them
- **Delivery check**: Last checkpoint before handoff, not a development tool
- **Does not claim product correctness**: Gate PASS means checks passed, not bug-free

## Version History

| Version | Date | Changes |
|---------|------|---------|
| 1.0.0 | 2026-06-27 | Initial version from QA-001 defect formalization |
