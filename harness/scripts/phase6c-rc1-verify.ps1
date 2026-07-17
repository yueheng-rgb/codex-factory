# phase6c-rc1-verify.ps1 — Phase 6C-RC1 Readiness Capsule Verifier (14 checks)
param([switch]$Quick)
$ErrorActionPreference = "Continue"
Add-Type -AssemblyName System.IO.Compression.FileSystem
$H = Resolve-Path (Join-Path $PSScriptRoot "..")
$P = [System.Collections.ArrayList]@()
$E = [System.Collections.ArrayList]@()
$total = 0; $ok = 0
function check($l,$sb){$script:total++;try{if(&$sb){[void]$script:P.Add($l);$script:ok++}else{[void]$script:E.Add("$l-FAIL")}}catch{[void]$script:E.Add("$l-ERROR: $_")}}

# === 1: U3-D report exists ===
check "C01: U3-D report exists" { Test-Path "$H\outputs\PHASE_6C_U3_D_FINAL_OPERATOR_AUDIT_BUNDLE_REPORT.md" }

# === 2: U3 final ZIP exists ===
check "C02: U3 final ZIP exists" { Test-Path "$H\outputs\phase6c-u3-final-operator-audit-bundle.zip" }

# === 3: U3 final SHA recorded ===
$U3_HASH = "ad2f52731cf5a54ef1a6393e29c1a64216b5654402d5909c790a799fe5a9d12c"
check "C03: U3 final SHA matches" { (Get-FileHash "$H\outputs\phase6c-u3-final-operator-audit-bundle.zip" -Algorithm SHA256).Hash.ToLower() -eq $U3_HASH }

# === 4: U2 final ZIP exists ===
check "C04: U2 final ZIP exists" { Test-Path "$H\outputs\phase6c-u2-final-factory-audit-bundle.zip" }

# === 5: U1 final ZIP exists ===
check "C05: U1 final ZIP exists" { Test-Path "$H\outputs\phase6c-u1-final-audit-bundle.zip" }

# === 6: T0-R3 final ZIP exists ===
check "C06: T0-R3 final ZIP exists" { Test-Path "$H\outputs\phase6c-t0-r3-final-audit-bundle.zip" }

# === 7: Operator CLI exists ===
check "C07: Operator CLI exists" { Test-Path "$H\scripts\invoke-project-factory.ps1" }

# === 8: Project Factory guide exists ===
check "C08: Factory guide exists" { Test-Path "$H\docs\HARNESS_PROJECT_FACTORY_GUIDE.md" }

# === 9: Operator guide exists ===
check "C09: Operator guide exists" { Test-Path "$H\docs\HARNESS_OPERATOR_CLI_GUIDE.md" }

# === 10: Readiness capsule exists ===
check "C10: Readiness capsule exists" { Test-Path "$H\outputs\PHASE_6C_RC1_REAL_PROJECT_READINESS_CAPSULE.md" }

# === 11: Baseline index exists ===
check "C11: Baseline index exists" { Test-Path "$H\outputs\PHASE_6C_RC1_CURRENT_BASELINE_INDEX.json" }

# === 12: No spawn_agent evidence for RC1 ===
check "C12: No RC1 spawn evidence" { -not (Test-Path "$H\runs\rc1-*") -and -not (Test-Path "$H\outputs\rc1-spawn-agent-evidence.json") }

# === 13: No new final ZIP created for RC1 ===
check "C13: No RC1 final ZIP" { -not (Test-Path "$H\outputs\phase6c-rc1-final-audit-bundle.zip") }

# === 14: Final report declares RC1 is documentation only ===
$capsulePath = "$H\outputs\PHASE_6C_RC1_REAL_PROJECT_READINESS_CAPSULE.md"
check "C14: Capsule states RC1 is documentation-only" { 
    if(-not (Test-Path $capsulePath)){return $false}
    $r = Get-Content $capsulePath -Raw
    ($r -match "does not run spawn_agent") -and ($r -match "documentation-only|does not prove new capability")
}

# === 15-18: Closed ZIP SHA256 final verification ===
$T0_HASH = "65a06bced03ae764a4438aa7fb81ee3951c0516ceda258d52ded9140d9497d3d"
$U1_HASH = "2a7c3e28b4adafd9fbe62b3c68c9b2ab3eecdd067cfa503f83640b85ad41fca4"
$U2_HASH = "30f97c496935f858a2adc6176eac866f3b47f8b1e2e9f9f471f7700d9fb66064"
check "C15: T0-R3 SHA matches" { (Get-FileHash "$H\outputs\phase6c-t0-r3-final-audit-bundle.zip" -Algorithm SHA256).Hash.ToLower() -eq $T0_HASH }
check "C16: U1 SHA matches" { (Get-FileHash "$H\outputs\phase6c-u1-final-audit-bundle.zip" -Algorithm SHA256).Hash.ToLower() -eq $U1_HASH }
check "C17: U2 SHA matches" { (Get-FileHash "$H\outputs\phase6c-u2-final-factory-audit-bundle.zip" -Algorithm SHA256).Hash.ToLower() -eq $U2_HASH }
check "C18: Baseline index JSON contains all 4 phases" {
    if(-not (Test-Path "$H\outputs\PHASE_6C_RC1_CURRENT_BASELINE_INDEX.json")){return $false}
    $b = Get-Content "$H\outputs\PHASE_6C_RC1_CURRENT_BASELINE_INDEX.json" -Raw | ConvertFrom-Json
    ($b.closedPhases.Count -ge 4) -and ($b.recommendation -eq "PROCEED_TO_REAL_SMALL_PROJECT_DRY_RUN")
}

$verdict = if($E.Count -eq 0){"PASS"}else{"FAIL"}
$exitCode = if($E.Count -gt 0){1}else{0}
@{phase="Phase 6C-RC1";reportType="rc1-verifier";verdict=$verdict;timestamp=(Get-Date).ToString("o");totalChecks=$total;passCount=$ok;failCount=$E.Count;passes=$P;errors=$E} | ConvertTo-Json -Depth 3
exit $exitCode