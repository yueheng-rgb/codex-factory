# append-decision.ps1 — Append a decision entry to decision-log.jsonl
param([Parameter(Mandatory)]$ProjectPath, [Parameter(Mandatory)]$Decision, [Parameter(Mandatory)]$Rationale, $Context="", $Stage="", $Actor="append-decision.ps1")

$cfDir = Join-Path $ProjectPath ".codex-factory"
$dlPath = Join-Path $cfDir "decision-log.jsonl"
if (-not (Test-Path $dlPath)) { Write-Error "decision-log.jsonl not found. Run init-memory.ps1 first."; exit 1 }

$entry = @{timestamp=(Get-Date).ToString("o");decision=$Decision;rationale=$Rationale;context=$Context;stage=$Stage;actor=$Actor;projectId=(Get-Content (Join-Path $cfDir "project-state.json") -Raw | ConvertFrom-Json).projectId;version="0.1.0"}
$line = $entry | ConvertTo-Json -Compress

Add-Content -Path $dlPath -Value $line -Encoding UTF8
Write-Host "Decision appended: $Decision"
@{status="ok";decision=$Decision;timestamp=$entry.timestamp} | ConvertTo-Json
