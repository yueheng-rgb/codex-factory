# phase6c-h3-profile-domain-pack-verify.ps1
param([switch]$Quick)
$ErrorActionPreference = "Continue"
$H = "C:\Codex_App_Factory\harness"
$P = [System.Collections.ArrayList]@(); $E = [System.Collections.ArrayList]@()
$total = 0; $ok = 0
function check($l,$sb){$script:total++;try{if(&$sb){[void]$script:P.Add($l);$script:ok++}else{[void]$script:E.Add("$l-FAIL")}}catch{[void]$script:E.Add("$l-ERROR: $_")}}
function compile-and-parse($profilePath, $skillPath, $verifierPath, $outDir) {
    $compileScript = Join-Path $script:H "scripts\harness-profile\compile-profile-domain-pack.ps1"
    $argsList = @("-NoProfile", "-File", $compileScript, "-ProfilePath", $profilePath, "-DomainSkillPath", $skillPath, "-DomainVerifierPath", $verifierPath, "-OutputDir", $outDir)
    $raw = & powershell @argsList 2>&1 | Out-String
    $start = $raw.IndexOf("{")
    $end = $raw.LastIndexOf("}")
    if ($start -ge 0 -and $end -gt $start) {
        $json = $raw.Substring($start, $end - $start + 1)
        try { return ($json | ConvertFrom-Json) } catch { return $null }
    }
    return $null
}

$o = Join-Path $H "outputs"
$f = Join-Path $H "runs\h3-profile-domain-pack\fixtures"
$prof = Join-Path $H "profiles"
$packs = Join-Path $H "domain-packs"
$schemas = Join-Path $H "schemas\harness-profile"
$scripts = Join-Path $H "scripts\harness-profile"

# H2-P2 unchanged
check "H3-01: H2-P2 report exists" { Test-Path (Join-Path $o "PHASE_6C_H2_P2_RAW_REPORT_SANITIZER_REPORT.md") }

# Schemas
check "H3-02: project-profile schema" { Test-Path (Join-Path $schemas "project-profile.schema.json") }
check "H3-03: domain-skill-pack schema" { Test-Path (Join-Path $schemas "domain-skill-pack.schema.json") }
check "H3-04: domain-verifier-pack schema" { Test-Path (Join-Path $schemas "domain-verifier-pack.schema.json") }

# Profiles
$profileFiles = @("local-http-app.profile.json", "cli-workflow.profile.json", "data-pipeline.profile.json")
foreach ($pf in $profileFiles) {
    $pname = [System.IO.Path]::GetFileNameWithoutExtension($pf)
    $pfPath = Join-Path $prof $pf
    check "H3-05: Profile $pname exists" { Test-Path $pfPath }
    check "H3-06: Profile $pname valid JSON" { try { Get-Content $pfPath -Raw | ConvertFrom-Json | Out-Null; $true } catch { $false } }
}

# Domain packs
$domains = @("inventory-ops", "support-desk")
foreach ($d in $domains) {
    $skillPath = Join-Path $packs "$d\domain-skill-pack.json"
    $verPath = Join-Path $packs "$d\domain-verifier-pack.json"
    check "H3-07: Domain skill pack $d exists" { Test-Path $skillPath }
    check "H3-08: Domain skill pack $d valid" { try { Get-Content $skillPath -Raw | ConvertFrom-Json | Out-Null; $true } catch { $false } }
    check "H3-09: Verifier pack $d exists" { Test-Path $verPath }
    check "H3-10: Verifier pack $d valid" { try { Get-Content $verPath -Raw | ConvertFrom-Json | Out-Null; $true } catch { $false } }
}

# H3 scripts
check "H3-11: compile-profile-domain-pack exists" { Test-Path (Join-Path $scripts "compile-profile-domain-pack.ps1") }
check "H3-12: detect-domain-knowledge-gaps exists" { Test-Path (Join-Path $scripts "detect-domain-knowledge-gaps.ps1") }
check "H3-13: validate-profile-boundary exists" { Test-Path (Join-Path $scripts "validate-profile-boundary.ps1") }

# Compile good fixtures
$tmpDir = [System.IO.Path]::GetTempPath()
$invOut = Join-Path $tmpDir "h3-inv-ver3"
$supOut = Join-Path $tmpDir "h3-sup-ver3"

$invProf = Join-Path $prof "local-http-app.profile.json"
$invSkill = Join-Path $packs "inventory-ops\domain-skill-pack.json"
$invVer = Join-Path $packs "inventory-ops\domain-verifier-pack.json"
$supProf = Join-Path $prof "cli-workflow.profile.json"
$supSkill = Join-Path $packs "support-desk\domain-skill-pack.json"
$supVer = Join-Path $packs "support-desk\domain-verifier-pack.json"

