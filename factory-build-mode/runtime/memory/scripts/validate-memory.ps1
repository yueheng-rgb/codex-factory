# validate-memory.ps1 — Validate .codex-factory/ memory integrity
param([Parameter(Mandatory)]$ProjectPath, [switch]$Json)

$cfDir = Join-Path $ProjectPath ".codex-factory"
$issues = @()
$warnings = @()
$result = @{valid=$true;issues=@();warnings=@()}

function Add-Issue($id, $msg, $severity="ERROR") {
    $issue = @{id=$id;message=$msg;severity=$severity;file="";field=""}
    $script:issues += $issue
    if ($severity -eq "ERROR") { $script:result.valid = $false }
}

# Check .codex-factory/ exists
if (-not (Test-Path $cfDir)) { Add-Issue "V01" ".codex-factory/ directory not found"; return ($result | ConvertTo-Json) }

# Required files
$required = @("project-state.json","decision-log.jsonl","task-graph.json","architecture-map.json","requirement-map.json","active-risks.json","verifier-history.json","handoff-packet.json")
foreach ($f in $required) {
    $fp = Join-Path $cfDir $f
    if (-not (Test-Path $fp)) { Add-Issue "V02" "Missing required file: $f" }
}

# Validate project-state.json
$statePath = Join-Path $cfDir "project-state.json"
if (Test-Path $statePath) {
    try { $state = Get-Content $statePath -Raw | ConvertFrom-Json }
    catch { Add-Issue "V03" "project-state.json is not valid JSON: $_" }
    if ($state) {
        if (-not $state.projectId) { Add-Issue "V04" "project-state.json missing projectId" }
        if (-not $state.version) { Add-Issue "V05" "project-state.json missing version"; $warnings += "V05: version missing" }
        if (-not $state.currentStage) { Add-Issue "V06" "project-state.json missing currentStage" }
        if (-not $state.updatedAt) { Add-Issue "V07" "project-state.json missing updatedAt"; $warnings += "V07: updatedAt missing" }
        $projectId = $state.projectId
    }
}

# Check projectId consistency across files
if ($projectId) {
    $idFiles = @("task-graph.json","architecture-map.json","requirement-map.json","active-risks.json","verifier-history.json","handoff-packet.json")
    foreach ($f in $idFiles) {
        $fp = Join-Path $cfDir $f
        if (Test-Path $fp) {
            try {
                $content = Get-Content $fp -Raw | ConvertFrom-Json
                if ($content.projectId -and $content.projectId -ne $projectId) {
                    Add-Issue "V08" "projectId mismatch: $f has '$($content.projectId)', expected '$projectId'"
                }
            } catch {}
        }
    }
}

# Validate handoff-packet.json
$handoffPath = Join-Path $cfDir "handoff-packet.json"
if (Test-Path $handoffPath) {
    try { $handoff = Get-Content $handoffPath -Raw | ConvertFrom-Json }
    catch { Add-Issue "V09" "handoff-packet.json is not valid JSON: $_" }
    if ($handoff) {
        if (-not $handoff.generatedAt) { Add-Issue "V10" "handoff-packet.json missing generatedAt" }
        # Stale handoff check (>24 hours)
        if ($handoff.generatedAt) {
            try {
                $age = (Get-Date) - [DateTime]::Parse($handoff.generatedAt)
                if ($age.TotalHours -gt 24) { $warnings += "V11: handoff-packet.json is stale (>24 hours old)" }
            } catch {}
        }
        if (-not $handoff.evidencePaths -or $handoff.evidencePaths.Count -eq 0) {
            $warnings += "V12: handoff-packet.json has no evidence paths"
        }
        if (-not $handoff.forbiddenAssumptions) { $warnings += "V13: handoff-packet.json missing forbiddenAssumptions" }
        if (-not $handoff.rejectedClaims) { $warnings += "V14: handoff-packet.json missing rejectedClaims" }
    }
}

# Validate task-graph.json
$tgPath = Join-Path $cfDir "task-graph.json"
if (Test-Path $tgPath) {
    try { $tg = Get-Content $tgPath -Raw | ConvertFrom-Json }
    catch { Add-Issue "V15" "task-graph.json is not valid JSON: $_" }
    if ($tg -and $tg.tasks) {
        $statuses = $tg.tasks | Where-Object { $_.status -eq "IN_PROGRESS" }
        if ($statuses.Count -gt 1) { $warnings += "V16: Multiple tasks IN_PROGRESS ($($statuses.Count)) — potential conflict" }
        $completed = ($tg.tasks | Where-Object { $_.status -eq "COMPLETED" }).Count
        if ($tg.completedTasks -ne $completed) { $warnings += "V17: completedTasks ($($tg.completedTasks)) does not match actual completed ($completed)" }
    }
}

# Validate decision-log.jsonl
$dlPath = Join-Path $cfDir "decision-log.jsonl"
if (Test-Path $dlPath) {
    $lines = Get-Content $dlPath | Where-Object { $_.Trim() -ne "" }
    foreach ($line in $lines) {
        try { $entry = $line | ConvertFrom-Json }
        catch { $warnings += "V18: Malformed JSON line in decision-log.jsonl: $($line.Substring(0,[Math]::Min(80,$line.Length)))" }
    }
}

# Validate verifier-history.json
$vhPath = Join-Path $cfDir "verifier-history.json"
if (Test-Path $vhPath) {
    try { $vh = Get-Content $vhPath -Raw | ConvertFrom-Json }
    catch { Add-Issue "V19" "verifier-history.json is not valid JSON: $_" }
    if ($vh -and $vh.entries) {
        foreach ($e in $vh.entries) {
            if (-not $e.command) { $warnings += "V20: verifier-history entry missing command" }
            if (-not $e.result) { $warnings += "V21: verifier-history entry missing result" }
        }
    }
}

# Validate active-risks.json
$arPath = Join-Path $cfDir "active-risks.json"
if (Test-Path $arPath) {
    try { $ar = Get-Content $arPath -Raw | ConvertFrom-Json }
    catch { Add-Issue "V22" "active-risks.json is not valid JSON: $_" }
    if ($ar -and $ar.risks) {
        $resolvedNoEvidence = $ar.risks | Where-Object { $_.status -eq "RESOLVED" -and (-not $_.resolutionEvidence) }
        if ($resolvedNoEvidence) { $warnings += "V23: $($resolvedNoEvidence.Count) risks resolved without evidence" }
    }
}

# Compressed summary detection (heuristic: look for summary files that aren't structured)
$summaryFiles = Get-ChildItem $cfDir -Filter "*summary*" -File -ErrorAction SilentlyContinue
if ($summaryFiles) { $warnings += "V24: Summary files detected in .codex-factory/ — compressed summaries are NOT evidence" }

$result.issues = $issues
$result.warnings = $warnings
$result.valid = ($issues | Where-Object { $_.severity -eq "ERROR" }).Count -eq 0

if ($Json) { $result | ConvertTo-Json -Depth 4 } else {
    Write-Host "Validation: $(if($result.valid){'PASS'}else{'FAIL'})"
    Write-Host "  Errors: $(($issues|Where-Object{$_.severity-eq'ERROR'}).Count)"
    Write-Host "  Warnings: $($warnings.Count)"
    foreach ($i in $issues) { Write-Host "  [$($i.severity)] $($i.id): $($i.message)" -ForegroundColor $(if($i.severity-eq'ERROR'){'Red'}else{'Yellow'}) }
    foreach ($w in $warnings) { Write-Host "  [WARN] $w" -ForegroundColor Yellow }
}
exit $(if($result.valid){0}else{1})
