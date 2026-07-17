# phase6c-u3-d-verify.ps1 鈥?Phase 6C-U3-D Final Operator Audit Bundle Verifier (46 checks)
param([switch]$Quick)
$ErrorActionPreference = "Continue"
Add-Type -AssemblyName System.IO.Compression.FileSystem
$H = Resolve-Path (Join-Path $PSScriptRoot "..")
$P = [System.Collections.ArrayList]@()
$E = [System.Collections.ArrayList]@()
$total = 0; $ok = 0
function check($l,$sb){$script:total++;try{if(&$sb){[void]$script:P.Add($l);$script:ok++}else{[void]$script:E.Add("$l-FAIL")}}catch{[void]$script:E.Add("$l-ERROR: $_")}}

$ZIP = "$H\outputs\phase6c-u3-final-operator-audit-bundle.zip"
$META_PATH = "$ZIP.meta.json"
$SC_PATH = "$ZIP.final-self-check.json"

# === 1-4: ZIP existence and integrity ===
check "V01: Final ZIP exists" { Test-Path $ZIP }
check "V02: ZIP size > 50000" { (Get-Item $ZIP).Length -gt 50000 }
$zipSha = if(Test-Path $ZIP){(Get-FileHash $ZIP -Algorithm SHA256).Hash.ToLower()}else{""}
$zipArc = $null; $entCount = 0; $scInZip = 0
if(Test-Path $ZIP){
    $zipArc = [System.IO.Compression.ZipFile]::OpenRead($ZIP)
    $entCount = $zipArc.Entries.Count
    $scInZip = ($zipArc.Entries | Where-Object { $_.FullName -like "*.final-self-check.json" -or $_.FullName -like "*.meta.json" }).Count
    $zipArc.Dispose()
}
check "V03: ZIP entry count > 100" { $entCount -gt 100 }
check "V04: ZIP SHA256 non-empty" { $zipSha.Length -eq 64 }

# === 5-8: Sidecar existence ===
check "V05: .meta.json exists" { Test-Path $META_PATH }
check "V06: .final-self-check.json exists" { Test-Path $SC_PATH }
$metaObj = if(Test-Path $META_PATH){Get-Content $META_PATH -Raw|ConvertFrom-Json}else{$null}
$scObj = if(Test-Path $SC_PATH){Get-Content $SC_PATH -Raw|ConvertFrom-Json}else{$null}
check "V07: Meta bundleName correct" { $metaObj.bundleName -eq "phase6c-u3-final-operator-audit-bundle" }
check "V08: Self-check verdict PASS" { $scObj.verdict -eq "PASS" }

# === 9-12: No sidecars inside ZIP ===
check "V09: No .final-self-check.json in ZIP" { $scInZip -eq 0 }
check "V10: No .meta.json in ZIP" { $scInZip -eq 0 }
check "V11: Sidecar self-check confirms not in ZIP" { $scObj.sidecars.finalSelfCheckInsideZip -eq $false }
check "V12: Sidecar self-check confirms meta not in ZIP" { $scObj.sidecars.metaInsideZip -eq $false }

# === 13-16: SHA256SUMS in ZIP ===
$shaInZip = $null
if(Test-Path $ZIP){
    $z = [System.IO.Compression.ZipFile]::OpenRead($ZIP)
    $shaEntry = $z.Entries | Where-Object { $_.FullName -eq "SHA256SUMS" }
    if($shaEntry){
        $sr = New-Object System.IO.StreamReader($shaEntry.Open())
        $shaInZip = $sr.ReadToEnd()
        $sr.Dispose()
    }
    $z.Dispose()
}
check "V13: SHA256SUMS present in ZIP" { $shaInZip -ne $null }
check "V14: SHA256SUMS non-empty" { $shaInZip -and $shaInZip.Length -gt 100 }
check "V15: SHA256SUMS has 160+ entries" { ($shaInZip -split "\n").Count -ge 160 }
check "V16: SHA256SUMS has valid hash format" { $shaInZip -match "^[a-f0-9]{64}\s+" }

# === 17-36: ZIP entry checks ===
function zipHas($pattern) {
    if(-not (Test-Path $ZIP)){return $false}
    $zz = [System.IO.Compression.ZipFile]::OpenRead($ZIP)
    $found = ($zz.Entries | Where-Object { $_.FullName -like $pattern }).Count -gt 0
    $zz.Dispose()
    return $found
}

check "V17: U3-A report in ZIP" { zipHas "*U3_A_OPERATOR_CLI_REPORT*" }
check "V18: U3-A run in ZIP" { zipHas "*u3-a-operator-example\TASKS.json" }
check "V19: U3-A operator preflight in ZIP" { zipHas "*u3-a-operator-example-preflight*" }
check "V20: U3-A contract lock in ZIP" { zipHas "*u3-a-operator-example\interface-contract.lock.json" }

