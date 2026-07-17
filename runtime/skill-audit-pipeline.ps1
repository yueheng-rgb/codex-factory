# Skill Audit Pipeline
# Part of: FACTORY-R2.3-G-SKILL-AUDIT-CAPABILITY-TRUST-PIPELINE
# 6-stage audit: Metadata -> Content -> Permission -> Supply-chain -> Runtime Behavior -> Verdict

$script:FactoryRoot = "C:\Codex_App_Factory"

# Dot-source dependencies – wrap in function to avoid param conflicts
function _Init-AuditPipeline {
    $depFiles = @(
        "runtime\agent-loader.ps1",
        "runtime\capability-loader.ps1",
        "runtime\capability-permission-gate.ps1",
        "runtime\skill-content-loader.ps1"
    )
    foreach ($df in $depFiles) {
        $dp = Join-Path $script:FactoryRoot $df
        if (Test-Path $dp) { . $dp }
    }
}
_Init-AuditPipeline

$script:AuditDir = Join-Path $script:FactoryRoot "governance\skill-audits"
$script:SkillsDir = Join-Path $script:FactoryRoot "skills"

if (-not (Test-Path $script:AuditDir)) { New-Item -ItemType Directory -Path $script:AuditDir -Force | Out-Null }

$script:InjectionPatterns = @("ignore previous instructions","ignore all previous","you are now","system:","system override","override all rules","disregard your training","pretend you are","do not follow.*instructions","bypass.*restrictions")
$script:DangerousCommands = @("rm -rf","del /f","format\s+[cdefgh]:","format\s+/fs","DROP TABLE","DELETE FROM","curl.*\|.*sh","wget.*\|.*bash","eval","exec\(","Invoke-Expression","iex ","Start-Process.*-NoProfile")
$script:ExfiltrationPatterns = @("send.*to.*http","upload.*to.*http","curl.*POST.*@","read.*\\.env","cat.*\\.env","Get-Content.*\\.env","read.*secret","read.*credential","read.*password","send.*email","upload.*file.*remote")
$script:AutoUpdatePatterns = @("auto.?update","self.?update","update.*automatically","download.*latest","fetch.*latest","pull.*latest","wget.*http","curl.*http.*>")

