# RUN-B Simulation — Package QA Gate Validation

**Phase**: G — RUN-B Simulation & Staging Pack

## 1. Simulation Design

To validate the Package QA Gate, we simulate a RUN-B scenario: a package ZIP that contains known QA-001-style defects. The gate should detect them.

### Fixture: `fixtures/qa-001-defect-fixture/`

A synthetic ZIP containing:
- `app.py` with Python syntax error
- `app.py` with "ChatGPT generated this" comment
- `report.md` missing author name
- `import pymysql` file with `?` placeholders
- `import sqlite3` file with `%s` placeholders
- Missing README
- `__pycache__/` directory included
- `.env` with real-looking SECRET_KEY

## 2. Expected Results

| Defect | Expected Finding | Severity |
|--------|-----------------|----------|
| "ChatGPT generated" in app.py | GPT residue detected | BLOCKING |
| Python syntax error | Syntax error detected | BLOCKING |
| Missing author in report | Author name not found | BLOCKING |
| PyMySQL + ? | Placeholder mismatch | BLOCKING |
| sqlite3 + %s | Placeholder mismatch | BLOCKING |
| Missing README | Missing README | WARNING |
| __pycache__ included | Cache files | WARNING |
| .env with secret | Real secret detected | BLOCKING |

## 3. Staging Pack Integration

The Package QA Gate script is referenced in the staging pack build process:

```powershell
# In staging-pack.ps1 (to be updated in staging update):
if (Test-Path "$FACTORY\factory-build-mode\package-qa-gate\scripts\package-qa-check.ps1") {
    & "$FACTORY\factory-build-mode\package-qa-gate\scripts\package-qa-check.ps1" `
        -PackagePath $stagingZipPath
    if ($LASTEXITCODE -eq 2) {
        Write-Host "[BLOCKED] Staging pack failed Package QA Gate" -ForegroundColor Red
        exit 1
    }
}
```

## 4. Phase G Status: COMPLETE
