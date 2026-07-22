# Codex Factory V4.2 — Agent Execution Runtime
# Takes agent_execution_plan.json and converts it into an executable multi-agent run workspace.
# Usage:
#   powershell -File runtime/agent-execution-runtime.ps1 -Command start -PlanDir outputs/V4_1/demo-admin-system
#   powershell -File runtime/agent-execution-runtime.ps1 -Command status -RunId runs/admin-001
#   powershell -File runtime/agent-execution-runtime.ps1 -Command create-handoff-template -RunId runs/admin-001 -WorkerId worker-backend
#   powershell -File runtime/agent-execution-runtime.ps1 -Command validate-handoff -RunId runs/admin-001 -HandoffFile handoffs/worker-backend-handoff.json
#   powershell -File runtime/agent-execution-runtime.ps1 -Command collect-artifacts -RunId runs/admin-001
#   powershell -File runtime/agent-execution-runtime.ps1 -Command validate -RunId runs/admin-001
#   powershell -File runtime/agent-execution-runtime.ps1 -Command integrate -RunId runs/admin-001
#   powershell -File runtime/agent-execution-runtime.ps1 -Command close -RunId runs/admin-001

param(
    [Parameter(Mandatory=$true)]
    [ValidateSet("start","status","create-handoff-template","validate-handoff","collect-artifacts","validate","integrate","close","import-live-handoff","validate-live-handoff","summarize-live-run")]
    [string]$Command,
    [string]$PlanDir,
    [string]$RunId,
    [string]$WorkerId,
    [string]$HandoffFile,
    [ValidateSet("manual","local-script","agent-adapter")]
    [string]$Mode = "manual",
    [switch]$Json
)

$ErrorActionPreference = "Stop"
$RepoRoot = (Get-Location).Path

# V4 is kept as a compatibility runtime.  It must fail closed because a handoff
# is a worker claim, not evidence.  The V5 factoryctl runtime is the authoritative
# path for native orchestration and independently verified acceptance.
$LegacyRuntimeVersion = "4.2-compat-hardened"

function Assert-SafeRunId([string]$id) {
    if ([string]::IsNullOrWhiteSpace($id) -or $id -notmatch '^[A-Za-z0-9][A-Za-z0-9._-]{0,127}$' -or $id -in @('.', '..')) {
        throw "Unsafe run id '$id'. Use only letters, numbers, dot, underscore, and hyphen (no path separators)."
    }
}

function Get-AbsolutePathInside([string]$basePath, [string]$relativePath) {
    if ([string]::IsNullOrWhiteSpace($relativePath) -or [IO.Path]::IsPathRooted($relativePath)) { return $null }
    try {
        $base = [IO.Path]::GetFullPath($basePath).TrimEnd([IO.Path]::DirectorySeparatorChar, [IO.Path]::AltDirectorySeparatorChar)
        $candidate = [IO.Path]::GetFullPath((Join-Path $base $relativePath))
        $prefix = $base + [IO.Path]::DirectorySeparatorChar
        if (-not $candidate.StartsWith($prefix, [StringComparison]::OrdinalIgnoreCase)) { return $null }
        return $candidate
    } catch {
        return $null
    }
}

