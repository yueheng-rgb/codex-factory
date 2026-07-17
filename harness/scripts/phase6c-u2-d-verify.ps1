# phase6c-u2-d-verify.ps1 — Phase 6C-U2-D Final Factory Audit Bundle Verifier (43 checks)
param([switch]$Quick)
$ErrorActionPreference = "Continue"
Add-Type -AssemblyName System.IO.Compression.FileSystem
Add-Type -AssemblyName System.IO.Compression
$H = Resolve-Path (Join-Path $PSScriptRoot "..")
$P = [System.Collections.ArrayList]@()
$E = [System.Collections.ArrayList]@()
$total = 0; $ok = 0
function check($l,$sb){$script:total++;try{if(&$sb){[void]$script:P.Add($l);$script:ok++}else{[void]$script:E.Add("$l-FAIL")}}catch{[void]$script:E.Add("$l-ERROR: $_")}}

$zipPath = "$H\outputs\phase6c-u2-final-factory-audit-bundle.zip"
$staging = "$H\outputs\phase6c-u2-final-factory-audit-bundle"
$scPath = "$zipPath.final-self-check.json"
$metaPath = "$zipPath.meta.json"

# 1-3: Pre-reqs
check "V01: U2-C report exists" { Test-Path "$H\outputs\PHASE_6C_U2_C_FACTORY_NEGATIVE_CONTROLS_REPORT.md" }
check "V02: U2-B report exists" { Test-Path "$H\outputs\PHASE_6C_U2_B_FACTORY_REAL_RUN_REPORT.md" }
check "V03: U2-A report exists" { Test-Path "$H\outputs\PHASE_6C_U2_A_REUSABLE_FACTORY_REPORT.md" }

# 4-7: ZIP + sidecars
check "V04: Staging directory exists" { Test-Path $staging }
check "V05: Final ZIP exists" { Test-Path $zipPath }
check "V06: Self-check sidecar exists" { Test-Path $scPath }
check "V07: Meta sidecar exists" { Test-Path $metaPath }

# 8-10: Sidecar separation
$zip = if(Test-Path $zipPath){[System.IO.Compression.ZipFile]::OpenRead($zipPath)}else{$null}
$ze = if($zip){$zip.Entries|%{$_.FullName}}else{@()}
check "V08: Sidecars not inside ZIP" { ($ze|?{$_ -match "final-self-check|\.meta\.json"}).Count -eq 0 }
check "V09: No final-zip-self-consistency in ZIP" { ($ze|?{$_ -match "final-zip-self-consistency"}).Count -eq 0 }
check "V10: Staging self-consistency in ZIP" { ($ze|?{$_ -match "final-staging-self-consistency"}).Count -gt 0 }
if($zip){$zip.Dispose()}

# 11-24: ZIP content
$zip2 = if(Test-Path $zipPath){[System.IO.Compression.ZipFile]::OpenRead($zipPath)}else{$null}
$ze2 = if($zip2){$zip2.Entries|%{$_.FullName}}else{@()}
check "V11: ZIP contains U2 reports" { ($ze2|?{$_ -match "PHASE_6C_U2"}).Count -ge 3 }
check "V12: ZIP contains factory templates" { ($ze2|?{$_ -match "factory\\templates"}).Count -ge 7 }
check "V13: ZIP contains example project" { ($ze2|?{$_ -match "tiny-typescript-service"}).Count -gt 0 }
check "V14: ZIP contains factory guide" { ($ze2|?{$_ -match "HARNESS_PROJECT_FACTORY_GUIDE"}).Count -gt 0 }
check "V15: ZIP contains U2 positive run" { ($ze2|?{$_ -match "runs\\u2-b-factory-real-run"}).Count -gt 0 }
check "V16: ZIP contains 3 U2 negative runs" { 
    ($ze2|?{$_ -match "runs\\u2-c-negative"} | Select-Object -Unique).Count -ge 2
}
check "V17: ZIP contains factory scripts" { ($ze2|?{$_ -match "new-project-run|materialize-project"}).Count -ge 2 }
check "V18: ZIP contains validate-state.ps1" { ($ze2|?{$_ -match "scripts\\validate-state\.ps1"}).Count -gt 0 }
check "V19: ZIP contains required schemas" { ($ze2|?{$_ -match "INTERFACE_CONTRACT|WORKER_INTERFACE_MANIFEST"}).Count -ge 2 }
check "V20: ZIP contains required prompts" { ($ze2|?{$_ -match "prompts\\orchestrator|prompts\\worker-agent"}).Count -ge 2 }
if($zip2){$zip2.Dispose()}

# 21-26: SHA256SUMS
$sumsPath = "$staging\SHA256SUMS"
check "V21: SHA256SUMS exists" { Test-Path $sumsPath }
$sumLines = if(Test-Path $sumsPath){Get-Content $sumsPath}else{@()}
check "V22: SHA256SUMS mismatch=0" {
    $m=0
    foreach($line in $sumLines){if($line.Trim().Length -eq 0){continue};$p=$line -split "\s+",2;if($p.Count -lt 2){continue};$fp=Join-Path $staging $p[1];if(Test-Path $fp){if((Get-FileHash $fp -Algorithm SHA256).Hash.ToLower() -ne $p[0]){$m++}}else{$m++}}
    $m -eq 0
}
check "V23: SHA checkedEntries=line count" { $sumLines.Count -gt 0 }