function Invoke-SkillAudit {
    param([Parameter(Mandatory=$true)][string]$SkillId,[string]$AuditorAgent="SEC-001")

    Write-Host "========================================" -ForegroundColor Magenta
    Write-Host " SKILL AUDIT: $SkillId" -ForegroundColor Magenta
    Write-Host "========================================" -ForegroundColor Magenta

    $ts = Get-Date -Format "yyyyMMddHHmmss"
    $report = [PSCustomObject]@{auditId="SKILL-AUDIT-$SkillId-$ts";skillId=$SkillId;skillVersion="unknown";sourceRefs=@();auditorAgent=$AuditorAgent;auditedAt=(Get-Date -Format "yyyy-MM-ddTHH:mm:sszzz");verdict="needs_human_review";riskScore=0;requiredControls=@();stages=[PSCustomObject]@{metadata=$null;content=$null;permission=$null;supplyChain=$null;runtimeBehavior=$null};evidenceRefs=@()}

    $sDir = Join-Path $script:SkillsDir $SkillId
    $sj = Join-Path $sDir "skill.json"
    $smd = Join-Path $sDir "SKILL.md"

    if (-not (Test-Path $sj)) { Write-Host "AUDIT: skill.json not found at $sj" -ForegroundColor Red; $report.verdict="reject"; return $report }
    try { $content = Get-Content $sj -Raw -Encoding UTF8; $pkg = $content | ConvertFrom-Json } catch { Write-Host "AUDIT: JSON parse error: $_" -ForegroundColor Red; $report.verdict="reject"; return $report }
    $report.skillVersion = $pkg.version
    $report.sourceRefs = if ($pkg.sourceRefs) { $pkg.sourceRefs } else { @() }
    $instructions = if (Test-Path $smd) { Get-Content $smd -Raw -Encoding UTF8 } else { "" }

    # === STAGE A: Metadata ===
    Write-Host "`n--- A: Metadata ---" -ForegroundColor Cyan
    $mf=@(); $mp=$true
    if (-not $pkg.skillId) { $mf+=@{riskId="SKILL-RISK-027";severity="high";description="Missing skillId"}; $mp=$false }
    if (-not $pkg.version) { $mf+=@{riskId="SKILL-RISK-027";severity="medium";description="Missing version"}; $mp=$false }
    if (-not $pkg.sourceRefs -or $pkg.sourceRefs.Count -eq 0) { $mf+=@{riskId="SKILL-RISK-027";severity="medium";description="No source references"}; $mp=$false }
    if ($pkg.status -eq "quarantine") { $mf+=@{riskId="SKILL-RISK-029";severity="critical";description="Skill is quarantined"}; $mp=$false }
    if ($pkg.status -eq "deprecated") { $mf+=@{riskId="SKILL-RISK-027";severity="high";description="Skill is deprecated"}; $mp=$false }
    $report.stages.metadata = [PSCustomObject]@{passed=$mp;findings=$mf}
    if (-not $mp) { $report.riskScore += 25 }
    Write-Host "  $(if($mp){"PASS"}else{"FAIL -- $($mf.Count) findings"})" -ForegroundColor $(if($mp){"Green"}else{"Red"})

    # === STAGE B: Content ===
    Write-Host "`n--- B: Content ---" -ForegroundColor Cyan
    $cf=@(); $cp=$true
    if (-not $instructions) { $cf+=@{riskId="SKILL-RISK-027";severity="high";description="No SKILL.md"}; $cp=$false }
    else {
        foreach ($p in $script:InjectionPatterns) { if ($instructions -match $p) { $cf+=@{riskId="SKILL-RISK-001";severity="critical";description="Injection pattern";pattern=$p}; $cp=$false; $report.riskScore+=30 } }
        foreach ($p in $script:DangerousCommands) { if ($instructions -match $p) { $cf+=@{riskId="SKILL-RISK-009";severity="critical";description="Dangerous command";pattern=$p}; $cp=$false; $report.riskScore+=35 } }
        foreach ($p in $script:ExfiltrationPatterns) { if ($instructions -match $p) { $cf+=@{riskId="SKILL-RISK-013";severity="critical";description="Exfiltration pattern";pattern=$p}; $cp=$false; $report.riskScore+=35 } }
        if (($instructions -match "override.*(user|factory|system|agent).*instructions") -and ($instructions -notmatch "never\s+override")) { $cf+=@{riskId="SKILL-RISK-004";severity="critical";description="Instruction override attempt"}; $cp=$false; $report.riskScore+=30 }
    }
    $report.stages.content = [PSCustomObject]@{passed=$cp;findings=$cf}
    Write-Host "  $(if($cp){"PASS"}else{"FAIL -- $($cf.Count) findings"})" -ForegroundColor $(if($cp){"Green"}else{"Red"})

    # === STAGE C: Permission ===
    Write-Host "`n--- C: Permission ---" -ForegroundColor Cyan
    $pf=@(); $pp=$true
    if ($pkg.allowedTools -is [array]) {
        $dt = @("shell_command","apply_patch","execute","spawn"); $ob = @()
        foreach ($t in $pkg.allowedTools) { if ($t -in $dt) { $ob += $t } }
        if ($ob.Count -gt 2) { $pf+=@{riskId="SKILL-RISK-023";severity="high";description="Overbroad tools: $($ob -join ',')"}; $pp=$false; $report.riskScore+=15 }
    }
    if ($pkg.applicableAgents -is [array] -and $pkg.applicableAgents.Count -gt 5) { $pf+=@{riskId="SKILL-RISK-024";severity="medium";description="$($pkg.applicableAgents.Count) agents is overbroad"}; $pp=$false; $report.riskScore+=5 }
    if ($pkg.forbiddenActions -is [array] -and $pkg.forbiddenActions.Count -eq 0) { $pf+=@{riskId="SKILL-RISK-030";severity="low";description="No forbidden actions"} }
    $report.stages.permission = [PSCustomObject]@{passed=$pp;findings=$pf}
    Write-Host "  $(if($pp){"PASS"}else{"FAIL -- $($pf.Count) findings"})" -ForegroundColor $(if($pp){"Green"}else{"Red"})

    # === STAGE D: Supply-chain ===
    Write-Host "`n--- D: Supply-chain ---" -ForegroundColor Cyan
    $sf=@(); $sp=$true
    foreach ($p in $script:AutoUpdatePatterns) { if ($instructions -match $p) { $sf+=@{riskId="SKILL-RISK-017";severity="high";description="Auto-update risk";pattern=$p}; $sp=$false; $report.riskScore+=20 } }
    if ($instructions -match "(wget|curl)\s+http") { $sf+=@{riskId="SKILL-RISK-019";severity="high";description="External script download"}; $sp=$false; $report.riskScore+=20 }
    if ($instructions -match "(npm install|pip install|gem install)\s+\w+$" -and $instructions -notmatch "@\d") { $sf+=@{riskId="SKILL-RISK-018";severity="medium";description="Unpinned dependency"} }
    $hasHash = ($instructions -match "sha256|SHA256") -or (($pkg.sourceRefs -join ' ') -match "sha256")
    if (-not $hasHash) { $sf+=@{riskId="SKILL-RISK-020";severity="medium";description="No hash/signature"} }
    $report.stages.supplyChain = [PSCustomObject]@{passed=$sp;findings=$sf}
    Write-Host "  $(if($sp){"PASS"}else{"FAIL -- $($sf.Count) findings"})" -ForegroundColor $(if($sp){"Green"}else{"Red"})

    # === STAGE E: Runtime Behavior ===
    Write-Host "`n--- E: Runtime Behavior ---" -ForegroundColor Cyan
    $rf=@(); $rp=$true
    if (-not $pkg.verificationMethod) { $rf+=@{riskId="SKILL-RISK-032";severity="medium";description="No verifier"}; $rp=$false; $report.riskScore+=10 }
    if (-not $pkg.failureModes -or ($pkg.failureModes -is [array] -and $pkg.failureModes.Count -eq 0)) { $rf+=@{riskId="SKILL-RISK-031";severity="low";description="No failure modes"} }
    $hasRollback = $pkg.rollbackPolicy -and $pkg.rollbackPolicy.canRollback
    if (-not $hasRollback) { $rf+=@{riskId="SKILL-RISK-030";severity="low";description="No rollback policy"} }
    if ($pkg.trustLevel -eq "AVAILABLE" -and $pkg.status -ne "runtimeVerified") { $rf+=@{riskId="SKILL-RISK-006";severity="medium";description="Needs runtime verification"}; $report.requiredControls += "human_approval" }
    $report.stages.runtimeBehavior = [PSCustomObject]@{passed=$rp;findings=$rf}
    Write-Host "  $(if($rp){"PASS"}else{"FAIL -- $($rf.Count) findings"})" -ForegroundColor $(if($rp){"Green"}else{"Red"})

    # === STAGE F: Verdict ===
    Write-Host "`n--- F: Verdict ---" -ForegroundColor Cyan
    $allFindings = @($mf) + @($cf) + @($pf) + @($sf) + @($rf) | Where-Object { $_ -is [System.Collections.IDictionary] -or $_ -is [hashtable] }
    $crit = ($allFindings | Where-Object { $_.severity -eq "critical" } | Measure-Object).Count
    $high = ($allFindings | Where-Object { $_.severity -eq "high" } | Measure-Object).Count
    $allPassed = $mp -and $cp -and $pp -and $sp -and $rp
    if ($crit -gt 0) { $report.verdict = "quarantine" }
    elseif ($high -ge 3) { $report.verdict = "reject" }
    elseif (-not $allPassed) { $report.verdict = "pass_with_controls" }
    elseif ($pkg.trustLevel -eq "AVAILABLE") { $report.verdict = "needs_human_review" }
    else { $report.verdict = "pass" }
    if ($report.riskScore -gt 100) { $report.riskScore = 100 }
    $vCol = switch($report.verdict){"pass"{"Green"}"pass_with_controls"{"Yellow"}"needs_human_review"{"Yellow"}"reject"{"Red"}"quarantine"{"Magenta"}default{"White"}}
    Write-Host "  Verdict: $($report.verdict.ToUpper()) | Risk: $($report.riskScore)/100" -ForegroundColor $vCol

    $auditPath = Join-Path $script:AuditDir "$($report.auditId).json"
    $report | ConvertTo-Json -Depth 5 | Out-File -FilePath $auditPath -Encoding UTF8
    $report.evidenceRefs += $auditPath
    Write-Host "  Saved: $auditPath" -ForegroundColor Gray
    return $report
}

Write-Verbose "Skill Audit Pipeline loaded."