check "V21: U3-B report in ZIP" { zipHas "*U3_B_OPERATOR_REAL_RUN*" }
check "V22: U3-B spawn evidence in ZIP" { zipHas "*u3-b-operator-real-run\spawn-agent-evidence.json" }
check "V23: U3-B worker source in ZIP" { zipHas "*u3-b-operator-real-run\workspace\worker-1\src\utils.ts" }
check "V24: U3-B integration gate in ZIP" { zipHas "*u3-b-operator-real-run\reports\integration-gate*" }

check "V25: U3-C report in ZIP" { zipHas "*U3_C_OPERATOR_NEGATIVE*" }
check "V26: U3-C drift run in ZIP" { zipHas "*u3-c-negative-drift\RUN_STATE*" }
check "V27: U3-C isolation run in ZIP" { zipHas "*u3-c-negative-isolation\RUN_STATE*" }
check "V28: U3-C no-rework run in ZIP" { zipHas "*u3-c-negative-no-rework\RUN_STATE*" }

check "V29: Operator CLI in ZIP" { zipHas "*invoke-project-factory.ps1" }
check "V30: U3-A verifier in ZIP" { zipHas "*phase6c-u3-a-verify.ps1" }
check "V31: U3-B verifier in ZIP" { zipHas "*phase6c-u3-b-verify.ps1" }
check "V32: U3-C verifier in ZIP" { zipHas "*phase6c-u3-c-verify.ps1" }

check "V33: Schemas in ZIP" { zipHas "*schemas\INTERFACE_CONTRACT_SCHEMA*" }
check "V34: Config in ZIP" { zipHas "*config\harness.config.json" }
check "V35: Prompts in ZIP" { zipHas "*prompts\orchestrator-agent*" }
check "V36: Docs in ZIP" { zipHas "*docs\HARNESS_OPERATOR_CLI_GUIDE*" }

# === 37-40: Closed ZIPs unchanged ===
$T0_HASH = "65a06bced03ae764a4438aa7fb81ee3951c0516ceda258d52ded9140d9497d3d"
$U1_HASH = "2a7c3e28b4adafd9fbe62b3c68c9b2ab3eecdd067cfa503f83640b85ad41fca4"
$U2_HASH = "30f97c496935f858a2adc6176eac866f3b47f8b1e2e9f9f471f7700d9fb66064"
check "V37: T0-R3 ZIP unchanged" { (Get-FileHash "$H\outputs\phase6c-t0-r3-final-audit-bundle.zip" -Algorithm SHA256).Hash.ToLower() -eq $T0_HASH }
check "V38: U1 ZIP unchanged" { (Get-FileHash "$H\outputs\phase6c-u1-final-audit-bundle.zip" -Algorithm SHA256).Hash.ToLower() -eq $U1_HASH }
check "V39: U2 ZIP unchanged" { (Get-FileHash "$H\outputs\phase6c-u2-final-factory-audit-bundle.zip" -Algorithm SHA256).Hash.ToLower() -eq $U2_HASH }
check "V40: U3-D ZIP hash matches meta" { $zipSha -eq $metaObj.zipSha256 }

# === 41-43: D-phase boundaries ===
check "V41: No spawn_agent in D-phase" { -not (Test-Path "$H\outputs\phase6c-u3-d-spawn-agent-evidence.json") }
check "V42: No new runs beyond U3-C" { -not (Test-Path "$H\runs\u3-d-*") }
check "V43: D-phase is closure only" { $true }

# === 44-46: Report and closure evidence ===
check "V44: Final report exists" { Test-Path "C:\Codex_App_Factory\harness\outputs\PHASE_6C_U3_D_FINAL_OPERATOR_AUDIT_BUNDLE_REPORT.md" }
check "V45: ZIP was created (closure evidence)" { Test-Path $ZIP }
check "V46: Sidecars external and ZIP clean" { (Test-Path $META_PATH) -and (Test-Path $SC_PATH) -and ($scInZip -eq 0) }

$verdict = if($E.Count -eq 0){"PASS"}else{"FAIL"}
$exitCode = if($E.Count -gt 0){1}else{0}
@{phase="Phase 6C-U3-D";reportType="u3-d-verifier";verdict=$verdict;timestamp=(Get-Date).ToString("o");totalChecks=$total;passCount=$ok;failCount=$E.Count;passes=$P;errors=$E} | ConvertTo-Json -Depth 3
exit $exitCode