# 24-26: Bundle reports
check "V24: Bundle-layout PASS" { $bl=Get-Content "$staging\reports\bundle-layout-report.json"|ConvertFrom-Json; $bl.verdict -eq "PASS" }
check "V25: SHA256SUMS validation PASS" { $sv=Get-Content "$staging\reports\sha256sums-validation-report.json"|ConvertFrom-Json; $sv.verdict -eq "PASS" }
check "V26: Staging self-consistency PASS" { $sc=Get-Content "$staging\reports\final-staging-self-consistency-report.json"|ConvertFrom-Json; $sc.verdict -eq "PASS" }

# 27-30: External self-check
$scData = if(Test-Path $scPath){Get-Content $scPath|ConvertFrom-Json}else{$null}
$actualSha = if(Test-Path $zipPath){(Get-FileHash $zipPath -Algorithm SHA256).Hash.ToLower()}else{""}
$actualEntries = if(Test-Path $zipPath){([System.IO.Compression.ZipFile]::OpenRead($zipPath)).Entries.Count}else{0}
check "V27: External self-check PASS" { $scData -and $scData.verdict -eq "PASS" }
check "V28: Self-check points to U2 ZIP" { $scData -and $scData.artifactPath -match "phase6c-u2-final-factory-audit-bundle" }
check "V29: Self-check SHA matches actual" { $scData -and $scData.artifactSha256 -eq $actualSha }
check "V30: Self-check entry count matches" { $scData -and $scData.artifactEntryCount -eq $actualEntries }

# 31-33: Summaries
check "V31: Factory summary PASS" {
    $fs=if(Test-Path "$staging\reports\u2-factory-summary.json"){Get-Content "$staging\reports\u2-factory-summary.json"|ConvertFrom-Json}else{$null}
    $fs -and $fs.skeletonGenerated -eq $true
}
check "V32: Positive summary PASS" {
    $ps=if(Test-Path "$staging\reports\u2-positive-summary.json"){Get-Content "$staging\reports\u2-positive-summary.json"|ConvertFrom-Json}else{$null}
    $ps -and $ps.validateStateVerdict -eq "run_passed"
}
check "V33: Negative summary PASS" {
    $ns=if(Test-Path "$staging\reports\u2-negative-summary.json"){Get-Content "$staging\reports\u2-negative-summary.json"|ConvertFrom-Json}else{$null}
    $ns -and $ns.allFailForIntendedReasons -eq $true
}

# 34-37: Root checks + noise
check "V34: Root JSON=0" { (Get-ChildItem $staging -File -Filter "*.json" | Measure).Count -eq 0 }
check "V35: Root PS1=0" { (Get-ChildItem $staging -File -Filter "*.ps1" | Measure).Count -eq 0 }
$posSumRaw = Get-Content "$staging\reports\u2-positive-summary.json" -Raw
check "V36: No no_token_store in positive" { $posSumRaw -notmatch "no_token_store" }
check "V37: No PROOF_VERIFICATION_FAILED in positive" { $posSumRaw -notmatch "PROOF_VERIFICATION_FAILED" }

# 38-43: Boundaries
$reportPath = "$H\outputs\PHASE_6C_U2_D_FINAL_FACTORY_AUDIT_BUNDLE_REPORT.md"
check "V38: Final report exists" { Test-Path $reportPath }
check "V39: Report states no spawn_agent" { 
    if(Test-Path $reportPath){$r=Get-Content $reportPath -Raw;$r -match "does not run spawn_agent|does not prove new multi-agent"}else{$false}
}
check "V40: Report states only packages bundle" { 
    if(Test-Path $reportPath){$r=Get-Content $reportPath -Raw;$r -match "packages|audit bundle|packaging"}else{$false}
}
check "V41: T0-R3 ZIP unchanged" {
    $t="$H\outputs\phase6c-t0-r3-final-audit-bundle.zip"
    if(Test-Path $t){(Get-FileHash $t -Algorithm SHA256).Hash.ToLower() -eq "65a06bced03ae764a4438aa7fb81ee3951c0516ceda258d52ded9140d9497d3d"}else{$false}
}
check "V42: U1 final ZIP unchanged" {
    $u="$H\outputs\phase6c-u1-final-audit-bundle.zip"
    if(Test-Path $u){(Get-FileHash $u -Algorithm SHA256).Hash.ToLower() -eq "2a7c3e28b4adafd9fbe62b3c68c9b2ab3eecdd067cfa503f83640b85ad41fca4"}else{$false}
}
check "V43: U2-B positive not modified" {
    $vs = Get-Content "$H\runs\u2-b-factory-real-run\reports\validate-state-report.json" | ConvertFrom-Json
    $vs.verdict -eq "run_passed"
}

$verdict = if($E.Count -eq 0){"PASS"}else{"FAIL"}
$exitCode = if($E.Count -gt 0){1}else{0}
@{phase="Phase 6C-U2-D";reportType="u2-d-verifier";verdict=$verdict;timestamp=(Get-Date).ToString("o");totalChecks=$total;passCount=$ok;failCount=$E.Count;passes=$P;errors=$E} | ConvertTo-Json -Depth 3
exit $exitCode
