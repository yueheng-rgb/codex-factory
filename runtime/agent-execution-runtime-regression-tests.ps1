# Negative and binding regressions for the hardened V4 compatibility runtime.
# This script only creates data below a unique system-temp directory.

param()

$ErrorActionPreference = "Stop"
$RuntimeScript = Join-Path $PSScriptRoot "agent-execution-runtime.ps1"
$PowerShellExe = (Get-Process -Id $PID).Path
$TempBase = [IO.Path]::GetFullPath([IO.Path]::GetTempPath()).TrimEnd('\','/')
$TestRoot = Join-Path $TempBase ("codex-factory-v4-runtime-test-" + [guid]::NewGuid().ToString("N"))
$RunId = "runtime-regression"
$RunRoot = Join-Path $TestRoot "runs/$RunId"
$Assertions = 0

function Write-JsonFile([string]$Path, $Value) {
    $parent = Split-Path -Parent $Path
    if (-not (Test-Path -LiteralPath $parent)) { New-Item -ItemType Directory -Force -Path $parent | Out-Null }
    $Value | ConvertTo-Json -Depth 10 | Set-Content -LiteralPath $Path -Encoding UTF8
}

function Assert-Equal($Expected, $Actual, [string]$Message) {
    $script:Assertions++
    if ($Expected -ne $Actual) {
        throw "$Message (expected='$Expected', actual='$Actual')"
    }
}

function Invoke-Runtime([string]$Command) {
    Push-Location $TestRoot
    try {
        $output = & $PowerShellExe -NoLogo -NoProfile -ExecutionPolicy Bypass -File $RuntimeScript -Command $Command -RunId $RunId -Json 2>&1 | Out-String
        if ($LASTEXITCODE -ne 0) { throw "Runtime command '$Command' exited $LASTEXITCODE`n$output" }
        return $output
    } finally {
        Pop-Location
    }
}

try {
    foreach ($directory in @("input","worker-capsules","handoffs","artifacts","validation","integration")) {
        New-Item -ItemType Directory -Force -Path (Join-Path $RunRoot $directory) | Out-Null
    }

    Write-JsonFile (Join-Path $RunRoot "execution-run.json") @{
        run_id=$RunId; mode="manual"; task_count=1; worker_count=1; status="READY_FOR_MANUAL_WORKER_EXECUTION"
        source_plan_hashes=@{ agent_execution_plan="A"; task_graph="B"; worker_plan="C"; validation_plan="D" }
    }
    Write-JsonFile (Join-Path $RunRoot "input/validation_plan.json") @{
        per_task_validation=@(@{ task_id="T1"; methods=@("artifact"); required_evidence=@("T1-output"); blocking=$true })
        global_gates=@()
    }
    Write-JsonFile (Join-Path $RunRoot "worker-capsules/worker-one-capsule.json") @{
        worker_id="worker-one"; assigned_tasks=@("T1"); required_output_artifacts=@("T1-output")
        forbidden_files=@("config/secrets*"); handoff_required=$true
    }
    Write-JsonFile (Join-Path $RunRoot "handoffs/worker-one-handoff.json") @{
        worker_id="worker-one"; task_ids=@("T1"); status="COMPLETED"; files_changed=@()
        artifacts_produced=@("T1-output"); tests_run=0; tests_passed=0; tests_failed=0
        validation_result="PASS"; blockers=@(); assumptions=@(); handoff_notes="Implemented T1"; next_agent="integrator"
        timestamp=(Get-Date -Format "o")
    }

    # A claimed artifact without a run-local physical file must fail closed.
    [void](Invoke-Runtime "validate")
    $validation = Get-Content -LiteralPath (Join-Path $RunRoot "validation/validation-result.json") -Raw | ConvertFrom-Json
    Assert-Equal "FAIL" $validation.overall "Missing physical artifact must fail validation"
    [void](Invoke-Runtime "integrate")
    $integration = Get-Content -LiteralPath (Join-Path $RunRoot "integration/integration-report.json") -Raw | ConvertFrom-Json
    Assert-Equal "INTEGRATION_BLOCKED" $integration.integration_status "Missing artifact must block integration"
    [void](Invoke-Runtime "close")
    $receipt = Get-Content -LiteralPath (Join-Path $RunRoot "execution-receipt.json") -Raw | ConvertFrom-Json
    Assert-Equal $false $receipt.no_fake_pass_confirmed "Missing artifact cannot confirm no-fake-pass"
    Assert-Equal 0 $receipt.artifacts_collected "Claim count cannot masquerade as physical artifact count"

    # Traversal cannot bind an outside file as run evidence.
    Set-Content -LiteralPath (Join-Path $RunRoot "outside.txt") -Value "outside" -Encoding UTF8
    $handoffPath = Join-Path $RunRoot "handoffs/worker-one-handoff.json"
    $handoff = Get-Content -LiteralPath $handoffPath -Raw | ConvertFrom-Json
    $handoff.artifacts_produced = @("../outside.txt")
    Write-JsonFile $handoffPath $handoff
    [void](Invoke-Runtime "validate")
    $validation = Get-Content -LiteralPath (Join-Path $RunRoot "validation/validation-result.json") -Raw | ConvertFrom-Json
    Assert-Equal "FAIL" $validation.overall "Artifact path traversal must fail validation"

    # A non-empty physical artifact can pass an artifact-only legacy plan.
    $handoff.artifacts_produced = @("T1-output")
    Write-JsonFile $handoffPath $handoff
    Set-Content -LiteralPath (Join-Path $RunRoot "artifacts/T1-output") -Value "physical evidence" -Encoding UTF8
    [void](Invoke-Runtime "validate")
    $validation = Get-Content -LiteralPath (Join-Path $RunRoot "validation/validation-result.json") -Raw | ConvertFrom-Json
    Assert-Equal "PASS" $validation.overall "Physical artifact should pass an artifact-only plan"
    [void](Invoke-Runtime "integrate")
    $integration = Get-Content -LiteralPath (Join-Path $RunRoot "integration/integration-report.json") -Raw | ConvertFrom-Json
    Assert-Equal "READY_FOR_INTEGRATION" $integration.integration_status "Bound validation should allow legacy integration readiness"
    [void](Invoke-Runtime "close")
    $receipt = Get-Content -LiteralPath (Join-Path $RunRoot "execution-receipt.json") -Raw | ConvertFrom-Json
    Assert-Equal $true $receipt.no_fake_pass_confirmed "Fully bound legacy evidence should confirm no-fake-pass"
    Assert-Equal "READY_FOR_INTEGRATION" $receipt.final_status "Legacy close may only report integration readiness"

    # Evidence drift after validation/integration invalidates both bindings.
    Add-Content -LiteralPath (Join-Path $RunRoot "artifacts/T1-output") -Value "drift"
    [void](Invoke-Runtime "close")
    $receipt = Get-Content -LiteralPath (Join-Path $RunRoot "execution-receipt.json") -Raw | ConvertFrom-Json
    Assert-Equal $false $receipt.no_fake_pass_confirmed "Artifact drift must invalidate no-fake-pass confirmation"
    Assert-Equal "VALIDATION_BLOCKED" $receipt.final_status "Artifact drift must invalidate the validation snapshot"

    # The legacy live-handoff branch uses the same physical checks and a bound
    # snapshot; it cannot accept a text-only handoff or survive later drift.
    Set-Content -LiteralPath (Join-Path $RunRoot "artifacts/T1-output") -Value "live physical evidence" -Encoding UTF8
    New-Item -ItemType Directory -Force -Path (Join-Path $RunRoot "live-handoffs") | Out-Null
    Copy-Item -LiteralPath $handoffPath -Destination (Join-Path $RunRoot "live-handoffs/worker-one-handoff.json")
    [void](Invoke-Runtime "validate-live-handoff")
    $liveValidation = Get-Content -LiteralPath (Join-Path $RunRoot "live-handoffs/live-handoff-validation.json") -Raw | ConvertFrom-Json
    Assert-Equal "READY_FOR_LIVE_INTEGRATION" $liveValidation.final_status "Live handoff requires physical evidence before readiness"
    [void](Invoke-Runtime "summarize-live-run")
    $liveSummary = Get-Content -LiteralPath (Join-Path $RunRoot "live-handoffs/live-run-summary.json") -Raw | ConvertFrom-Json
    Assert-Equal $true $liveSummary.no_fake_pass_confirmed "Bound live evidence may confirm no-fake-pass"
    Add-Content -LiteralPath (Join-Path $RunRoot "artifacts/T1-output") -Value "post-live-validation drift"
    [void](Invoke-Runtime "summarize-live-run")
    $liveSummary = Get-Content -LiteralPath (Join-Path $RunRoot "live-handoffs/live-run-summary.json") -Raw | ConvertFrom-Json
    Assert-Equal $false $liveSummary.no_fake_pass_confirmed "Live evidence drift must invalidate no-fake-pass confirmation"
    Assert-Equal "LIVE_CROSS_WINDOW_BLOCKED" $liveSummary.final_status "Live evidence drift must block integration"

    # Required gates and non-artifact methods cannot silently skip evidence.
    Write-JsonFile (Join-Path $RunRoot "input/validation_plan.json") @{
        per_task_validation=@(@{ task_id="T1"; methods=@("artifact","test"); required_evidence=@("T1-output"); blocking=$true })
        global_gates=@(@{ gate="secret-scan"; status="required"; condition="before close" })
    }
    [void](Invoke-Runtime "validate")
    $validation = Get-Content -LiteralPath (Join-Path $RunRoot "validation/validation-result.json") -Raw | ConvertFrom-Json
    Assert-Equal "PARTIAL" $validation.overall "Missing test and gate receipts must remain pending"
    Assert-Equal 1 $validation.summary.pending "Missing test receipt must leave the task pending"
    Assert-Equal 1 $validation.summary.gate_pending "Missing required gate receipt must leave the gate pending"
} finally {
    # The exact target is a GUID-owned child of the resolved system temp path.
    $resolvedTestRoot = [IO.Path]::GetFullPath($TestRoot)
    if ($resolvedTestRoot.StartsWith($TempBase + [IO.Path]::DirectorySeparatorChar, [StringComparison]::OrdinalIgnoreCase) -and
        (Split-Path -Leaf $resolvedTestRoot) -match '^codex-factory-v4-runtime-test-[0-9a-f]{32}$') {
        Remove-Item -LiteralPath $resolvedTestRoot -Recurse -Force -ErrorAction SilentlyContinue
    }
}

Write-Output "PASS: agent-execution-runtime regressions ($Assertions assertions)"
