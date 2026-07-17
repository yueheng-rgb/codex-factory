# R2.1 INFRA MVP — Verification Script
# Checks that all required R2.1 artifacts are present
# Run: pwsh -File harness/verification/verify-r2-1-infra.ps1

param(
    [string]$FactoryRoot = "C:\Codex_App_Factory"
)

$ErrorActionPreference = "Continue"
$results = @()
$passCount = 0
$failCount = 0
$warnCount = 0

function Check-File {
    param([string]$Label, [string]$Path)
    $fullPath = Join-Path $FactoryRoot $Path
    if (Test-Path $fullPath) {
        $results += "[PASS] $Label : $Path"
        $script:passCount++
        return $true
    } else {
        $results += "[FAIL] $Label : $Path (MISSING)"
        $script:failCount++
        return $false
    }
}

function Check-Dir {
    param([string]$Label, [string]$Path)
    $fullPath = Join-Path $FactoryRoot $Path
    if (Test-Path $fullPath -PathType Container) {
        $results += "[PASS] $Label : $Path (directory exists)"
        $script:passCount++
        return $true
    } else {
        $results += "[FAIL] $Label : $Path (DIRECTORY MISSING)"
        $script:failCount++
        return $false
    }
}

function Check-JsonValid {
    param([string]$Label, [string]$Path)
    $fullPath = Join-Path $FactoryRoot $Path
    if (-not (Test-Path $fullPath)) {
        $results += "[FAIL] $Label : $Path (FILE MISSING — cannot validate JSON)"
        $script:failCount++
        return $false
    }
    try {
        $null = Get-Content $fullPath -Raw -Encoding UTF8 | ConvertFrom-Json -ErrorAction Stop
        $results += "[PASS] $Label : $Path (valid JSON)"
        $script:passCount++
        return $true
    } catch {
        $results += "[FAIL] $Label : $Path (INVALID JSON: $($_.Exception.Message))"
        $script:failCount++
        return $false
    }
}

function Check-Content {
    param([string]$Label, [string]$Path, [string]$MustContain)
    $fullPath = Join-Path $FactoryRoot $Path
    if (-not (Test-Path $fullPath)) {
        $results += "[FAIL] $Label : $Path (FILE MISSING)"
        $script:failCount++
        return $false
    }
    $content = Get-Content $fullPath -Raw -Encoding UTF8
    if ($content -match $MustContain) {
        $results += "[PASS] $Label : $Path (contains expected content)"
        $script:passCount++
        return $true
    } else {
        $results += "[WARN] $Label : $Path (content check failed — pattern not found)"
        $script:warnCount++
        return $false
    }
}

Write-Host "========================================" -ForegroundColor Cyan
Write-Host " R2.1 INFRA MVP — Verification Script" -ForegroundColor Cyan
Write-Host " Factory Root: $FactoryRoot" -ForegroundColor Cyan
Write-Host " Date: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# === 1. AGENT DEFINITION FILES ===
Write-Host "--- 1. Agent Definition Files ---" -ForegroundColor Yellow
Check-JsonValid "Agent: Router"           "governance\multi-agent\agent-definitions\router.agent.json"
Check-JsonValid "Agent: Research"         "governance\multi-agent\agent-definitions\research.agent.json"
Check-JsonValid "Agent: Architect"        "governance\multi-agent\agent-definitions\architect.agent.json"
Check-JsonValid "Agent: Librarian"        "governance\multi-agent\agent-definitions\librarian.agent.json"
Check-JsonValid "Agent: Implementer"      "governance\multi-agent\agent-definitions\implementer.agent.json"
Check-JsonValid "Agent: Verifier"         "governance\multi-agent\agent-definitions\verifier.agent.json"
Check-JsonValid "Agent: Security"         "governance\multi-agent\agent-definitions\security.agent.json"
Check-JsonValid "Agent: Integrator"       "governance\multi-agent\agent-definitions\integrator.agent.json"
Check-JsonValid "Agent: Drift Auditor"    "governance\multi-agent\agent-definitions\drift-auditor.agent.json"
Write-Host ""

# === 2. HANGOFF BUS ===
Write-Host "--- 2. Handoff Bus ---" -ForegroundColor Yellow
Check-JsonValid "Handoff Schema"          "governance\multi-agent\handoff-bus\handoff.schema.json"
Check-File      "Handoff Index"           "governance\multi-agent\handoff-bus\handoff-index.jsonl"
Check-Dir       "Handoffs Directory"      "governance\multi-agent\handoff-bus\handoffs"
Write-Host ""

