# Factory State Monitoring — H21 Prototype

## Status: PROTOTYPE — not production automation

## Files
- `factory-state-monitoring-policy.json` — Governance rules
- `factory-state-monitoring-template.json` — Task template
- `factory-state-monitoring-result.schema.json` — Output schema
- `sample-monitoring-pass.json` — Sample clean run
- `sample-monitoring-alert.json` — Sample alert run

## Run
```powershell
powershell -File scripts/monitoring/run-factory-state-monitor.ps1 -Json
```

## Safety Rules
1. Monitoring is READONLY — never mutates state
2. MONITORING_ALERT != verifier PASS
3. Monitoring result is signal only, not closure evidence
4. Prototype only — runtime scheduling requires DRY27/H22
