# Engine Evidence Binder v2.0.0
# Binds external engine results to structured evidence for gate decisions
param(
    [Parameter(Mandatory=$true)][string]$EngineId,
    [Parameter(Mandatory=$true)][string]$TargetProject,
    [string]$EngineVersion = "unknown",
    [string]$RunStatus = "SKIPPED",
    [string]$TargetUrlOrPath = "",
    [string]$CommandRedacted = "",
    [string]$ResultSummary = "",
    [string]$SkipReason = "",
    [string]$FailureClassification = "",
    [string]$SourceOrigin = "",
    [string]$FindingsJson = "[]",
    [string]$NonClaimsJson = "[]",
    [string]$ParserStatus = "NO_INPUT",
    [switch]$SecretPresent
)

$evidence = [PSCustomObject]@{
    evidence_id = "EV-$(Get-Date -Format 'yyyyMMddHHmmss')-$EngineId-$TargetProject"
    engine_id = $EngineId
    engine_version = $EngineVersion
    run_status = $RunStatus
    target_project = $TargetProject
    target_url_or_path = $TargetUrlOrPath
    command_redacted = $CommandRedacted
    started_at = (Get-Date -Format 'yyyy-MM-ddTHH:mm:ss')
    duration_seconds = 0
    result_summary = $ResultSummary
    findings = (ConvertFrom-Json $FindingsJson -ErrorAction SilentlyContinue) ?? @()
    findings_count = 0
    severity_summary = @{}
    parser_status = $ParserStatus
    non_claims = (ConvertFrom-Json $NonClaimsJson -ErrorAction SilentlyContinue) ?? @()
    skip_reason = $SkipReason
    failure_classification = $FailureClassification
    secret_present = $SecretPresent.IsPresent
    source_origin = $SourceOrigin
    verified = $false
}

# Key safety: NEVER output secrets
if ($CommandRedacted -match "(key=|secret=|token=|apikey=)[^\s&]+") {
    Write-Warning "ENGINE-EVIDENCE-SECURITY: command_redacted may contain secrets — sanitize before binding"
    $evidence.command_redacted = "[REDACTED_FOR_SECURITY]"
}

return $evidence
