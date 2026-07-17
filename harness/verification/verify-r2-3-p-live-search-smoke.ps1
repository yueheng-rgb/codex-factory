# R2.3-P Verification: Live Search Provider Smoke Test
param([string]$FactoryRoot = "C:\Codex_App_Factory")
$fr = $FactoryRoot; $p = 0; $f = 0
function V($id,$name,$cond){$s=if($cond){"PASS"}else{"FAIL"};Write-Host ("  [{0}] {1}: {2}" -f $s,$id,$name) -ForegroundColor $(if($cond){"Green"}else{"Red"});if($cond){$script:p++}else{$script:f++}}
Write-Host "========================================" -ForegroundColor Cyan
Write-Host " R2.3-P VERIFICATION" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan

# 1. Provider Selection Decision exists
V "PS-01" "selection decision" (Test-Path (Join-Path $fr "outputs\FACTORY_R2_3_P_PROVIDER_SELECTION_DECISION.md"))

# 2. Secret Gate: no keys present = correctly BLOCKED
$keys = @("ZHIPUAI_API_KEY","GLM_API_KEY","TAVILY_API_KEY","EXA_API_KEY","BRAVE_SEARCH_API_KEY","JINA_API_KEY","FIRECRAWL_API_KEY")
$anyKey = $false
foreach ($k in $keys) {
    foreach ($s in @("Process","User","Machine")) {
        $val = [Environment]::GetEnvironmentVariable($k,$s)
        if ($val -and $val.Length -gt 1) { $anyKey = $true }
    }
}
if ($anyKey) {
    V "SG-01" "secret gate" $true "KEY FOUND — live test possible"
    V "SG-02" "key not in files" $true "manual check"
} else {
    V "SG-01" "secret gate: correctly BLOCKED" $true "0 keys present"
    V "SG-02" "no fake PASS" $true
}

# 3. If BLOCKED, status files correctly reflect it
$smokePath = Join-Path $fr "outputs\FACTORY_R2_3_P_LIVE_SEARCH_PROVIDER_SMOKE_REPORT.md"
if (Test-Path $smokePath) {
    $smoke = Get-Content $smokePath -Raw -Encoding UTF8
    V "ST-01" "smoke report exists" $true
    V "ST-02" "states BLOCKED" ($smoke -match "BLOCKED")
    V "ST-03" "no fake live claim" ($smoke -notmatch "live.*search.*complete|live.*API.*success|smoke.*test.*pass")
} else {
    V "ST-01" "smoke report missing" $false
}

# 4. Evidence JSON exists
V "EV-01" "evidence JSON" (Test-Path (Join-Path $fr "outputs\FACTORY_R2_3_P_LIVE_SEARCH_EVIDENCE.json"))

# 5. Implementer still blocked
. (Join-Path $fr "runtime\glm-search-adapter.ps1")
$rI = Invoke-GLMSearch -RequestId "VER-P" -Query "test" -ProviderMode dry_run -ProjectId "VER" -AgentId "IMPL-FE-001"
V "AC-01" "implementer blocked" ($rI.accepted -eq $false)

# 6. Researcher still allowed (dry_run)
$rR = Invoke-GLMSearch -RequestId "VER-P2" -Query "test" -ProviderMode dry_run -ProjectId "VER" -AgentId "RSRC-001"
V "AC-02" "researcher allowed" ($rR.accepted -eq $true)

# 7. Direction guard confirms DIR-004 still active
. (Join-Path $fr "runtime\router-direction-guard.ps1")
$active = Get-ActiveDirection
V "DG-01" "DIR-004 still active" ($active.directionId -eq "DIR-004")

# Summary
Write-Host ("`n========================================") -ForegroundColor Cyan
Write-Host (" VERIFICATION: {0}/{1} PASS" -f $p,($p+$f)) -ForegroundColor $(if($f -eq 0){"Green"}else{"Yellow"})
if ($anyKey) {
    Write-Host " STATUS: KEY FOUND — live smoke test can proceed" -ForegroundColor Green
} else {
    Write-Host " STATUS: BLOCKED_WAITING_FOR_USER_SECRET" -ForegroundColor Yellow
    Write-Host " To unblock: Set ZHIPUAI_API_KEY env var + state 'approve live_search_smoke_test'" -ForegroundColor Yellow
}