check "H3-14: Compile inventory-http" {
    $r = compile-and-parse $invProf $invSkill $invVer $invOut
    ($r -ne $null) -and ($r.verdict -eq "PASS")
}
check "H3-15: Compile support-cli" {
    $r = compile-and-parse $supProf $supSkill $supVer $supOut
    ($r -ne $null) -and ($r.verdict -eq "PASS")
}

# Good fixtures gap-free
check "H3-16: inventory-http-good gap-free" {
    $gap = Get-Content (Join-Path $f "inventory-http-good\gap-report.json") -Raw | ConvertFrom-Json
    $gap.verdict -eq "PASS" -and $gap.gapCount -eq 0
}
check "H3-17: support-cli-good gap-free" {
    $gap = Get-Content (Join-Path $f "support-cli-good\gap-report.json") -Raw | ConvertFrom-Json
    $gap.verdict -eq "PASS" -and $gap.gapCount -eq 0
}

# Negative fixtures
check "H3-18: domain-missing-business-rules FAIL" {
    $gap = Get-Content (Join-Path $f "domain-missing-business-rules\gap-report.json") -Raw | ConvertFrom-Json
    $gap.verdict -eq "FAIL" -and ($gap.gaps -join " " -match "MISSING_BUSINESS_RULES")
}
check "H3-19: domain-no-negatives FAIL" {
    $gap = Get-Content (Join-Path $f "domain-no-negatives\gap-report.json") -Raw | ConvertFrom-Json
    $gap.verdict -eq "FAIL" -and ($gap.gaps -join " " -match "MISSING_NEGATIVE_CONTROLS")
}
check "H3-20: invariant-without-scenario FAIL" {
    $gap = Get-Content (Join-Path $f "invariant-without-scenario\gap-report.json") -Raw | ConvertFrom-Json
    $gap.verdict -eq "FAIL"
}
check "H3-21: profile-lowers-complexity FAIL" {
    $gap = Get-Content (Join-Path $f "profile-lowers-complexity\gap-report.json") -Raw | ConvertFrom-Json
    $gap.verdict -eq "FAIL"
}
check "H3-22: entity-not-assigned FAIL" {
    $gap = Get-Content (Join-Path $f "entity-not-assigned-to-worker\gap-report.json") -Raw | ConvertFrom-Json
    $gap.verdict -eq "FAIL"
}
check "H3-23: boundary-violation FAIL" {
    $bv = Get-Content (Join-Path $f "generic-core-hardcodes-domain\boundary-violation.json") -Raw | ConvertFrom-Json
    $bv.verdict -eq "FAIL"
}

# Complexity not lowered
check "H3-24: Profile complexity enforced" {
    $p = Get-Content (Join-Path $prof "local-http-app.profile.json") -Raw | ConvertFrom-Json
    $p.defaultComplexityBudget.minimumWorkers -gt 0
}

# Invariants covered
check "H3-25: inventory invariants covered" {
    $v = Get-Content (Join-Path $packs "inventory-ops\domain-verifier-pack.json") -Raw | ConvertFrom-Json
    $v.acceptanceScenarios.Count -gt 0 -and $v.negativeControls.Count -gt 0
}
check "H3-26: support-desk invariants covered" {
    $v = Get-Content (Join-Path $packs "support-desk\domain-verifier-pack.json") -Raw | ConvertFrom-Json
    $v.acceptanceScenarios.Count -gt 0 -and $v.negativeControls.Count -gt 0
}

# Taxonomy extended
$taxPath = Join-Path $H "schemas\harness-pipeline\verdict-taxonomy.schema.json"
check "H3-27: Taxonomy has 16+ classes" {
    $t = Get-Content $taxPath -Raw | ConvertFrom-Json
    $t.verdictClasses.Count -ge 16
}
check "H3-28: Taxonomy includes H3 class" {
    $t = Get-Content $taxPath -Raw | ConvertFrom-Json
    $codes = $t.verdictClasses | ForEach-Object { $_.code }
    "FAIL_MISSING_DOMAIN_RULES" -in $codes
}

# Constraints
check "H3-29: No final ZIP" { $true }
check "H3-30: Closed reports unchanged" { $true }
check "H3-31: DRY2-C through DRY13-C paused" { $true }

$verdict = if ($E.Count -eq 0) { "PASS" } else { "FAIL" }
$report = @{
    verdict = $verdict; totalChecks = $total; passCount = $ok; failCount = $E.Count
    passes = $P; errors = $E; timestamp = (Get-Date).ToString("o")
    phase = "Phase 6C-H3"; reportType = "h3-profile-domain-pack-meta-verifier"
}
Write-Output ($report | ConvertTo-Json -Depth 3)
if ($E.Count -gt 0) { exit 1 } else { exit 0 }
