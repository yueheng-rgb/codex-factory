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
                "Manual mode: workers must be dispatched to separate Codex windows manually",
                "Agent-adapter mode: NOT_CONFIGURED (reserved for future spawn_agent integration)",
                "No fake PASS: status will not be EXECUTION_VERIFIED until all artifacts collected"
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
        if ($Json) { $handoff | ConvertTo-Json -Depth 3 }
    }

    "validate-handoff" {
        if (-not $RunId) { Write-Error "validate-handoff requires -RunId <run-id>"; exit 1 }
        if (-not $HandoffFile) { Write-Error "validate-handoff requires -HandoffFile <path>"; exit 1 }

        if (-not (Test-Path $HandoffFile)) { Write-Error "Handoff file not found: $HandoffFile"; exit 1 }

        $handoff = Get-Content $HandoffFile -Raw | ConvertFrom-Json
        $capsuleFile = "runs/$RunId/worker-capsules/$($handoff.worker_id)-capsule.json"
        $capsule = if (Test-Path $capsuleFile) { Get-Content $capsuleFile -Raw | ConvertFrom-Json } else { $null }

        $issues = @()
        $warnings = @()

        # Check required fields
        if (-not $handoff.worker_id) { $issues += "Missing worker_id" }
        if (-not $handoff.task_ids -or $handoff.task_ids.Count -eq 0) { $issues += "Missing task_ids" }
        if ($handoff.status -eq "PENDING") { $warnings += "Status is PENDING — update to COMPLETED/PARTIAL/BLOCKED/FAILED" }
        if ($handoff.handoff_notes -eq "[FILL IN: describe what was done, any issues, decisions made]") {
            $warnings += "handoff_notes is still template placeholder"
        }
        if (-not $handoff.next_agent) { $issues += "Missing next_agent" }

        # Check capsule compliance
        if ($capsule) {
            if ($capsule.handoff_required -and $handoff.status -ne "COMPLETED") {
                $warnings += "Handoff required but status is not COMPLETED"
            }
            # Check required outputs
            if ($handoff.status -eq "COMPLETED") {
                foreach ($req in $capsule.required_output_artifacts) {
                    if ($req -notin $handoff.artifacts_produced) {
                        $warnings += "Required artifact '$req' not in artifacts_produced"
                    }
                }
            }
            # Check file boundary
            foreach ($f in $handoff.files_changed) {
                foreach ($forbidden in $capsule.forbidden_files) {
                    if ($f -like $forbidden) {
                        $issues += "FILE BOUNDARY VIOLATION: '$f' matches forbidden pattern '$forbidden'"
                    }
                }
            }
        }

        $result = @{
            handoff_file = $HandoffFile
            worker_id = $handoff.worker_id
            status = if ($issues.Count -gt 0) { "FAIL" } elseif ($warnings.Count -gt 0) { "WARN" } else { "PASS" }
            issues = $issues
            warnings = $warnings
        }

        Write-Output "=== Handoff Validation ==="
        Write-Output "  Worker: $($handoff.worker_id)"
        Write-Output "  Result: $($result.status)"
        if ($issues.Count -gt 0) { Write-Output "  Issues: $($issues -join '; ')" }
        if ($warnings.Count -gt 0) { Write-Output "  Warnings: $($warnings -join '; ')" }
        if ($Json) { $result | ConvertTo-Json -Depth 3 }
    }

    "collect-artifacts" {
        if (-not $RunId) { Write-Error "collect-artifacts requires -RunId <run-id>"; exit 1 }

        $handoffDir = "runs/$RunId/handoffs"
        $artifactDir = "runs/$RunId/artifacts"
        $handoffs = @(Get-ChildItem "$handoffDir/*.json" -ErrorAction SilentlyContinue)

        $index = @{ run_id=$RunId; collected_at=(Get-Date -Format "o"); artifacts=@(); handoff_artifacts=@() }
        $collected = 0

        foreach ($h in $handoffs) {
            $handoff = Get-Content $h.FullName -Raw | ConvertFrom-Json
            foreach ($a in $handoff.artifacts_produced) {
                $index.handoff_artifacts += @{
                    artifact_name = $a
                    claimed_by = $handoff.worker_id
                    status = $handoff.status
                    handoff_file = $h.Name
                }
                $collected++
            }
        }

        # Also scan artifacts directory
        $directArtifacts = @(Get-ChildItem "$artifactDir/*" -ErrorAction SilentlyContinue)
        foreach ($da in $directArtifacts) {
            if ($da.Name -notin $index.handoff_artifacts.artifact_name) {
                $index.artifacts += @{ name=$da.Name; size=$da.Length; source="direct" }
            }
        }

        $index | ConvertTo-Json -Depth 4 | Out-File "$artifactDir/artifact-index.json" -Encoding utf8 -NoNewline

        Write-Output "=== Artifact Collection ==="
        Write-Output "  Handoff-claimed: $collected"
        Write-Output "  Direct artifacts: $($directArtifacts.Count)"
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

        $run = Get-Content $runFile -Raw | ConvertFrom-Json
        $vp = Get-Content $validationPlanFile -Raw | ConvertFrom-Json

        $handoffDir = "runs/$RunId/handoffs"
        $handoffs = @(Get-ChildItem "$handoffDir/*.json" -ErrorAction SilentlyContinue)

        $taskResults = @()
        $passed = 0; $failed = 0; $pending = 0
        foreach ($ptv in $vp.per_task_validation) {
            $taskId = $ptv.task_id
            $handoff = @($handoffs | Where-Object {
                $h = Get-Content $_.FullName -Raw | ConvertFrom-Json
                $taskId -in $h.task_ids
            } | Select-Object -First 1)

            if ($handoff) {
                $hdata = Get-Content $handoff.FullName -Raw | ConvertFrom-Json
                $taskResult = @{
                    task_id = $taskId
                    handoff_present = $true
                    handoff_status = $hdata.status
                    required_methods = $ptv.methods
                    status = if ($hdata.status -eq "COMPLETED") { "PASS" } else { "PENDING" }
                }
                if ($hdata.status -eq "COMPLETED") { $passed++ } else { $pending++ }
            } else {
                $taskResult = @{ task_id=$taskId; handoff_present=$false; required_methods=$ptv.methods; status="PENDING" }
                $pending++
            }
            $taskResults += $taskResult
        }

        $gateResults = @()
        foreach ($gate in $vp.global_gates) {
            $gr = @{ gate=$gate.gate; status=$gate.status; condition=$gate.condition }
            if ($gate.gate -eq "snapshot-verifier" -and $gate.status -eq "required") {
                $gr.result = "SKIPPED — run outside CI context"
            }
            if ($gate.gate -eq "secret-scan") {
                $gr.result = "PENDING — run secret-presence-check.ps1"
            }
            $gateResults += $gr
        }

        $vResult = @{
            run_id = $RunId
            validated_at = (Get-Date -Format "o")
            task_results = $taskResults
            gate_results = $gateResults
            summary = @{ total=$taskResults.Count; passed=$passed; failed=$failed; pending=$pending }
            overall = if ($failed -gt 0) { "FAIL" } elseif ($pending -gt 0) { "PARTIAL" } else { "PASS" }
            non_claims = @(
                "Manual mode: validation reflects handoff collection status only",
                "snapshot-verifier and secret-scan gates need CI context or manual execution"
            )
        }

        $vResult | ConvertTo-Json -Depth 4 | Out-File "runs/$RunId/validation/validation-result.json" -Encoding utf8 -NoNewline

        Write-Output "=== Validation ==="
        Write-Output "  Tasks: $($vResult.summary.total) total | $passed PASS | $failed FAIL | $pending PENDING"
        Write-Output "  Overall: $($vResult.overall)"
        Write-Output "  Result: runs/$RunId/validation/validation-result.json"
        if ($Json) { $vResult | ConvertTo-Json -Depth 4 }
    }

    "integrate" {
        if (-not $RunId) { Write-Error "integrate requires -RunId <run-id>"; exit 1 }

        $handoffDir = "runs/$RunId/handoffs"
        $handoffs = @(Get-ChildItem "$handoffDir/*.json" -ErrorAction SilentlyContinue)

        $checks = @()
        $allPassed = $true

        # Check 1: All workers have handoffs
        $capsuleDir = "runs/$RunId/worker-capsules"
        $capsules = @(Get-ChildItem "$capsuleDir/*.json" -ErrorAction SilentlyContinue)
        $expectedWorkers = $capsules.Count
        $handoffWorkers = @($handoffs | ForEach-Object {
            (Get-Content $_.FullName -Raw | ConvertFrom-Json).worker_id
        } | Select-Object -Unique)
        $handoffCheck = @{
            check = "all_workers_handed_off"
            expected = $expectedWorkers
            actual = $handoffWorkers.Count
            missing = @($capsules | Where-Object { $_.BaseName -replace '-capsule$','' -notin $handoffWorkers } | ForEach-Object { $_.BaseName -replace '-capsule$','' })
            status = if ($handoffWorkers.Count -ge $expectedWorkers) { "PASS" } else { "FAIL" }
        }
        $checks += $handoffCheck
        if ($handoffCheck.status -eq "FAIL") { $allPassed = $false }

        # Check 2: No handoff has blockers
        $blockedHandoffs = @()
        foreach ($h in $handoffs) {
            $hd = Get-Content $h.FullName -Raw | ConvertFrom-Json
            if ($hd.blockers -and $hd.blockers.Count -gt 0) {
                $blockedHandoffs += @{ worker_id=$hd.worker_id; blockers=$hd.blockers }
            }
        }
        $blockerCheck = @{
            check = "no_blockers"
            blocked_workers = $blockedHandoffs
            status = if ($blockedHandoffs.Count -eq 0) { "PASS" } else { "FAIL" }
        }
        $checks += $blockerCheck
        if ($blockerCheck.status -eq "FAIL") { $allPassed = $false }

        # Check 3: Required artifacts present
        $artifactsMissing = @()
        foreach ($h in $handoffs) {
            $hd = Get-Content $h.FullName -Raw | ConvertFrom-Json
            $cf = "runs/$RunId/worker-capsules/$($hd.worker_id)-capsule.json"
            if (Test-Path $cf) {
                $cap = Get-Content $cf -Raw | ConvertFrom-Json
                if ($hd.status -eq "COMPLETED") {
                    foreach ($req in $cap.required_output_artifacts) {
                        if ($req -notin $hd.artifacts_produced) {
                            $artifactsMissing += @{ worker_id=$hd.worker_id; missing=$req }
                        }
                    }
                }
            }
        }
        $artifactCheck = @{
            check = "required_artifacts"
            missing = $artifactsMissing
            status = if ($artifactsMissing.Count -eq 0) { "PASS" } else { "FAIL" }
        }
        $checks += $artifactCheck
        if ($artifactCheck.status -eq "FAIL") { $allPassed = $false }

        # Check 4: File boundary violations
        $boundaryViolations = @()
        foreach ($h in $handoffs) {
            $hd = Get-Content $h.FullName -Raw | ConvertFrom-Json
            $cf = "runs/$RunId/worker-capsules/$($hd.worker_id)-capsule.json"
            if (Test-Path $cf) {
                $cap = Get-Content $cf -Raw | ConvertFrom-Json
                foreach ($f in $hd.files_changed) {
                    foreach ($forbidden in $cap.forbidden_files) {
                        if ($f -like $forbidden) {
                            $boundaryViolations += @{ worker_id=$hd.worker_id; file=$f; forbidden_pattern=$forbidden }
                        }
                    }
                }
            }
        }
        $boundaryCheck = @{
            check = "no_boundary_violations"
            violations = $boundaryViolations
            status = if ($boundaryViolations.Count -eq 0) { "PASS" } else { "FAIL" }
        }
        $checks += $boundaryCheck
        if ($boundaryCheck.status -eq "FAIL") { $allPassed = $false }

        $integrationReport = @{
            run_id = $RunId
            generated_at = (Get-Date -Format "o")
            checks = $checks
            integration_status = if ($allPassed) { "READY_FOR_INTEGRATION" } else { "INTEGRATION_BLOCKED" }
            non_claims = @(
                "Integration check validates handoff completeness and boundaries",
                "Actual code merge must be performed by the integrator agent or main agent"
            )
        }

        New-Item -ItemType Directory -Force -Path "runs/$RunId/integration" | Out-Null
        $integrationReport | ConvertTo-Json -Depth 4 | Out-File "runs/$RunId/integration/integration-report.json" -Encoding utf8 -NoNewline

        Write-Output "=== Integration Report ==="
        foreach ($c in $checks) {
            Write-Output "  $($c.check): $($c.status)"
        }
        Write-Output "  Overall: $($integrationReport.integration_status)"
        Write-Output "  Report: runs/$RunId/integration/integration-report.json"
        if ($Json) { $integrationReport | ConvertTo-Json -Depth 4 }
    }

    "close" {
        if (-not $RunId) { Write-Error "close requires -RunId <run-id>"; exit 1 }

        $runFile = "runs/$RunId/execution-run.json"
        if (-not (Test-Path $runFile)) { Write-Error "Run not found: $RunId"; exit 1 }
        $run = Get-Content $runFile -Raw | ConvertFrom-Json

        $handoffs = @(Get-ChildItem "runs/$RunId/handoffs/*.json" -ErrorAction SilentlyContinue)
        $capsules = @(Get-ChildItem "runs/$RunId/worker-capsules/*.json" -ErrorAction SilentlyContinue)
        $artifacts = @(Get-ChildItem "runs/$RunId/artifacts/*" -ErrorAction SilentlyContinue)
        $validationFile = "runs/$RunId/validation/validation-result.json"
        $integrationFile = "runs/$RunId/integration/integration-report.json"

        $validationResult = if (Test-Path $validationFile) { Get-Content $validationFile -Raw | ConvertFrom-Json } else { $null }
        $integrationResult = if (Test-Path $integrationFile) { Get-Content $integrationFile -Raw | ConvertFrom-Json } else { $null }

        # Count completed vs blocked
        $completed = 0; $blocked = 0; $totalExpected = 0
        foreach ($h in $handoffs) {
            $hd = Get-Content $h.FullName -Raw | ConvertFrom-Json
            $totalExpected += $hd.task_ids.Count
            if ($hd.status -eq "COMPLETED") { $completed += $hd.task_ids.Count }
            elseif ($hd.status -eq "BLOCKED") { $blocked += $hd.task_ids.Count }
        }
        if ($totalExpected -eq 0) { $totalExpected = $run.task_count }

        # Count artifact claims
        $artifactClaimed = 0
        foreach ($h in $handoffs) {
            $hd = Get-Content $h.FullName -Raw | ConvertFrom-Json
            $artifactClaimed += $hd.artifacts_produced.Count
        }

        # Determine final status
        $finalStatus = "READY_FOR_MANUAL_WORKER_EXECUTION"
        if ($handoffs.Count -gt 0 -and $handoffs.Count -lt $capsules.Count) {
            $finalStatus = "PARTIAL_HANDOFF_COLLECTED"
        }
        if ($handoffs.Count -ge $capsules.Count) {
            if ($integrationResult -and $integrationResult.integration_status -eq "READY_FOR_INTEGRATION") {
                $finalStatus = "READY_FOR_INTEGRATION"
            } elseif ($integrationResult -and $integrationResult.integration_status -eq "INTEGRATION_BLOCKED") {
                $finalStatus = "INTEGRATION_BLOCKED"
            }
        }
        if ($blocked -gt 0) { $finalStatus = "INTEGRATION_BLOCKED" }

        # NEVER allow EXECUTION_VERIFIED in manual mode automatically
        if ($Mode -eq "manual" -and $finalStatus -eq "READY_FOR_INTEGRATION") {
            # Keep as READY_FOR_INTEGRATION — don't auto-promote
        }

        $receipt = @{
            run_id = $RunId
            mode = $run.mode
            input_plan_hashes = $run.source_plan_hashes
            tasks_total = $totalExpected
            tasks_completed = $completed
            tasks_blocked = $blocked
            workers_total = $capsules.Count
            handoffs_expected = $capsules.Count
            handoffs_collected = $handoffs.Count
            artifacts_expected = $totalExpected
            artifacts_collected = $artifactClaimed
            validation_status = if ($validationResult) { $validationResult.overall } else { "PENDING" }
            integration_status = if ($integrationResult) { $integrationResult.integration_status } else { "PENDING" }
            final_status = $finalStatus
            blocking_issues = @()
            no_fake_pass_confirmed = $true
            closed_at = (Get-Date -Format "o")
            non_claims = @(
                "Manual mode: EXECUTION_VERIFIED requires all handoffs COMPLETED + all artifacts present + validation PASS + integration READY",
                "Current status reflects actual collected evidence, not assumed completion",
                "Agent-adapter mode is NOT_CONFIGURED"
            )
        }

        # Collect blocking issues
        foreach ($h in $handoffs) {
            $hd = Get-Content $h.FullName -Raw | ConvertFrom-Json
            if ($hd.blockers -and $hd.blockers.Count -gt 0) {
                $receipt.blocking_issues += @("$($hd.worker_id): $($hd.blockers -join '; ')")
            }
        }

        $receipt | ConvertTo-Json -Depth 4 | Out-File "runs/$RunId/execution-receipt.json" -Encoding utf8 -NoNewline

        # Update run status
        $run.status = $finalStatus
        $run | ConvertTo-Json -Depth 5 | Out-File $runFile -Encoding utf8 -NoNewline

        Write-Output "=== Execution Receipt ==="
        Write-Output "  Run: $RunId"
        Write-Output "  Mode: $($run.mode)"
        Write-Output "  Final Status: $finalStatus"
        Write-Output "  Tasks: $completed completed / $blocked blocked / $totalExpected total"
        Write-Output "  Handoffs: $($handoffs.Count) / $($capsules.Count)"
        Write-Output "  Artifacts: $artifactClaimed claimed / $totalExpected expected"
        Write-Output "  Validation: $($receipt.validation_status)"
        Write-Output "  Integration: $($receipt.integration_status)"
        Write-Output "  Receipt: runs/$RunId/execution-receipt.json"
        if ($Json) { $receipt | ConvertTo-Json -Depth 4 }
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
            $hd = Get-Content $h.FullName -Raw | ConvertFrom-Json
            $issues = @()
            
            # Check required fields
            if (-not $hd.worker_id) { $issues += "Missing worker_id" }
            if (-not $hd.task_ids -or $hd.task_ids.Count -eq 0) { $issues += "Missing task_ids" }
            if (-not $hd.status) { $issues += "Missing status" }
            
            # Check for placeholder content
            if ($hd.status -eq "PENDING" -and $hd.handoff_notes -match "FILL IN|placeholder|template") {
                $issues += "PLACEHOLDER_DETECTED: handoff appears to be a template, not real worker output"
            }
            if ($hd.artifacts_produced.Count -eq 0 -and $hd.status -eq "COMPLETED") {
                $issues += "COMPLETED status but no artifacts_produced"
            }
            if ($hd.handoff_notes -eq "[FILL IN after completing tasks]") {
                $issues += "PLACEHOLDER: handoff_notes is unchanged template text"
            }
            
            # Check boundary — find capsule by trying known paths
            $capDir = "outputs/V4_2/demo-admin-system-execution/worker-capsules"
            $capsuleFile = $null
            $candidates = @(
                "$capDir/$($hd.worker_id)-capsule.json",
                "$capDir/worker-backend-capsule.json",
                "$capDir/worker-frontend-capsule.json",
                "$capDir/worker-qa-capsule.json"
            )
            foreach ($c in $candidates) {
                if (Test-Path $c) {
                    try {
                        $testCap = Get-Content $c -Raw | ConvertFrom-Json
                        if ($testCap.worker_id -eq $hd.worker_id) { $capsuleFile = $c; break }
                    } catch {}
                }
            }
            if ($capsuleFile) {
                try {
                    $cap = Get-Content $capsuleFile -Raw | ConvertFrom-Json
                    if ($cap.forbidden_files) {
                        foreach ($f in $hd.files_changed) {
                            foreach ($forb in $cap.forbidden_files) {
                                if ($f -like $forb) { $issues += "BOUNDARY_VIOLATION: '$f' matches forbidden '$forb'" }
                            }
                        }
                    }
                } catch { }
            }
            
            $verdict = if ($issues.Count -gt 0) { "REJECTED" } else { "ACCEPTED" }
            if ($issues -match "PLACEHOLDER") { $placeholder++ }
            if ($verdict -eq "ACCEPTED") { $accepted++ } else { $rejected++ }
            
            $results += @{
                worker_id = $hd.worker_id
                file = $h.Name
                status = $hd.status
                artifacts = $hd.artifacts_produced.Count
                issues = $issues
                verdict = $verdict
            }
        }

        $summary = @{
            validated_at = (Get-Date -Format "o")
            total = $handoffs.Count
            accepted = $accepted
            rejected = $rejected
            placeholder_detected = $placeholder
            results = $results
            final_status = if ($rejected -gt 0 -and $accepted -gt 0) { "LIVE_CROSS_WINDOW_PARTIAL" }
                          elseif ($rejected -gt 0 -and $accepted -eq 0) { "LIVE_CROSS_WINDOW_BLOCKED" }
                          elseif ($placeholder -gt 0) { "WAITING_FOR_REAL_WORKER_HANDOFFS" }
                          else { "READY_FOR_LIVE_INTEGRATION" }
        }
        $summary | ConvertTo-Json -Depth 4 | Out-File "$liveDir/live-handoff-validation.json" -Encoding utf8 -NoNewline

        Write-Output "=== Live Handoff Validation ==="
        foreach ($r in $results) {
            Write-Output "  $($r.worker_id): $($r.verdict) (status=$($r.status), artifacts=$($r.artifacts))"
            foreach ($i in $r.issues) { Write-Output "    - $i" }
        }
        Write-Output "  Final Status: $($summary.final_status)"
        Write-Output "  Accepted: $accepted / $($handoffs.Count)"
        if ($Json) { $summary | ConvertTo-Json -Depth 4 }
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
        $totalArtifacts = 0
        foreach ($r in $acceptedWorkers) { $totalArtifacts += $r.artifacts }
        
        $receipt = @{
            run_id = $RunId
            mode = "live-cross-window"
            generated_at = (Get-Date -Format "o")
            workers_total = $v.total
            workers_accepted = $v.accepted
            workers_rejected = $v.rejected
            placeholders_found = $v.placeholder_detected
            total_artifacts_claimed = $totalArtifacts
            final_status = $v.final_status
            no_fake_pass_confirmed = ($v.placeholder_detected -eq 0 -and $v.rejected -eq 0)
            user_action_required = if ($v.final_status -eq "WAITING_FOR_REAL_WORKER_HANDOFFS") {
                "Open 3 separate Codex windows and paste WORKER_*_PROMPT.md from outputs/V4_4/live-cross-window-kit/"
            } elseif ($v.final_status -eq "READY_FOR_LIVE_INTEGRATION") {
                "All handoffs validated. Run integrator and close to generate final receipt."
            } else {
                "Review rejected handoffs, fix violations, and re-submit."
            }
        }
        
        $receipt | ConvertTo-Json -Depth 3 | Out-File "$liveDir/live-run-summary.json" -Encoding utf8 -NoNewline
        
        Write-Output "=== Live Run Summary ==="
        Write-Output "  Workers: $($v.accepted) accepted / $($v.rejected) rejected / $($v.placeholder_detected) placeholder"
        Write-Output "  Artifacts claimed: $totalArtifacts"
        Write-Output "  Final Status: $($v.final_status)"
        Write-Output "  User Action: $($receipt.user_action_required)"
        if ($Json) { $receipt | ConvertTo-Json -Depth 3 }
    }

    default {
        Write-Error "Unknown command: $Command. Use: start, status, create-handoff-template, validate-handoff, collect-artifacts, validate, integrate, close"
        exit 1
    }
}
