# Session Rotation Startup Checklist

## Before Any Implementation in a New Window
1. [ ] Read governance/factory-state/current-factory-state.json
2. [ ] Read governance/factory-state/session-rotation-handoff.json
3. [ ] Run: powershell -File scripts/factoryctl.ps1 verify --json
4. [ ] Validate: Get-FileHash factory-resource-pack/MANIFEST.json | compare with MANIFEST.sha256
5. [ ] Confirm no unexpected new phase artifacts exist
6. [ ] Confirm compressed summary is NOT being treated as evidence
7. [ ] Trust only: repo artifacts, verifier JSON, manifest SHA, factory state, handoff capsule
8. [ ] Reject claims based solely on "previous window said..."

## After First Compact/Compression
- Current window: finish minor task only
- Current window: generate session-rotation-handoff.json
- DO NOT start new H/DRY/FINAL major phase
- New window: run this checklist before anything else
