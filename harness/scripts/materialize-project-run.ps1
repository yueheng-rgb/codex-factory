# materialize-project-run.ps1 - Phase 6C-U2-A
param(
    [Parameter(Mandatory=$true)][string]$ProjectRequest,
    [Parameter(Mandatory=$true)][string]$RunId
)
$ErrorActionPreference = "Stop"
$H = Split-Path -Parent (Split-Path -Parent $PSCommandPath)
$pr = Get-Content $ProjectRequest -Raw -Encoding UTF8 | ConvertFrom-Json
$runDir = Join-Path $H "runs\$RunId"
if (Test-Path $runDir) { Write-Error "Run directory already exists: $runDir"; exit 3 }
$now = (Get-Date).ToString("o")
$phase = if ($pr.phase) { $pr.phase } else { "Phase 6C-U2-A" }

$dirs = @("$runDir\prompts"); $wc = $pr.workers.Count; for ($i=1; $i -le $wc; $i++) { $dirs += "$runDir\workspace\worker-$i\src" }; $dirs += @("$runDir\worker-interface-manifests","$runDir\source-derived-interface-manifests","$runDir\canonical-integrated\src","$runDir\reports")
foreach ($d in $dirs) { New-Item -ItemType Directory -Path $d -Force | Out-Null }

# TASKS.json
$tl = [System.Collections.ArrayList]@()
$ti = 1
foreach ($w in $pr.workers) {
    $tid = "T-$($ti.ToString('000'))"
    $exps = if ($w.exports) { $w.exports | % { @{interfaceId=$_.interfaceId;name=$_.name;file=$_.file} } } else { @() }
    $imps = if ($w.imports) { $w.imports | % { @{interfaceId=$_.interfaceId;name=$_.name;fromWorkerId=$_.fromWorkerId;file=$_.file} } } else { @() }
    [void]$tl.Add(@{taskId=$tid;workerId=$w.workerId;description=$w.taskDescription;ownedPaths=$w.ownedPaths;exports=$exps;imports=$imps;acceptanceCriteria=@("AC-$($ti.ToString('000'))")})
    $ti++
}
$taskObj = @{schemaVersion="6B-R3";runId=$RunId;phase=$phase;generatedAt=$now;tasks=$tl}
$taskObj | ConvertTo-Json -Depth 5 | Set-Content "$runDir\TASKS.json" -Encoding UTF8

# ACCEPTANCE.json
$al = [System.Collections.ArrayList]@()
$ai = 1
foreach ($a in $pr.acceptance) {
    $aid = if ($a.acceptanceId) { $a.acceptanceId } else { "AC-$($ai.ToString('000'))" }
    $tids = if ($ai -le 2) { @("T-$($ai.ToString('000'))") } else { @("T-001","T-002") }
    $ev = if ($ai -le 2) { @("source_output","interface_manifest") } else { @("validate_state_output") }
    $gates = if ($ai -le 2) { @("contractLock","interfaceDrift","manifestHonesty") } else { @("hashChain","tokenProofs","integrationGate") }
    [void]$al.Add(@{acceptanceId=$aid;description=$a.description;taskIds=$tids;requiredEvidence=$ev;gateChecks=$gates})
    $ai++
}
$accObj = @{schemaVersion="6B-R3";runId=$RunId;phase=$phase;generatedAt=$now;acceptance=$al}
$accObj | ConvertTo-Json -Depth 4 | Set-Content "$runDir\ACCEPTANCE.json" -Encoding UTF8

# OWNERSHIP.json
$owners = @{}
foreach ($w in $pr.workers) {
    $forbid = @()
    foreach ($ow in $pr.workers) { if ($ow.workerId -ne $w.workerId) { $forbid += "$($ow.workerId)/*" } }
    $forbid += "canonical-integrated/*"
    $owners[$w.workerId] = @{workerId=$w.workerId;ownedPaths=$w.ownedPaths;forbiddenWritePaths=$forbid;allowedReadPaths=@("$($w.workerId)/*","interface-contract.lock.json")}
}
$ownObj = @{schemaVersion="6B-R3";runId=$RunId;phase=$phase;generatedAt=$now;ownershipMap=$owners}
$ownObj | ConvertTo-Json -Depth 4 | Set-Content "$runDir\OWNERSHIP.json" -Encoding UTF8

# Interface contract
$ifaces = @()
foreach ($w in $pr.workers) {
    if ($w.exports) {
        foreach ($ex in $w.exports) {
            $consumers = @($pr.workers | ? { $_.workerId -ne $w.workerId -and $_.imports -and ($_.imports | ? { $_.interfaceId -eq $ex.interfaceId }) } | % { $_.workerId })
            $sig = if ($ex.signature) { $ex.signature } else { @{kind="function";params=@();returns="unknown"} }
            $ifaces += @{interfaceId=$ex.interfaceId;name=$ex.name;providerWorkerId=$w.workerId;consumerWorkerIds=[array]$consumers;file=$ex.file;signature=$sig}
        }
    }
}
$contractObj = @{schemaVersion="6B-R3";contractId="$RunId-contract";projectName=$pr.projectName;runId=$RunId;phase=$phase;locked=$true;lockedAt=$now;interfaces=$ifaces}
$contractObj | ConvertTo-Json -Depth 5 | Set-Content "$runDir\interface-contract.lock.json" -Encoding UTF8

$crossCount = ($ifaces | ? { $_.consumerWorkerIds.Count -gt 0 } | Measure).Count

