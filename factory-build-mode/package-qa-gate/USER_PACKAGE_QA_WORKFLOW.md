# User-Facing Package QA Workflow

## When This Applies

Any time Codex Factory produces a final ZIP for handoff — project submission, experiment report, source code delivery, staging bundle.

## Workflow Steps

### Step 1: User Requests Final ZIP
```
User: "Create the final ZIP for submission"
User: "Package the project for delivery"
```

### Step 2: Codex Builds/Repairs Package
- Build mode produces the package
- Any known issues are repaired
- Package ZIP is created at specified path

### Step 3: Codex Runs Package QA Gate
```
Codex automatically runs:
  package-qa-check.ps1 -PackagePath <zip> -ProfilePath <profile>
```

### Step 4: If BLOCKING Findings
1. Codex reports findings with specific files, lines, and fixes
2. Codex applies minimal repair if repair prompt is available
3. Codex re-runs QA Gate
4. Loop until PASS or user override

### Step 5: Final Handoff
- Only when PASS or PASS_WITH_WARNINGS
- QA report included as delivery evidence
- ZIP delivered to user

## Override Policy

If user explicitly approves handoff despite BLOCKING findings:
- Status recorded as PASS_WITH_OVERRIDE
- All BLOCKING findings listed in delivery record
- User accepts responsibility for unfixed issues

## Manual Usage

```powershell
# Run QA manually on any ZIP
.\factory-build-mode\package-qa-gate\scripts\package-qa-check.ps1 `
    -PackagePath "C:\my-project.zip" `
    -ProfilePath ".\factory-build-mode\package-qa-gate\profiles\my-profile.json" `
    -OutputPath ".\qa-result.json"
```
