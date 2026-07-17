# FACTORY-V04-P2-D: Script Usability Check Report
**Timestamp**: 2026-06-25T23:10:00+08:00

## validate-draft.ps1
- **Fixed**: INSTALL_DRAFT.md/CHANGELOG_DRAFT.md → INSTALL.md/CHANGELOG.md
- **Fixed**: "One-benchmark caveat" → "Two-benchmark caveat (EVAL-8 + EVAL-13)"
- **Added**:  parameter (defaults to script parent dir)
- **Added**: DAILY_USE.md + MINIMAL_CONTEXT_PACKET.md existence checks
- **Added**: Draft duplicate absence check (CHANGELOG_DRAFT/INSTALL_DRAFT)
- **Preserved**: Relative paths, exit codes (0/1), error array

## smoke-test.ps1
- **Added**:  parameter (defaults to script parent dir)
- **Added**:  parameter for machine-readable JSON output
- **Added**: Step 6: Daily use path verification (MCP + DAILY_USE)
- **Added**: Structured results array for JSON output
- **Preserved**: All 5 original smoke scenarios

## Result: PASS — both scripts have pack-root params, JSON output, correct RC references.