# Worker prompts
$utf8 = New-Object System.Text.UTF8Encoding($false)
$wi = 1
foreach ($w in $pr.workers) {
    $wid = $w.workerId; $tid = "T-$($wi.ToString('000'))"
    $ownedRows = ($w.ownedPaths | % { "| ``$_`` | Worker $wid source |" }) -join [Environment]::NewLine
    if ($w.exports) { $expRows = ($w.exports | % { "| ``$($_.interfaceId)`` | ``$($_.name)`` | ``$($_.file)`` | $($_.signature.kind)( $([string]::Join(", ", $_.signature.params)) ) -> $($_.signature.returns) |" }) -join [Environment]::NewLine } else { $expRows = "| (none) | (none) | (none) | (none) |" }
    if ($w.imports) { $impRows = ($w.imports | % { "| ``$($_.interfaceId)`` | ``$($_.name)`` | ``$($_.fromWorkerId)`` | ``$($_.file)`` |" }) -join [Environment]::NewLine } else { $impRows = "| (none) | (none) | (none) | (none) |" }
    $forbidList = ($owners[$wid].forbiddenWritePaths | % { "- Do NOT write to: ``$_``" }) -join [Environment]::NewLine
    
    $accItems = @($pr.acceptance | ? { $_.description -match $wid -or $_.acceptanceId -like "*$wi*" })
    if ($accItems.Count -eq 0) { $accItems = $pr.acceptance }
    $accRows = ($accItems | % { "- **$($_.acceptanceId)**: $($_.description)" }) -join [Environment]::NewLine
    
    $prompt = "`# Worker $wid 闁?$($pr.projectName)`r`n`r`n" +
      "`#`# Project Context`r`n" +
      "- **Project**: $($pr.projectName)`r`n" +
      "- **Run**: $RunId`r`n" +
      "- **Phase**: $phase`r`n" +
      "- **Your role**: Worker $wid`r`n`r`n" +
      "`#`# Task Assignment`r`n`r`n" +
      "`#`#`# Your Task: $tid`r`n" +
      "**Description**: $($w.taskDescription)`r`n`r`n" +
      "`#`#`# Files You Own`r`n" +
      "| File | Purpose |`r`n" +
      "|------|---------|`r`n" +
      "$ownedRows`r`n`r`n" +
      "`#`#`# Interfaces You Must Provide (Exports)`r`n" +
      "| Interface ID | Function | File | Signature |`r`n" +
      "|---|---|---|---|`r`n" +
      "$expRows`r`n`r`n" +
      "`#`#`# Interfaces You May Import (Dependencies)`r`n" +
      "| Interface ID | Function | From Worker | File |`r`n" +
      "|---|---|---|---|`r`n" +
      "$impRows`r`n`r`n" +
      "`#`# Contract Lock`r`n" +
      "The interface contract is **locked** in ``interface-contract.lock.json``. Do NOT change exported function names or signatures.`r`n`r`n" +
      "`#`# Boundaries (OWNERSHIP)`r`n" +
      "$forbidList`r`n`r`n" +
      "`#`# Acceptance Criteria`r`n" +
      "$accRows`r`n`r`n" +
      "`#`# Required Deliverables`r`n" +
      "1. Your source file(s) in ``workspace/$wid/src/```r`n" +
      "2. Your ``worker-interface-manifest.json`` listing all actual exports`r`n" +
      "3. Your ``worker-implementation-manifest.json`` listing all files produced`r`n" +
      "4. Do NOT write to any other worker``'``s workspace`r`n" +
      "5. Do NOT write to ``canonical-integrated/```r`n`r`n" +
      "`#`# Remember`r`n" +
      "- You are one of multiple Workers. Other Workers depend on your exported interfaces matching the locked contract.`r`n" +
      "- If you discover an issue with the contract, report it via handoff.`r`n" +
      "- The Validator will verify your outputs independently.`r`n"
    $promptPath = "$runDir\prompts\$wid-prompt.md"
    [System.IO.File]::WriteAllText($promptPath, $prompt, $utf8)
    Write-Host "  Prompt: $promptPath"
    $wi++
}

# README.md
$readme = "# $($pr.projectName) 闁?$RunId`r`n`r`n- **Phase**: $phase`r`n- **Generated**: $now`r`n`r`n## Structure`r`n- TASKS.json 闁?$($tl.Count) tasks`r`n- ACCEPTANCE.json 闁?$($al.Count) items`r`n- OWNERSHIP.json 闁?$($owners.Count) workers`r`n- interface-contract.lock.json 闁?$($ifaces.Count) interfaces`r`n- prompts/ 闁?worker prompts`r`n`r`n## Next Steps`r`n1. Review generated files`r`n2. Run via Orchestrator with spawn_agent Workers`r`n3. Run validators`r`n4. Integrate and produce final audit bundle`r`n"
[System.IO.File]::WriteAllText("$runDir\README.md", $readme, $utf8)

$summary = @{
    phase=$phase;runId=$RunId;projectName=$pr.projectName
    runDir=(Resolve-Path $runDir).Path;tasksCount=$tl.Count
    acceptanceCount=$al.Count;ownershipCount=$owners.Count
    contractInterfaceCount=$ifaces.Count;crossWorkerDependencyCount=$crossCount
    contractLocked=$true
    workerPromptPaths=@($pr.workers | % { "$runDir\prompts\$($_.workerId)-prompt.md" })
    generatedAt=$now
} | ConvertTo-Json -Depth 3
Write-Output $summary
exit 0