# === 3. CONTRACT TEMPLATES ===
Write-Host "--- 3. Contract Templates ---" -ForegroundColor Yellow
Check-JsonValid "PIC Schema"             "governance\contracts\templates\pic.schema.json"
Check-JsonValid "AC Schema"              "governance\contracts\templates\ac.schema.json"
Check-JsonValid "FC Schema"              "governance\contracts\templates\fc.schema.json"
Check-JsonValid "NGC Schema"             "governance\contracts\templates\ngc.schema.json"
Check-Dir       "Active Contracts Dir"   "governance\contracts\active"
Write-Host ""

# === 4. SKILL REGISTRY ===
Write-Host "--- 4. Skill Registry Skeleton ---" -ForegroundColor Yellow
Check-JsonValid "Skill Registry Schema"  "knowledge-bank\skill-registry.schema.json"
Check-File      "Registry JSONL"         "knowledge-bank\registry.jsonl"
Check-File      "Import Policy"          "knowledge-bank\skill-import-policy.md"
Write-Host ""

# === 5. RESEARCH PACKET ===
Write-Host "--- 5. Research Packet Schema ---" -ForegroundColor Yellow
Check-JsonValid "Research Packet Schema" "knowledge-bank\research\research-packet.schema.json"
Check-File      "Source Priority"        "knowledge-bank\research\source-priority.md"
Write-Host ""

# === 6. DRIFT CHECK ===
Write-Host "--- 6. Drift Check MVP ---" -ForegroundColor Yellow
Check-JsonValid "Drift Check Schema"     "governance\drift-control\drift-check.schema.json"
Check-File      "Drift Types"            "governance\drift-control\drift-types.md"
Write-Host ""

# === 7. FAILURE LESSONS ===
Write-Host "--- 7. Failure Lesson Format ---" -ForegroundColor Yellow
Check-JsonValid "Failure Lesson Schema"  "knowledge-bank\failure-lessons\failure-lesson.schema.json"
Check-File      "Lessons JSONL"          "knowledge-bank\failure-lessons\lessons.jsonl"
# Check that lessons.jsonl has at least 3 entries
$lessonsPath = Join-Path $FactoryRoot "knowledge-bank\failure-lessons\lessons.jsonl"
if (Test-Path $lessonsPath) {
    $lessonCount = (Get-Content $lessonsPath | Where-Object { $_.Trim() -ne "" -and $_ -notmatch '^#' }).Count
    if ($lessonCount -ge 3) {
        $results += "[PASS] Failure Lessons Count : $lessonCount lessons (>= 3 required)"
        $script:passCount++
    } else {
        $results += "[FAIL] Failure Lessons Count : $lessonCount lessons (< 3 required)"
        $script:failCount++
    }
}
Write-Host ""

# === SUMMARY ===
Write-Host "========================================" -ForegroundColor Cyan
Write-Host " VERIFICATION COMPLETE" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  PASS:  $passCount" -ForegroundColor Green
Write-Host "  FAIL:  $failCount" -ForegroundColor Red
Write-Host "  WARN:  $warnCount" -ForegroundColor Yellow
Write-Host "  TOTAL: $($passCount + $failCount + $warnCount)" -ForegroundColor Cyan
Write-Host ""

if ($failCount -eq 0) {
    Write-Host ">>> R2.1 INFRA MVP VERIFICATION: ALL CHECKS PASSED <<<" -ForegroundColor Green
} else {
    Write-Host ">>> R2.1 INFRA MVP VERIFICATION: $failCount FAILURES DETECTED <<<" -ForegroundColor Red
}

Write-Host ""
Write-Host "--- Detailed Results ---" -ForegroundColor Yellow
$results | ForEach-Object { Write-Host $_ }

# Output results as JSON for report
$resultObj = @{
    verificationDate = Get-Date -Format 'yyyy-MM-ddTHH:mm:sszzz'
    factoryRoot = $FactoryRoot
    passCount = $passCount
    failCount = $failCount
    warnCount = $warnCount
    totalChecks = $passCount + $failCount + $warnCount
    passed = ($failCount -eq 0)
    details = $results
}
$resultObj | ConvertTo-Json -Depth 3 | Out-File -FilePath (Join-Path $FactoryRoot "harness\verification\r2-1-verification-result.json") -Encoding UTF8
Write-Host "`nResults saved to: harness\verification\r2-1-verification-result.json"