function Get-ArtifactEvidence([string]$runId, [string]$claim) {
    $result = [ordered]@{
        claim = $claim
        exists = $false
        valid_path = $false
        relative_path = $null
        size = 0
        sha256 = $null
        reason = $null
    }

    if ([string]::IsNullOrWhiteSpace($claim)) {
        $result.reason = "empty_artifact_claim"
        return [pscustomobject]$result
    }

    $normalized = $claim.Replace('/', [IO.Path]::DirectorySeparatorChar).Replace('\', [IO.Path]::DirectorySeparatorChar)
    $artifactPrefix = "artifacts" + [IO.Path]::DirectorySeparatorChar
    if ($normalized.StartsWith($artifactPrefix, [StringComparison]::OrdinalIgnoreCase)) {
        $normalized = $normalized.Substring($artifactPrefix.Length)
    }

    $artifactRoot = Join-Path $RepoRoot "runs/$runId/artifacts"
    $candidate = Get-AbsolutePathInside $artifactRoot $normalized
    if (-not $candidate) {
        $result.reason = "artifact_path_must_be_relative_and_inside_run_artifacts"
        return [pscustomobject]$result
    }

    $result.valid_path = $true
    $result.relative_path = "artifacts/" + ($normalized -replace '\\','/')
    if ((Split-Path $candidate -Leaf) -eq "artifact-index.json") {
        $result.reason = "runtime_generated_index_cannot_be_worker_evidence"
        return [pscustomobject]$result
    }
    if (-not (Test-Path -LiteralPath $candidate -PathType Leaf)) {
        $result.reason = "physical_artifact_missing"
        return [pscustomobject]$result
    }

    $file = Get-Item -LiteralPath $candidate
    $result.exists = $true
    $result.size = [int64]$file.Length
    $result.sha256 = Get-Sha256 $candidate
    if ($file.Length -le 0) {
        $result.exists = $false
        $result.reason = "physical_artifact_empty"
    }
    return [pscustomobject]$result
}

function Get-ChangedFileEvidence([string]$path) {
    $result = [ordered]@{
        path = $path
        exists = $false
        valid_path = $false
        size = 0
        sha256 = $null
        reason = $null
    }
    $candidate = Get-AbsolutePathInside $RepoRoot $path
    if (-not $candidate) {
        $result.reason = "changed_file_must_be_relative_and_inside_project"
        return [pscustomobject]$result
    }
    $result.valid_path = $true
    if (-not (Test-Path -LiteralPath $candidate -PathType Leaf)) {
        $result.reason = "changed_file_missing"
        return [pscustomobject]$result
    }
    $file = Get-Item -LiteralPath $candidate
    $result.exists = $true
    $result.size = [int64]$file.Length
    $result.sha256 = Get-Sha256 $candidate
    return [pscustomobject]$result
}

function Get-RequiredEvidenceNames($capsule, $validationPlan, $taskIds) {
    $required = @()
    if ($capsule -and $capsule.required_output_artifacts) {
        $required += @($capsule.required_output_artifacts)
    }
    if ($validationPlan -and $validationPlan.per_task_validation) {
        foreach ($task in $validationPlan.per_task_validation) {
            if ($task.task_id -in $taskIds -and $task.required_evidence) {
                $required += @($task.required_evidence)
            }
        }
    }
    return @($required | Where-Object { -not [string]::IsNullOrWhiteSpace([string]$_) } | Select-Object -Unique)
}

function Test-HandoffEvidence([string]$runId, $handoff, $capsule, $validationPlan) {
    $issues = @()
    $warnings = @()
    $artifactEvidence = @()
    $changedFileEvidence = @()

    if (-not $handoff.worker_id) { $issues += "Missing worker_id" }
    if (-not $handoff.task_ids -or $handoff.task_ids.Count -eq 0) { $issues += "Missing task_ids" }
    if ($handoff.status -notin @("COMPLETED","PARTIAL","BLOCKED","FAILED")) { $issues += "Invalid handoff status '$($handoff.status)'" }
    elseif ($handoff.status -ne "COMPLETED") { $warnings += "Handoff status is $($handoff.status); it cannot pass task validation or integration" }
    if (-not $handoff.next_agent) { $issues += "Missing next_agent" }
    if ([string]::IsNullOrWhiteSpace([string]$handoff.handoff_notes) -or $handoff.handoff_notes -match '(?i)FILL IN|placeholder|template') {
        $issues += "handoff_notes is empty or still a template placeholder"
    }

    if ($capsule) {
        if ($handoff.worker_id -ne $capsule.worker_id) { $issues += "worker_id does not match capsule" }
        $unexpectedTasks = @($handoff.task_ids | Where-Object { $_ -notin $capsule.assigned_tasks })
        if ($unexpectedTasks.Count -gt 0) { $issues += "Handoff contains unassigned task(s): $($unexpectedTasks -join ', ')" }
        if ($handoff.status -eq "COMPLETED") {
            $missingTasks = @($capsule.assigned_tasks | Where-Object { $_ -notin $handoff.task_ids })
            if ($missingTasks.Count -gt 0) { $issues += "COMPLETED handoff omits assigned task(s): $($missingTasks -join ', ')" }
        }
    } else {
        $issues += "Worker capsule not found"
    }

    if ($handoff.status -eq "COMPLETED") {
        if ($handoff.blockers -and $handoff.blockers.Count -gt 0) { $issues += "COMPLETED handoff contains blockers" }
        if ($handoff.validation_result -ne "PASS") { $issues += "COMPLETED handoff requires validation_result=PASS" }
        $testsRun = [int]$handoff.tests_run
        $testsPassed = [int]$handoff.tests_passed
        $testsFailed = [int]$handoff.tests_failed
        if ($testsRun -lt 0 -or $testsPassed -lt 0 -or $testsFailed -lt 0) { $issues += "Test counters cannot be negative" }
        if (($testsPassed + $testsFailed) -gt $testsRun) { $issues += "Test counters are inconsistent" }
        if ($testsFailed -gt 0) { $issues += "COMPLETED handoff reports failed tests" }
    }

    foreach ($claim in @($handoff.artifacts_produced)) {
        $evidence = Get-ArtifactEvidence $runId ([string]$claim)
        $artifactEvidence += $evidence
        if (-not $evidence.exists) { $issues += "Artifact '$claim' is not valid physical evidence: $($evidence.reason)" }
    }

    $requiredNames = Get-RequiredEvidenceNames $capsule $validationPlan @($handoff.task_ids)
    foreach ($required in $requiredNames) {
        if ($required -notin @($handoff.artifacts_produced)) {
            $issues += "Required artifact '$required' is not declared"
        } else {
            $physical = @($artifactEvidence | Where-Object { $_.claim -eq $required -and $_.exists })
            if ($physical.Count -eq 0) { $issues += "Required artifact '$required' has no physical file" }
        }
    }

    foreach ($changed in @($handoff.files_changed)) {
        $evidence = Get-ChangedFileEvidence ([string]$changed)
        $changedFileEvidence += $evidence
        if (-not $evidence.exists) { $issues += "Changed file '$changed' cannot be verified: $($evidence.reason)" }
        if ($capsule) {
            foreach ($forbidden in @($capsule.forbidden_files)) {
                if ($forbidden -and $forbidden -notmatch '^_' -and $changed -like $forbidden) {
                    $issues += "FILE BOUNDARY VIOLATION: '$changed' matches forbidden pattern '$forbidden'"
                }
            }
        }
    }

    return [pscustomobject]@{
        status = if ($issues.Count -gt 0) { "FAIL" } elseif ($warnings.Count -gt 0) { "WARN" } else { "PASS" }
        issues = @($issues | Select-Object -Unique)
        warnings = @($warnings | Select-Object -Unique)
        artifact_evidence = $artifactEvidence
        changed_file_evidence = $changedFileEvidence
    }
}

function Test-ValidationReceipt([string]$runId, [string]$taskId, [string]$method, [string]$workerId) {
    $result = [ordered]@{
        task_id = $taskId
        method = $method
        status = "PENDING"
        receipt_path = $null
        receipt_sha256 = $null
        issues = @()
    }
    if ($taskId -notmatch '^[A-Za-z0-9][A-Za-z0-9._-]{0,127}$' -or $method -notmatch '^[a-z_]+$') {
        $result.status = "FAIL"
        $result.issues += "Unsafe task id or validation method"
        return [pscustomobject]$result
    }

    $relative = "$taskId-$method-receipt.json"
    $validationRoot = Join-Path $RepoRoot "runs/$runId/validation"
    $receiptPath = Get-AbsolutePathInside $validationRoot $relative
    $result.receipt_path = "validation/$relative"
    if (-not $receiptPath -or -not (Test-Path -LiteralPath $receiptPath -PathType Leaf)) {
        $result.issues += "Missing independent $method receipt at validation/$relative"
        return [pscustomobject]$result
    }

    try {
        $receipt = Get-Content -LiteralPath $receiptPath -Raw | ConvertFrom-Json
    } catch {
        $result.status = "FAIL"
        $result.issues += "Validation receipt is not valid JSON"
        return [pscustomobject]$result
    }
    $result.receipt_sha256 = Get-Sha256 $receiptPath
    if ($receipt.task_id -ne $taskId) { $result.issues += "Receipt task_id does not match" }
    $verdict = if ($receipt.verdict) { [string]$receipt.verdict } else { [string]$receipt.status }
    if ($verdict -notin @("PASS","APPROVED")) { $result.issues += "Receipt verdict is not PASS/APPROVED" }

    if ($method -in @("test","static_check")) {
        if ($null -eq $receipt.exit_code -or [int]$receipt.exit_code -ne 0) { $result.issues += "$method receipt requires exit_code=0" }
        if ([string]::IsNullOrWhiteSpace([string]$receipt.command)) { $result.issues += "$method receipt requires a command" }
    }
    if ($method -eq "test") {
        if ($null -eq $receipt.tests_run -or [int]$receipt.tests_run -le 0) { $result.issues += "Test receipt requires tests_run > 0" }
        if ($null -eq $receipt.tests_failed -or [int]$receipt.tests_failed -ne 0) { $result.issues += "Test receipt requires tests_failed=0" }
        if ($null -eq $receipt.tests_passed -or [int]$receipt.tests_passed -ne [int]$receipt.tests_run) { $result.issues += "Test receipt requires tests_passed=tests_run" }
    }
    if ($method -in @("review","manual_instruction")) {
        if ([string]::IsNullOrWhiteSpace([string]$receipt.reviewer_id)) { $result.issues += "$method receipt requires reviewer_id" }
        if ($receipt.reviewer_id -eq $workerId) { $result.issues += "Worker cannot independently approve its own $method receipt" }
    }

    $result.status = if ($result.issues.Count -eq 0) { "PASS" } else { "FAIL" }
    return [pscustomobject]$result
}

function Test-GlobalGateReceipt([string]$runId, [string]$gateName) {
    $result = [ordered]@{ gate=$gateName; status="PENDING"; receipt_path=$null; receipt_sha256=$null; issues=@() }
    if ($gateName -notmatch '^[A-Za-z0-9][A-Za-z0-9._-]{0,127}$') {
        $result.status = "FAIL"
        $result.issues += "Unsafe gate name"
        return [pscustomobject]$result
    }
    $relative = "gates/$gateName-receipt.json"
    $validationRoot = Join-Path $RepoRoot "runs/$runId/validation"
    $receiptPath = Get-AbsolutePathInside $validationRoot $relative
    $result.receipt_path = "validation/$relative"
    if (-not $receiptPath -or -not (Test-Path -LiteralPath $receiptPath -PathType Leaf)) {
        $result.issues += "Missing required gate receipt at validation/$relative"
        return [pscustomobject]$result
    }
    try {
        $receipt = Get-Content -LiteralPath $receiptPath -Raw | ConvertFrom-Json
    } catch {
        $result.status = "FAIL"
        $result.issues += "Gate receipt is not valid JSON"
        return [pscustomobject]$result
    }
    $result.receipt_sha256 = Get-Sha256 $receiptPath
    if ($receipt.gate -and $receipt.gate -ne $gateName) { $result.issues += "Gate receipt name does not match" }
    $verdict = if ($receipt.verdict) { [string]$receipt.verdict } else { [string]$receipt.status }
    if ($verdict -notin @("PASS","APPROVED")) { $result.issues += "Gate receipt verdict is not PASS/APPROVED" }
    if ([string]::IsNullOrWhiteSpace([string]$receipt.verified_by)) { $result.issues += "Gate receipt requires verified_by" }
    $result.status = if ($result.issues.Count -eq 0) { "PASS" } else { "FAIL" }
    return [pscustomobject]$result
}

function Get-EvidenceSnapshot([string]$runId) {
    $entries = @()
    $runDir = Join-Path $RepoRoot "runs/$runId"
    $patterns = @(
        @{ type="input"; path=(Join-Path $runDir "input") },
        @{ type="capsule"; path=(Join-Path $runDir "worker-capsules") },
        @{ type="handoff"; path=(Join-Path $runDir "handoffs") },
        @{ type="live_handoff"; path=(Join-Path $runDir "live-handoffs") },
        @{ type="artifact"; path=(Join-Path $runDir "artifacts") },
        @{ type="validation_evidence"; path=(Join-Path $runDir "validation") }
    )
    foreach ($group in $patterns) {
        if (Test-Path -LiteralPath $group.path) {
            foreach ($file in @(Get-ChildItem -LiteralPath $group.path -File -Recurse | Sort-Object FullName)) {
                if ($file.Name -in @("artifact-index.json", "validation-result.json", "live-handoff-validation.json", "live-run-summary.json")) { continue }
                $relative = $file.FullName.Substring($runDir.Length).TrimStart('\','/') -replace '\\','/'
                $entries += [pscustomobject]@{ type=$group.type; path=$relative; size=[int64]$file.Length; sha256=(Get-Sha256 $file.FullName) }
            }
        }
    }

    $handoffDir = Join-Path $runDir "handoffs"
    if (Test-Path -LiteralPath $handoffDir) {
        foreach ($handoffFile in @(Get-ChildItem -LiteralPath $handoffDir -Filter '*.json' -File | Sort-Object FullName)) {
            try {
                $handoff = Get-Content -LiteralPath $handoffFile.FullName -Raw | ConvertFrom-Json
                foreach ($changed in @($handoff.files_changed | Sort-Object -Unique)) {
                    $evidence = Get-ChangedFileEvidence ([string]$changed)
                    if ($evidence.exists) {
                        $entries += [pscustomobject]@{ type="changed_file"; path=([string]$changed -replace '\\','/'); size=$evidence.size; sha256=$evidence.sha256 }
                    }
                }
            } catch {
                $entries += [pscustomobject]@{ type="invalid_handoff"; path=$handoffFile.Name; size=0; sha256="INVALID_JSON" }
            }
        }
    }

    $canonicalLines = @($entries | Sort-Object type,path | ForEach-Object { "$($_.type)|$($_.path)|$($_.size)|$($_.sha256)" })
    $sha = [Security.Cryptography.SHA256]::Create()
    try {
        $bytes = [Text.Encoding]::UTF8.GetBytes(($canonicalLines -join "`n"))
        $digest = ($sha.ComputeHash($bytes) | ForEach-Object { $_.ToString('x2') }) -join ''
    } finally {
        $sha.Dispose()
    }
    return [pscustomobject]@{ sha256=$digest; entries=$entries; entry_count=$entries.Count }
}

if ($RunId) { Assert-SafeRunId $RunId }

function Get-Sha256($path) {
    if (Test-Path $path) {
        $hash = (Get-FileHash -Path $path -Algorithm SHA256).Hash
        return $hash
    }
    return "FILE_NOT_FOUND"
}

function New-RunId {
    $ts = Get-Date -Format "yyyyMMdd-HHmmss"
    $rnd = Get-Random -Minimum 1000 -Maximum 9999
    return "run-$ts-$rnd"
}

function New-WorkerCapsule($worker, $allTasks, $validationPlan, $skillResult, $knowledgeResult) {
    $workerTaskIds = $worker.assigned_tasks
    $taskDetails = @($allTasks | Where-Object { $_.id -in $workerTaskIds })
    $validationMethods = @("artifact")
    foreach ($t in $taskDetails) {
        if ($t.type -match 'test|verification') { $validationMethods += "test" }
        if ($t.risk_level -in @("P0","P1")) { $validationMethods += "review" }
    }
    $validationMethods = @($validationMethods | Select-Object -Unique)

    # Capsule conflict detection
    $capsuleConflict = $false
    $capsuleConflictReason = @()
    foreach ($t in $taskDetails) {
        # If task is an auth module, check if auth files in own directory would be forbidden
        if ($t.type -eq "backend_module" -and $t.title -match "(?i)auth") {
            # Worker assigned auth task — ensure own auth files not forbidden
            $authPattern = "src/*/auth*"
            foreach ($forb in $worker.forbidden_files) {
                if ($forb -eq $authPattern) {
                    $capsuleConflict = $true
                    $capsuleConflictReason += "CONFLICT: Task '$($t.id) $($t.title)' requires auth files, but forbidden_files contains '$forb'. Refined: cross-worker boundaries only."
                }
            }
        }
    }
    # Refine forbidden_files: remove domain-keyword patterns, keep cross-worker + secrets
    $refinedForbidden = @("config/secrets*")
    # Add other workers' directories
    foreach ($w in $workerPlan.workers) {
        if ($w.id -ne $worker.id) {
            $refinedForbidden += "src/$($w.id)/*"
            $refinedForbidden += "tests/$($w.id)/*"
        }
    }
    if ($capsuleConflict) {
        $refinedForbidden += "_conflict_refined: removed keyword-based patterns (e.g. src/*/auth*), using cross-worker boundaries only"
    }

    $capsule = @{
        worker_id = $worker.id
        role = $worker.role
        assigned_tasks = $workerTaskIds
        allowed_files = $worker.allowed_files
        forbidden_files = $refinedForbidden
        input_artifacts = @(foreach ($t in $taskDetails) { "$($t.id)-input" })
        required_output_artifacts = @(foreach ($t in $taskDetails) { "$($t.id)-output" })
        validation_methods = $validationMethods
        related_skill_packs = if ($skillResult.selected_skill_packs) { $skillResult.selected_skill_packs } else { @() }
        related_knowledge_sources = if ($knowledgeResult.used) { $knowledgeResult.references } else { @() }
        handoff_required = $true
        capsule_conflict_detected = $capsuleConflict
        capsule_conflict_reason = $capsuleConflictReason
        capsule_boundary_refinement = if ($capsuleConflict) { "V4.4.1: forbidden_files refined from keyword-based to cross-worker patterns" } else { "clean" }
        completion_criteria = @(
            "All assigned tasks have output artifacts",
            "All tests pass (if applicable)",
            "Handoff file produced",
            "No forbidden file boundary violation"
        )
        forbidden_actions = @(
            "Cannot write entire repo",
            "Cannot bypass artifact gate",
            "Cannot self-approve final acceptance",
            "Cannot modify other workers' files"
        )
        non_claims = @(
            "Worker output is not final acceptance",
            "No artifact = no PASS"
        )
    }
    return $capsule
}

# ═══════════════════════════════════════════
# COMMAND DISPATCH
# ═══════════════════════════════════════════

switch ($Command) {

    "start" {
        if (-not $PlanDir) { Write-Error "start requires -PlanDir <path>"; exit 1 }
        if (-not (Test-Path "$PlanDir/agent_execution_plan.json")) {
            Write-Error "agent_execution_plan.json not found in $PlanDir. Run task-decomposition-engine.ps1 first."
            exit 1
        }

        $agentPlan = Get-Content "$PlanDir/agent_execution_plan.json" -Raw | ConvertFrom-Json
        $taskGraph = Get-Content "$PlanDir/task_graph.json" -Raw | ConvertFrom-Json
        $workerPlan = Get-Content "$PlanDir/worker_plan.json" -Raw | ConvertFrom-Json
        $validationPlan = Get-Content "$PlanDir/validation_plan.json" -Raw | ConvertFrom-Json
        $riskClass = if (Test-Path "$PlanDir/risk_classification.json") {
            Get-Content "$PlanDir/risk_classification.json" -Raw | ConvertFrom-Json
        } else { $null }

        $skillResult = @{ selected_skill_packs = @() }
        $knowledgeResult = @{ used = $false }

        $runId = if ($RunId) { $RunId } else { New-RunId }
        $runDir = "runs/$runId"
        New-Item -ItemType Directory -Force -Path "$runDir/input" | Out-Null
        New-Item -ItemType Directory -Force -Path "$runDir/worker-capsules" | Out-Null
        New-Item -ItemType Directory -Force -Path "$runDir/mailbox" | Out-Null
        New-Item -ItemType Directory -Force -Path "$runDir/handoffs" | Out-Null
        New-Item -ItemType Directory -Force -Path "$runDir/artifacts" | Out-Null
        New-Item -ItemType Directory -Force -Path "$runDir/validation" | Out-Null
        New-Item -ItemType Directory -Force -Path "$runDir/logs" | Out-Null

        # Copy input plans
        Copy-Item "$PlanDir/agent_execution_plan.json" "$runDir/input/"
        Copy-Item "$PlanDir/task_graph.json" "$runDir/input/"
        Copy-Item "$PlanDir/worker_plan.json" "$runDir/input/"
        Copy-Item "$PlanDir/validation_plan.json" "$runDir/input/"
        if (Test-Path "$PlanDir/risk_classification.json") { Copy-Item "$PlanDir/risk_classification.json" "$runDir/input/" }
        if (Test-Path "$PlanDir/evidence_requirements.json") { Copy-Item "$PlanDir/evidence_requirements.json" "$runDir/input/" }

        # Generate worker capsules
        $workers = $workerPlan.workers
        $allNodes = $taskGraph.nodes
        $capsuleIndex = @()
        foreach ($w in $workers) {
            $capsule = New-WorkerCapsule $w $allNodes $validationPlan $skillResult $knowledgeResult
            $capsule | ConvertTo-Json -Depth 5 | Out-File "$runDir/worker-capsules/$($w.id)-capsule.json" -Encoding utf8 -NoNewline
            $capsuleIndex += @{ worker_id=$w.id; capsule_file="worker-capsules/$($w.id)-capsule.json" }
        }

        # Create execution-run.json
        $execRun = @{
            run_id = $runId
            created_at = (Get-Date -Format "o")
            mode = $Mode
            source_plan_dir = $PlanDir
            source_plan_hashes = @{
                agent_execution_plan = Get-Sha256 "$PlanDir/agent_execution_plan.json"
                task_graph = Get-Sha256 "$PlanDir/task_graph.json"
                worker_plan = Get-Sha256 "$PlanDir/worker_plan.json"
                validation_plan = Get-Sha256 "$PlanDir/validation_plan.json"
            }
            project_type = if ($riskClass) { "unknown" } else { "unknown" }
            risk_level = if ($riskClass -and $riskClass.risk_level) { $riskClass.risk_level } else { "unknown" }
            selected_skill_packs = @()
            knowledge_sources_used = $false
            search_provider = "none"
            task_count = $allNodes.Count
            worker_count = $workers.Count
            capsule_index = $capsuleIndex
            status = "READY_FOR_MANUAL_WORKER_EXECUTION"
            non_claims = @(
                "Legacy V4 manual mode: workers must be dispatched to separate Codex windows manually",
                "Agent-adapter mode is not implemented in V4; use V5 factoryctl for native automatic dispatch",
                "V4 compatibility never emits EXECUTION_VERIFIED; V5 independent verification is authoritative"
            )
        }
        $execRun | ConvertTo-Json -Depth 5 | Out-File "$runDir/execution-run.json" -Encoding utf8 -NoNewline

        # Log
        "[$(Get-Date -Format 'o')] START run_id=$runId mode=$Mode plan_dir=$PlanDir workers=$($workers.Count) tasks=$($allNodes.Count)" |
            Out-File "$runDir/logs/runtime.log" -Encoding utf8

        Write-Output "Run created: $runId"
        Write-Output "  Mode: $Mode"
        Write-Output "  Workers: $($workers.Count)"
        Write-Output "  Tasks: $($allNodes.Count)"
        Write-Output "  Status: READY_FOR_MANUAL_WORKER_EXECUTION"
        Write-Output "  Capsules: $runDir/worker-capsules/"
        Write-Output "  Automatic resident/temporary Agent dispatch is available through the V5 factoryctl installation path."
        if ($Json) { $execRun | ConvertTo-Json -Depth 5 }
    }

    "status" {
        if (-not $RunId) { Write-Error "status requires -RunId <run-id>"; exit 1 }
        $runFile = "runs/$RunId/execution-run.json"
        if (-not (Test-Path $runFile)) { Write-Error "Run not found: $RunId"; exit 1 }

        $run = Get-Content $runFile -Raw | ConvertFrom-Json
        $capsules = @(Get-ChildItem "runs/$RunId/worker-capsules/*.json" -ErrorAction SilentlyContinue)
        $handoffs = @(Get-ChildItem "runs/$RunId/handoffs/*.json" -ErrorAction SilentlyContinue)
        $artifacts = @(Get-ChildItem "runs/$RunId/artifacts/*" -ErrorAction SilentlyContinue)

        Write-Output "=== Run: $RunId ==="
        Write-Output "  Mode: $($run.mode)"
        Write-Output "  Status: $($run.status)"
        Write-Output "  Created: $($run.created_at)"
        Write-Output "  Workers: $($run.worker_count) (capsules: $($capsules.Count))"
        Write-Output "  Tasks: $($run.task_count)"
        Write-Output "  Handoffs: $($handoffs.Count) / $($run.worker_count) expected"
        Write-Output "  Artifacts: $($artifacts.Count)"
        Write-Output "  Risk Level: $($run.risk_level)"
        if ($Json) { $run | ConvertTo-Json -Depth 5 }
    }

    "create-handoff-template" {
        if (-not $RunId) { Write-Error "create-handoff-template requires -RunId <run-id>"; exit 1 }
        if (-not $WorkerId) { Write-Error "create-handoff-template requires -WorkerId <worker-id>"; exit 1 }

        $capsuleFile = "runs/$RunId/worker-capsules/$WorkerId-capsule.json"
        if (-not (Test-Path $capsuleFile)) { Write-Error "Worker capsule not found: $capsuleFile"; exit 1 }

        $capsule = Get-Content $capsuleFile -Raw | ConvertFrom-Json

        $handoff = @{
            worker_id = $WorkerId
            task_ids = $capsule.assigned_tasks
            status = "PENDING"
            files_changed = @()
            artifacts_produced = @()
            tests_run = 0
            tests_passed = 0
            tests_failed = 0
            validation_result = "PENDING"
            blockers = @()
            assumptions = @()
            handoff_notes = "[FILL IN: describe what was done, any issues, decisions made]"
            next_agent = "integrator"
            timestamp = (Get-Date -Format "o")
        }

        $handoffFile = "runs/$RunId/handoffs/$WorkerId-handoff.json"
        $handoff | ConvertTo-Json -Depth 3 | Out-File $handoffFile -Encoding utf8 -NoNewline

        Write-Output "Handoff template created: $handoffFile"
        Write-Output "  Worker: $WorkerId"
        Write-Output "  Tasks: $($capsule.assigned_tasks -join ', ')"
        Write-Output "  Next: Fill in handoff_notes, files_changed, artifacts_produced, then run validate-handoff"
        Write-Output "  Each artifact claim must have a non-empty physical file at runs/$RunId/artifacts/<claim>."
        Write-Output "  Non-artifact validation methods require validation/<task>-<method>-receipt.json."
        if ($Json) { $handoff | ConvertTo-Json -Depth 3 }
    }

    "validate-handoff" {
        if (-not $RunId) { Write-Error "validate-handoff requires -RunId <run-id>"; exit 1 }
        if (-not $HandoffFile) { Write-Error "validate-handoff requires -HandoffFile <path>"; exit 1 }

        if (-not (Test-Path $HandoffFile)) { Write-Error "Handoff file not found: $HandoffFile"; exit 1 }

        $handoff = Get-Content $HandoffFile -Raw | ConvertFrom-Json
        $capsuleFile = "runs/$RunId/worker-capsules/$($handoff.worker_id)-capsule.json"
        $capsule = if (Test-Path $capsuleFile) { Get-Content $capsuleFile -Raw | ConvertFrom-Json } else { $null }

        $validationPlanFile = "runs/$RunId/input/validation_plan.json"
        $validationPlan = if (Test-Path $validationPlanFile) { Get-Content $validationPlanFile -Raw | ConvertFrom-Json } else { $null }
        $assessment = Test-HandoffEvidence $RunId $handoff $capsule $validationPlan

        $result = @{
            handoff_file = $HandoffFile
            worker_id = $handoff.worker_id
            status = $assessment.status
            issues = $assessment.issues
            warnings = $assessment.warnings
            artifact_evidence = $assessment.artifact_evidence
            changed_file_evidence = $assessment.changed_file_evidence
            legacy_runtime = $LegacyRuntimeVersion
            non_claim = "PASS here means structural and physical evidence checks passed; it is not V5 independent acceptance."
        }

        Write-Output "=== Handoff Validation ==="
        Write-Output "  Worker: $($handoff.worker_id)"
        Write-Output "  Result: $($result.status)"
        if ($assessment.issues.Count -gt 0) { Write-Output "  Issues: $($assessment.issues -join '; ')" }
        if ($assessment.warnings.Count -gt 0) { Write-Output "  Warnings: $($assessment.warnings -join '; ')" }
        if ($Json) { $result | ConvertTo-Json -Depth 6 }
    }

    "collect-artifacts" {
        if (-not $RunId) { Write-Error "collect-artifacts requires -RunId <run-id>"; exit 1 }

        $handoffDir = "runs/$RunId/handoffs"
        $artifactDir = "runs/$RunId/artifacts"
        $handoffs = @(Get-ChildItem "$handoffDir/*.json" -ErrorAction SilentlyContinue)

        $index = @{ run_id=$RunId; collected_at=(Get-Date -Format "o"); artifacts=@(); handoff_artifacts=@(); legacy_runtime=$LegacyRuntimeVersion }
        $physicalCollected = 0

        foreach ($h in $handoffs) {
            $handoff = Get-Content $h.FullName -Raw | ConvertFrom-Json
            foreach ($a in $handoff.artifacts_produced) {
                $evidence = Get-ArtifactEvidence $RunId ([string]$a)
                $index.handoff_artifacts += @{
                    artifact_name = $a
                    claimed_by = $handoff.worker_id
                    status = $handoff.status
                    handoff_file = $h.Name
                    physical_exists = $evidence.exists
                    relative_path = $evidence.relative_path
                    size = $evidence.size
                    sha256 = $evidence.sha256
                    rejection_reason = $evidence.reason
                }
                if ($evidence.exists) { $physicalCollected++ }
            }
        }

        # Also scan physical files in the artifact directory. The generated index
        # itself is explicitly excluded from worker evidence.
        $directArtifacts = @(Get-ChildItem -LiteralPath $artifactDir -File -Recurse -ErrorAction SilentlyContinue | Where-Object { $_.Name -ne "artifact-index.json" })
        foreach ($da in $directArtifacts) {
            $relative = $da.FullName.Substring((Resolve-Path $artifactDir).Path.Length).TrimStart('\','/') -replace '\\','/'
            $index.artifacts += @{ name=$da.Name; relative_path="artifacts/$relative"; size=[int64]$da.Length; sha256=(Get-Sha256 $da.FullName); source="physical_scan" }
        }

        $index | ConvertTo-Json -Depth 4 | Out-File "$artifactDir/artifact-index.json" -Encoding utf8 -NoNewline

        Write-Output "=== Artifact Collection ==="
        Write-Output "  Handoff claims with physical files: $physicalCollected"
        Write-Output "  Physical artifact files: $($directArtifacts.Count)"
        Write-Output "  Index: $artifactDir/artifact-index.json"
        if ($Json) { $index | ConvertTo-Json -Depth 4 }
    }

    "validate" {
        if (-not $RunId) { Write-Error "validate requires -RunId <run-id>"; exit 1 }

        $runFile = "runs/$RunId/execution-run.json"
        $validationPlanFile = "runs/$RunId/input/validation_plan.json"

        if (-not (Test-Path $validationPlanFile)) {
            Write-Error "validation_plan.json not found in run input"; exit 1
        }

        if (-not (Test-Path $runFile)) { Write-Error "execution-run.json not found"; exit 1 }
        $run = Get-Content $runFile -Raw | ConvertFrom-Json
        $vp = Get-Content $validationPlanFile -Raw | ConvertFrom-Json

        $handoffDir = "runs/$RunId/handoffs"
        $handoffs = @(Get-ChildItem "$handoffDir/*.json" -ErrorAction SilentlyContinue)

        $handoffRecords = @()
        $preflightIssues = @()
        foreach ($handoffEntry in $handoffs) {
            try {
                $handoffRecords += [pscustomobject]@{ file=$handoffEntry; data=(Get-Content $handoffEntry.FullName -Raw | ConvertFrom-Json) }
            } catch {
                $preflightIssues += "Invalid handoff JSON '$($handoffEntry.FullName)': $($_.Exception.Message)"
            }
        }

        $taskResults = @()
        $passed = 0; $failed = 0; $pending = 0
        foreach ($ptv in $vp.per_task_validation) {
            $taskId = $ptv.task_id
            $matching = @($handoffRecords | Where-Object { $taskId -in $_.data.task_ids })

            if ($matching.Count -eq 1) {
                $hdata = $matching[0].data
                $capsuleFile = "runs/$RunId/worker-capsules/$($hdata.worker_id)-capsule.json"
                $capsule = if (Test-Path $capsuleFile) { Get-Content $capsuleFile -Raw | ConvertFrom-Json } else { $null }
                $assessment = Test-HandoffEvidence $RunId $hdata $capsule $vp
                $methodResults = @()
                $taskFailed = ($assessment.status -eq "FAIL")
                $taskPending = ($hdata.status -ne "COMPLETED")

                foreach ($method in @($ptv.methods)) {
                    if ($method -eq "artifact") {
                        $requiredForTask = @($ptv.required_evidence)
                        $missingPhysical = @()
                        foreach ($required in $requiredForTask) {
                            $physical = Get-ArtifactEvidence $RunId ([string]$required)
                            if ($required -notin @($hdata.artifacts_produced) -or -not $physical.exists) {
                                $missingPhysical += $required
                            }
                        }
                        $methodStatus = if ($missingPhysical.Count -eq 0 -and $assessment.status -ne "FAIL") { "PASS" } else { "FAIL" }
                        $methodResults += [pscustomobject]@{
                            method = "artifact"
                            status = $methodStatus
                            missing = $missingPhysical
                            note = "Artifact PASS requires a non-empty physical file under runs/<run-id>/artifacts."
                        }
                        if ($methodStatus -eq "FAIL") { $taskFailed = $true }
                    } else {
                        $receiptResult = Test-ValidationReceipt $RunId $taskId ([string]$method) ([string]$hdata.worker_id)
                        $methodResults += $receiptResult
                        if ($receiptResult.status -eq "FAIL") { $taskFailed = $true }
                        if ($receiptResult.status -eq "PENDING") { $taskPending = $true }
                    }
                }
                if (-not $ptv.methods -or $ptv.methods.Count -eq 0) { $taskFailed = $true }
                $taskStatus = if ($taskFailed) { "FAIL" } elseif ($taskPending) { "PENDING" } else { "PASS" }
                $taskResult = @{
                    task_id = $taskId
                    handoff_present = $true
                    handoff_status = $hdata.status
                    required_methods = $ptv.methods
                    method_results = $methodResults
                    evidence_issues = $assessment.issues
                    status = $taskStatus
                }
                if ($taskStatus -eq "PASS") { $passed++ } elseif ($taskStatus -eq "FAIL") { $failed++ } else { $pending++ }
            } elseif ($matching.Count -gt 1) {
                $taskResult = @{ task_id=$taskId; handoff_present=$true; required_methods=$ptv.methods; status="FAIL"; evidence_issues=@("Task appears in multiple handoffs") }
                $failed++
            } else {
                $taskResult = @{ task_id=$taskId; handoff_present=$false; required_methods=$ptv.methods; status="PENDING" }
                $pending++
            }
            $taskResults += $taskResult
        }

        $gateResults = @()
        $gateFailed = 0; $gatePending = 0
        foreach ($gate in $vp.global_gates) {
            if ($gate.status -eq "required") {
                $receiptResult = Test-GlobalGateReceipt $RunId ([string]$gate.gate)
                $gr = @{
                    gate = $gate.gate
                    requirement = $gate.status
                    condition = $gate.condition
                    result = $receiptResult.status
                    receipt_path = $receiptResult.receipt_path
                    receipt_sha256 = $receiptResult.receipt_sha256
                    issues = $receiptResult.issues
                }
                if ($receiptResult.status -eq "FAIL") { $gateFailed++ }
                if ($receiptResult.status -eq "PENDING") { $gatePending++ }
            } else {
                $gr = @{ gate=$gate.gate; requirement=$gate.status; condition=$gate.condition; result="NOT_BLOCKING" }
            }
            $gateResults += $gr
        }

        $snapshot = Get-EvidenceSnapshot $RunId
        $overall = if ($preflightIssues.Count -gt 0 -or $failed -gt 0 -or $gateFailed -gt 0) { "FAIL" } elseif ($pending -gt 0 -or $gatePending -gt 0) { "PARTIAL" } else { "PASS" }

        $vResult = @{
            run_id = $RunId
            validated_at = (Get-Date -Format "o")
            legacy_runtime = $LegacyRuntimeVersion
            task_results = $taskResults
            gate_results = $gateResults
            preflight_issues = $preflightIssues
            summary = @{ total=$taskResults.Count; passed=$passed; failed=$failed; pending=$pending; gate_failed=$gateFailed; gate_pending=$gatePending }
            overall = $overall
            evidence_snapshot_sha256 = $snapshot.sha256
            evidence_snapshot_entry_count = $snapshot.entry_count
            evidence_manifest = $snapshot.entries
            non_claims = @(
                "Worker counters and handoff text are claims; they do not pass without physical artifacts and required receipts",
                "This V4 compatibility result is not V5 independent acceptance",
                "Required global gates without a receipt remain PENDING and block integration"
            )
        }

        $vResult | ConvertTo-Json -Depth 8 | Out-File "runs/$RunId/validation/validation-result.json" -Encoding utf8 -NoNewline

        Write-Output "=== Validation ==="
        Write-Output "  Tasks: $($vResult.summary.total) total | $passed PASS | $failed FAIL | $pending PENDING"
        Write-Output "  Required gates: $gateFailed FAIL | $gatePending PENDING"
        Write-Output "  Overall: $($vResult.overall)"
        Write-Output "  Result: runs/$RunId/validation/validation-result.json"
        if ($Json) { $vResult | ConvertTo-Json -Depth 8 }
    }

    "integrate" {
        if (-not $RunId) { Write-Error "integrate requires -RunId <run-id>"; exit 1 }

        $handoffDir = "runs/$RunId/handoffs"
        $handoffs = @(Get-ChildItem "$handoffDir/*.json" -ErrorAction SilentlyContinue)
        $checks = @()
        $allPassed = $true
        $capsuleDir = "runs/$RunId/worker-capsules"
        $capsules = @(Get-ChildItem "$capsuleDir/*.json" -ErrorAction SilentlyContinue)

        $capsuleRecords = @()
        foreach ($capsuleFile in $capsules) {
            $capsuleRecords += [pscustomobject]@{ file=$capsuleFile; data=(Get-Content $capsuleFile.FullName -Raw | ConvertFrom-Json) }
        }
        $handoffRecords = @()
        $invalidHandoffs = @()
        foreach ($handoffEntry in $handoffs) {
            try {
                $handoffRecords += [pscustomobject]@{ file=$handoffEntry; data=(Get-Content $handoffEntry.FullName -Raw | ConvertFrom-Json) }
            } catch {
                $invalidHandoffs += "$($handoffEntry.FullName): $($_.Exception.Message)"
            }
        }

        # Check 1: exact worker set, with no duplicate or unknown identities.
        $expectedWorkerIds = @($capsuleRecords | ForEach-Object { $_.data.worker_id } | Sort-Object -Unique)
        $actualWorkerIds = @($handoffRecords | ForEach-Object { $_.data.worker_id })
        $uniqueActualWorkerIds = @($actualWorkerIds | Sort-Object -Unique)
        $duplicateWorkers = @($actualWorkerIds | Group-Object | Where-Object { $_.Count -gt 1 } | ForEach-Object { $_.Name })
        $unknownWorkers = @($uniqueActualWorkerIds | Where-Object { $_ -notin $expectedWorkerIds })
        $missingWorkers = @($expectedWorkerIds | Where-Object { $_ -notin $uniqueActualWorkerIds })
        $handoffCheck = @{
            check = "exact_worker_handoff_set"
            expected = $expectedWorkerIds
            actual = $uniqueActualWorkerIds
            missing = $missingWorkers
            unknown = $unknownWorkers
            duplicates = $duplicateWorkers
            invalid_json = $invalidHandoffs
            status = if ($missingWorkers.Count -eq 0 -and $unknownWorkers.Count -eq 0 -and $duplicateWorkers.Count -eq 0 -and $invalidHandoffs.Count -eq 0 -and $expectedWorkerIds.Count -gt 0) { "PASS" } else { "FAIL" }
        }
        $checks += $handoffCheck
        if ($handoffCheck.status -eq "FAIL") { $allPassed = $false }

        # Check 2: every handoff must be COMPLETED and pass the same physical
        # evidence checks used by validation. A logical artifact name is not enough.
        $validationPlanFile = "runs/$RunId/input/validation_plan.json"
        $validationPlan = if (Test-Path $validationPlanFile) { Get-Content $validationPlanFile -Raw | ConvertFrom-Json } else { $null }
        $handoffAssessments = @()
        foreach ($record in $handoffRecords) {
            $capsuleRecord = @($capsuleRecords | Where-Object { $_.data.worker_id -eq $record.data.worker_id } | Select-Object -First 1)
            $capsule = if ($capsuleRecord.Count -eq 1) { $capsuleRecord[0].data } else { $null }
            $assessment = Test-HandoffEvidence $RunId $record.data $capsule $validationPlan
            $handoffAssessments += [pscustomobject]@{
                worker_id = $record.data.worker_id
                handoff_status = $record.data.status
                evidence_status = $assessment.status
                issues = $assessment.issues
                artifacts = $assessment.artifact_evidence
                changed_files = $assessment.changed_file_evidence
            }
        }
        $handoffEvidenceCheck = @{
            check = "completed_handoffs_with_physical_evidence"
            workers = $handoffAssessments
            status = if ($handoffAssessments.Count -eq $expectedWorkerIds.Count -and @($handoffAssessments | Where-Object { $_.handoff_status -ne "COMPLETED" -or $_.evidence_status -ne "PASS" }).Count -eq 0) { "PASS" } else { "FAIL" }
        }
        $checks += $handoffEvidenceCheck
        if ($handoffEvidenceCheck.status -eq "FAIL") { $allPassed = $false }

        # Check 3: validation must be current, PASS, and bound to the exact input,
        # capsule, handoff, artifact, changed-file, and receipt hashes.
        $validationFile = "runs/$RunId/validation/validation-result.json"
        $validationResult = if (Test-Path $validationFile) { Get-Content $validationFile -Raw | ConvertFrom-Json } else { $null }
        $snapshot = Get-EvidenceSnapshot $RunId
        $validationCheck = @{
            check = "current_validation_pass"
            validation_status = if ($validationResult) { $validationResult.overall } else { "MISSING" }
            expected_snapshot_sha256 = if ($validationResult) { $validationResult.evidence_snapshot_sha256 } else { $null }
            actual_snapshot_sha256 = $snapshot.sha256
            status = if ($validationResult -and $validationResult.overall -eq "PASS" -and $validationResult.evidence_snapshot_sha256 -eq $snapshot.sha256) { "PASS" } else { "FAIL" }
        }
        $checks += $validationCheck
        if ($validationCheck.status -eq "FAIL") { $allPassed = $false }

        $integrationReport = @{
            run_id = $RunId
            generated_at = (Get-Date -Format "o")
            legacy_runtime = $LegacyRuntimeVersion
            checks = $checks
            integration_status = if ($allPassed) { "READY_FOR_INTEGRATION" } else { "INTEGRATION_BLOCKED" }
            evidence_snapshot_sha256 = $snapshot.sha256
            validation_result_sha256 = if (Test-Path $validationFile) { Get-Sha256 $validationFile } else { $null }
            non_claims = @(
                "READY_FOR_INTEGRATION is not EXECUTION_VERIFIED and is not V5 independent acceptance",
                "Actual code merge and final independent verification remain the main agent's responsibility",
                "Any evidence change invalidates this report and requires validate + integrate again"
            )
        }

        New-Item -ItemType Directory -Force -Path "runs/$RunId/integration" | Out-Null
        $integrationReport | ConvertTo-Json -Depth 8 | Out-File "runs/$RunId/integration/integration-report.json" -Encoding utf8 -NoNewline

        Write-Output "=== Integration Report ==="
        foreach ($c in $checks) {
            Write-Output "  $($c.check): $($c.status)"
        }
        Write-Output "  Overall: $($integrationReport.integration_status)"
        Write-Output "  Report: runs/$RunId/integration/integration-report.json"
        if ($Json) { $integrationReport | ConvertTo-Json -Depth 8 }
    }

    "close" {
        if (-not $RunId) { Write-Error "close requires -RunId <run-id>"; exit 1 }

        $runFile = "runs/$RunId/execution-run.json"
        if (-not (Test-Path $runFile)) { Write-Error "Run not found: $RunId"; exit 1 }
        $run = Get-Content $runFile -Raw | ConvertFrom-Json

        $handoffs = @(Get-ChildItem "runs/$RunId/handoffs/*.json" -ErrorAction SilentlyContinue)
        $capsules = @(Get-ChildItem "runs/$RunId/worker-capsules/*.json" -ErrorAction SilentlyContinue)
        $validationFile = "runs/$RunId/validation/validation-result.json"
        $integrationFile = "runs/$RunId/integration/integration-report.json"

        $validationResult = if (Test-Path $validationFile) { Get-Content $validationFile -Raw | ConvertFrom-Json } else { $null }
        $integrationResult = if (Test-Path $integrationFile) { Get-Content $integrationFile -Raw | ConvertFrom-Json } else { $null }

        $validationPlanFile = "runs/$RunId/input/validation_plan.json"
        $validationPlan = if (Test-Path $validationPlanFile) { Get-Content $validationPlanFile -Raw | ConvertFrom-Json } else { $null }
        $capsuleRecords = @($capsules | ForEach-Object { [pscustomobject]@{ file=$_; data=(Get-Content $_.FullName -Raw | ConvertFrom-Json) } })
        $handoffRecords = @()
        $blockingIssues = @()
        foreach ($handoffEntry in $handoffs) {
            try {
                $handoffRecords += [pscustomobject]@{ file=$handoffEntry; data=(Get-Content $handoffEntry.FullName -Raw | ConvertFrom-Json) }
            } catch {
                $blockingIssues += "Invalid handoff JSON '$($handoffEntry.FullName)': $($_.Exception.Message)"
            }
        }

        $expectedWorkerIds = @($capsuleRecords | ForEach-Object { $_.data.worker_id } | Sort-Object -Unique)
        $actualWorkerIds = @($handoffRecords | ForEach-Object { $_.data.worker_id })
        $uniqueActualWorkerIds = @($actualWorkerIds | Sort-Object -Unique)
        $missingWorkers = @($expectedWorkerIds | Where-Object { $_ -notin $uniqueActualWorkerIds })
        $unknownWorkers = @($uniqueActualWorkerIds | Where-Object { $_ -notin $expectedWorkerIds })
        $duplicateWorkers = @($actualWorkerIds | Group-Object | Where-Object { $_.Count -gt 1 } | ForEach-Object { $_.Name })
        if ($missingWorkers.Count -gt 0) { $blockingIssues += "Missing handoff worker(s): $($missingWorkers -join ', ')" }
        if ($unknownWorkers.Count -gt 0) { $blockingIssues += "Unknown handoff worker(s): $($unknownWorkers -join ', ')" }
        if ($duplicateWorkers.Count -gt 0) { $blockingIssues += "Duplicate handoff worker(s): $($duplicateWorkers -join ', ')" }

        $artifactClaims = @()
        $artifactEvidence = @()
        $expectedArtifactNames = @($capsuleRecords | ForEach-Object { @($_.data.required_output_artifacts) } | Select-Object -Unique)
        foreach ($record in $handoffRecords) {
            $capsuleRecord = @($capsuleRecords | Where-Object { $_.data.worker_id -eq $record.data.worker_id } | Select-Object -First 1)
            $capsule = if ($capsuleRecord.Count -eq 1) { $capsuleRecord[0].data } else { $null }
            $assessment = Test-HandoffEvidence $RunId $record.data $capsule $validationPlan
            $artifactClaims += @($record.data.artifacts_produced)
            $artifactEvidence += @($assessment.artifact_evidence)
            if ($assessment.status -ne "PASS") {
                foreach ($issue in $assessment.issues) { $blockingIssues += "$($record.data.worker_id): $issue" }
            }
        }
        foreach ($required in $expectedArtifactNames) {
            $physical = Get-ArtifactEvidence $RunId ([string]$required)
            if (-not $physical.exists) { $blockingIssues += "Required physical artifact missing: $required ($($physical.reason))" }
        }

        $snapshot = Get-EvidenceSnapshot $RunId
        $validationBound = ($validationResult -and $validationResult.overall -eq "PASS" -and $validationResult.evidence_snapshot_sha256 -eq $snapshot.sha256)
        $currentValidationHash = if (Test-Path $validationFile) { Get-Sha256 $validationFile } else { $null }
        $integrationBound = ($integrationResult -and $integrationResult.integration_status -eq "READY_FOR_INTEGRATION" -and $integrationResult.evidence_snapshot_sha256 -eq $snapshot.sha256 -and $integrationResult.validation_result_sha256 -eq $currentValidationHash)
        if (-not $validationBound) { $blockingIssues += "Validation is missing, not PASS, or stale relative to current evidence" }
        if (-not $integrationBound) { $blockingIssues += "Integration report is missing, blocked, or stale relative to current evidence" }

        $exactWorkerSet = ($expectedWorkerIds.Count -gt 0 -and $missingWorkers.Count -eq 0 -and $unknownWorkers.Count -eq 0 -and $duplicateWorkers.Count -eq 0)
        $allHandoffsCompleted = ($handoffRecords.Count -eq $expectedWorkerIds.Count -and @($handoffRecords | Where-Object { $_.data.status -ne "COMPLETED" }).Count -eq 0)
        $physicalArtifactNames = @($artifactEvidence | Where-Object { $_.exists } | ForEach-Object { $_.claim } | Select-Object -Unique)
        $allRequiredArtifactsPhysical = (@($expectedArtifactNames | Where-Object { $_ -notin $physicalArtifactNames }).Count -eq 0 -and $expectedArtifactNames.Count -gt 0)
        $noFakePassConfirmed = ($exactWorkerSet -and $allHandoffsCompleted -and $allRequiredArtifactsPhysical -and $validationBound -and $integrationBound -and $blockingIssues.Count -eq 0)

        $finalStatus = "READY_FOR_MANUAL_WORKER_EXECUTION"
        if ($handoffRecords.Count -gt 0 -and -not $exactWorkerSet) {
            $finalStatus = "PARTIAL_HANDOFF_COLLECTED"
        } elseif ($exactWorkerSet -and -not $validationBound) {
            $finalStatus = "VALIDATION_BLOCKED"
        } elseif ($exactWorkerSet -and $validationBound -and -not $integrationBound) {
            $finalStatus = "INTEGRATION_BLOCKED"
        } elseif ($noFakePassConfirmed) {
            $finalStatus = "READY_FOR_INTEGRATION"
        } elseif ($handoffRecords.Count -gt 0) {
            $finalStatus = "INTEGRATION_BLOCKED"
        }

        $passedTaskIds = @()
        $failedTaskIds = @()
        if ($validationResult -and $validationResult.task_results) {
            $passedTaskIds = @($validationResult.task_results | Where-Object { $_.status -eq "PASS" } | ForEach-Object { $_.task_id } | Select-Object -Unique)
            $failedTaskIds = @($validationResult.task_results | Where-Object { $_.status -eq "FAIL" } | ForEach-Object { $_.task_id } | Select-Object -Unique)
        }
        $totalExpected = [int]$run.task_count

        $receipt = @{
            run_id = $RunId
            mode = $run.mode
            legacy_runtime = $LegacyRuntimeVersion
            input_plan_hashes = $run.source_plan_hashes
            tasks_total = $totalExpected
            tasks_completed = $passedTaskIds.Count
            tasks_blocked = $failedTaskIds.Count
            workers_total = $capsules.Count
            handoffs_expected = $capsules.Count
            handoffs_collected = $handoffRecords.Count
            artifacts_expected = $expectedArtifactNames.Count
            artifacts_claimed = @($artifactClaims | Select-Object -Unique).Count
            artifacts_collected = $physicalArtifactNames.Count
            artifact_evidence = $artifactEvidence
            validation_status = if ($validationResult) { $validationResult.overall } else { "PENDING" }
            integration_status = if ($integrationBound) { "PASS" } elseif ($integrationResult) { "BLOCKED" } else { "PENDING" }
            evidence_snapshot_sha256 = $snapshot.sha256
            final_status = $finalStatus
            blocking_issues = @($blockingIssues | Select-Object -Unique)
            no_fake_pass_confirmed = $noFakePassConfirmed
            closed_at = (Get-Date -Format "o")
            non_claims = @(
                "V4 compatibility close never emits EXECUTION_VERIFIED",
                "READY_FOR_INTEGRATION means legacy evidence is internally consistent; V5 independent verification is still required for authoritative acceptance",
                "Worker text and test counters are not treated as physical artifacts"
            )
        }

        $receipt | ConvertTo-Json -Depth 8 | Out-File "runs/$RunId/execution-receipt.json" -Encoding utf8 -NoNewline

        # Update run status
        $run.status = $finalStatus
        $run | ConvertTo-Json -Depth 5 | Out-File $runFile -Encoding utf8 -NoNewline

        Write-Output "=== Execution Receipt ==="
        Write-Output "  Run: $RunId"
        Write-Output "  Mode: $($run.mode)"
        Write-Output "  Final Status: $finalStatus"
        Write-Output "  Tasks: $($passedTaskIds.Count) verified / $($failedTaskIds.Count) failed / $totalExpected total"
        Write-Output "  Handoffs: $($handoffRecords.Count) / $($capsules.Count)"
        Write-Output "  Artifacts: $($receipt.artifacts_collected) physical / $($receipt.artifacts_claimed) claimed / $($receipt.artifacts_expected) expected"
        Write-Output "  Validation: $($receipt.validation_status)"
        Write-Output "  Integration: $($receipt.integration_status)"
        Write-Output "  No-fake-pass confirmed: $($receipt.no_fake_pass_confirmed)"
        Write-Output "  Receipt: runs/$RunId/execution-receipt.json"
        if ($Json) { $receipt | ConvertTo-Json -Depth 8 }
    }


    "import-live-handoff" {
        if (-not $RunId) { Write-Error "import-live-handoff requires -RunId <run-id>"; exit 1 }
        $liveDir = "runs/$RunId/live-handoffs"
        New-Item -ItemType Directory -Force -Path $liveDir | Out-Null
        Write-Output "Live handoff intake directory ready: $liveDir"
        Write-Output "Place worker handoff JSON files here:"
        Write-Output "  - worker-backend-handoff.json"
        Write-Output "  - worker-frontend-handoff.json"
        Write-Output "  - worker-qa-handoff.json"
        Write-Output "Then run: validate-live-handoff -RunId $RunId"
    }

    "validate-live-handoff" {
        if (-not $RunId) { Write-Error "validate-live-handoff requires -RunId <run-id>"; exit 1 }
        $liveDir = "runs/$RunId/live-handoffs"
        if (-not (Test-Path $liveDir)) { Write-Error "Live handoff directory not found. Run import-live-handoff first."; exit 1 }

        $handoffs = @(Get-ChildItem "$liveDir/worker-*-handoff.json" -ErrorAction SilentlyContinue)
        if ($handoffs.Count -eq 0) {
            Write-Output "STATUS: WAITING_FOR_REAL_WORKER_HANDOFFS"
            Write-Output "  No handoff files found in $liveDir"
            Write-Output "  Place worker handoff files, then re-run this command."
            if ($Json) { @{status="WAITING_FOR_REAL_WORKER_HANDOFFS"; handoffs_found=0} | ConvertTo-Json }
            exit 0
        }

        $results = @()
        $accepted = 0; $rejected = 0; $placeholder = 0
        foreach ($h in $handoffs) {
            try {
                $hd = Get-Content $h.FullName -Raw | ConvertFrom-Json
            } catch {
                $results += @{ worker_id=$null; file=$h.Name; status="INVALID"; artifacts_claimed=0; physical_artifacts=0; issues=@("Invalid handoff JSON"); verdict="REJECTED" }
                $rejected++
                continue
            }
            $capsuleFile = "runs/$RunId/worker-capsules/$($hd.worker_id)-capsule.json"
            $capsule = if (Test-Path $capsuleFile) { Get-Content $capsuleFile -Raw | ConvertFrom-Json } else { $null }
            $validationPlanFile = "runs/$RunId/input/validation_plan.json"
            $validationPlan = if (Test-Path $validationPlanFile) { Get-Content $validationPlanFile -Raw | ConvertFrom-Json } else { $null }
            $assessment = Test-HandoffEvidence $RunId $hd $capsule $validationPlan
            $issues = @($assessment.issues)
            if ($hd.status -ne "COMPLETED") { $issues += "Live handoff is not COMPLETED" }
            if ($hd.handoff_notes -match '(?i)FILL IN|placeholder|template') { $placeholder++ }

            $physicalCount = @($assessment.artifact_evidence | Where-Object { $_.exists }).Count
            $verdict = if ($issues.Count -gt 0) { "REJECTED" } else { "ACCEPTED" }
            if ($verdict -eq "ACCEPTED") { $accepted++ } else { $rejected++ }

            $results += @{
                worker_id = $hd.worker_id
                file = $h.Name
                status = $hd.status
                artifacts_claimed = @($hd.artifacts_produced).Count
                physical_artifacts = $physicalCount
                artifact_evidence = $assessment.artifact_evidence
                issues = @($issues | Select-Object -Unique)
                verdict = $verdict
            }
        }

        $snapshot = Get-EvidenceSnapshot $RunId
        $summary = @{
            validated_at = (Get-Date -Format "o")
            legacy_runtime = $LegacyRuntimeVersion
            total = $handoffs.Count
            accepted = $accepted
            rejected = $rejected
            placeholder_detected = $placeholder
            results = $results
            evidence_snapshot_sha256 = $snapshot.sha256
            final_status = if ($rejected -gt 0 -and $accepted -gt 0) { "LIVE_CROSS_WINDOW_PARTIAL" }
                          elseif ($rejected -gt 0 -and $accepted -eq 0) { "LIVE_CROSS_WINDOW_BLOCKED" }
                          elseif ($placeholder -gt 0) { "WAITING_FOR_REAL_WORKER_HANDOFFS" }
                          elseif ($accepted -gt 0 -and $accepted -eq $handoffs.Count) { "READY_FOR_LIVE_INTEGRATION" }
                          else { "LIVE_CROSS_WINDOW_BLOCKED" }
            non_claim = "READY_FOR_LIVE_INTEGRATION requires run-local capsules and physical artifacts; it is not V5 independent acceptance."
        }
        $summary | ConvertTo-Json -Depth 8 | Out-File "$liveDir/live-handoff-validation.json" -Encoding utf8 -NoNewline

        Write-Output "=== Live Handoff Validation ==="
        foreach ($r in $results) {
            Write-Output "  $($r.worker_id): $($r.verdict) (status=$($r.status), physical_artifacts=$($r.physical_artifacts))"
            foreach ($i in $r.issues) { Write-Output "    - $i" }
        }
        Write-Output "  Final Status: $($summary.final_status)"
        Write-Output "  Accepted: $accepted / $($handoffs.Count)"
        if ($Json) { $summary | ConvertTo-Json -Depth 8 }
    }

    "summarize-live-run" {
        if (-not $RunId) { Write-Error "summarize-live-run requires -RunId <run-id>"; exit 1 }
        $liveDir = "runs/$RunId/live-handoffs"
        $validationFile = "$liveDir/live-handoff-validation.json"
        
        if (-not (Test-Path $validationFile)) {
            Write-Output "No validation results yet. Run validate-live-handoff first."
            Write-Output "STATUS: WAITING_FOR_REAL_WORKER_HANDOFFS"
            exit 0
        }
        
        $v = Get-Content $validationFile -Raw | ConvertFrom-Json
        $acceptedWorkers = @($v.results | Where-Object { $_.verdict -eq "ACCEPTED" })
        $totalArtifactsClaimed = 0
        $totalPhysicalArtifacts = 0
        foreach ($r in $acceptedWorkers) {
            $totalArtifactsClaimed += [int]$r.artifacts_claimed
            $totalPhysicalArtifacts += [int]$r.physical_artifacts
        }
        $snapshot = Get-EvidenceSnapshot $RunId
        $validationBound = ($v.evidence_snapshot_sha256 -eq $snapshot.sha256)
        $noFakePassConfirmed = ($v.final_status -eq "READY_FOR_LIVE_INTEGRATION" -and $v.placeholder_detected -eq 0 -and $v.rejected -eq 0 -and $validationBound -and $totalPhysicalArtifacts -gt 0)
        
        $receipt = @{
            run_id = $RunId
            mode = "live-cross-window"
            legacy_runtime = $LegacyRuntimeVersion
            generated_at = (Get-Date -Format "o")
            workers_total = $v.total
            workers_accepted = $v.accepted
            workers_rejected = $v.rejected
            placeholders_found = $v.placeholder_detected
            total_artifacts_claimed = $totalArtifactsClaimed
            total_physical_artifacts = $totalPhysicalArtifacts
            evidence_snapshot_sha256 = $snapshot.sha256
            validation_snapshot_matches = $validationBound
            final_status = if ($noFakePassConfirmed) { $v.final_status } else { "LIVE_CROSS_WINDOW_BLOCKED" }
            no_fake_pass_confirmed = $noFakePassConfirmed
            user_action_required = if ($v.final_status -eq "WAITING_FOR_REAL_WORKER_HANDOFFS") {
                "Open 3 separate Codex windows and paste WORKER_*_PROMPT.md from outputs/V4_4/live-cross-window-kit/"
            } elseif (-not $validationBound) {
                "Evidence changed after validation. Re-run validate-live-handoff."
            } elseif ($noFakePassConfirmed) {
                "Legacy physical handoffs are internally consistent. Use factoryctl for authoritative V5 verification."
            } else {
                "Review rejected handoffs, fix violations, and re-submit."
            }
        }
        
        $receipt | ConvertTo-Json -Depth 3 | Out-File "$liveDir/live-run-summary.json" -Encoding utf8 -NoNewline
        
        Write-Output "=== Live Run Summary ==="
        Write-Output "  Workers: $($v.accepted) accepted / $($v.rejected) rejected / $($v.placeholder_detected) placeholder"
        Write-Output "  Artifacts: $totalPhysicalArtifacts physical / $totalArtifactsClaimed claimed"
        Write-Output "  Final Status: $($receipt.final_status)"
        Write-Output "  No-fake-pass confirmed: $($receipt.no_fake_pass_confirmed)"
        Write-Output "  User Action: $($receipt.user_action_required)"
        if ($Json) { $receipt | ConvertTo-Json -Depth 3 }
    }

    default {
        Write-Error "Unknown command: $Command. Use: start, status, create-handoff-template, validate-handoff, collect-artifacts, validate, integrate, close, import-live-handoff, validate-live-handoff, summarize-live-run"
        exit 1
    }
}
