# Read-only Search Adapter
# Part of: FACTORY-R2.3-K
. (Join-Path (Split-Path $PSScriptRoot -Parent) "runtime\tool-registry-loader.ps1")
. (Join-Path (Split-Path $PSScriptRoot -Parent) "runtime\tool-permission-gate.ps1")
. (Join-Path (Split-Path $PSScriptRoot -Parent) "runtime\tool-invocation-logger.ps1")

function Import-SearchResult {
    param([Parameter(Mandatory=$true)]$InputPath,[string]$ProjectId="PROJ-SEARCH-INTAKE",[string]$AgentId="RSRC-001")
    $gr = Test-ToolPermission -ProjectId $ProjectId -AgentId $AgentId -ToolId "TOOL-SEARCH-ADAPTER-001" -ProjectType "all" -SandboxAvailable $true -HumanApproved $true -NetworkAllowed $false -SecretsAllowed $false -FileWriteAllowed $false -CloudAllowed $false
    if (-not (Test-Path $InputPath)) { return [PSCustomObject]@{accepted=$false;reason="Input file not found";gateDecision=$gr.Decision} }
    try { $input = Get-Content $InputPath -Raw -Encoding UTF8 | ConvertFrom-Json } catch { return [PSCustomObject]@{accepted=$false;reason="JSON parse error";gateDecision=$gr.Decision} }
    $ic = 0; $pass = $true
    if (-not $input.query) { $ic++; $pass = $false }
    if (-not $input.provider) { $ic++; $pass = $false }
    if (-not $input.sourceRefs -or $input.sourceRefs.Count -eq 0) { $ic++; $pass = $false }
    if (-not $input.claimedFacts -or $input.claimedFacts.Count -eq 0) { $ic++; $pass = $false }
    $isAi = $input.provider -match "ai_generated|chatgpt|glm|claude|perplexity"
    if ($isAi -and ($input.sourceRefs.Count -eq 0)) { $ic++; $pass = $false }
    $trust = if ($input.provider -match "official_docs") { "TRUSTED_REFERENCE" } elseif ($isAi) { "NEEDS_HUMAN_REVIEW" } else { "REFERENCE_ONLY" }
    $action = if ($pass -and $input.provider -match "official_docs") { "review_and_capsule" } elseif ($pass) { "human_review_required" } else { "reject_or_resubmit" }
    $pkt = [PSCustomObject]@{intakeId="SEARCH-INTAKE-$(Get-Date -Format 'yyyyMMddHHmmss')";query=$input.query;provider=$input.provider;providerConfidence=$input.providerConfidence;sourceCount=$input.sourceRefs.Count;factCount=$input.claimedFacts.Count;accepted=$pass;issueCount=$ic;trustRecommendation=$trust;recommendedAction=$action;sourceRefs=$input.sourceRefs;claimedFacts=$input.claimedFacts;importedAt=Get-Date -Format "yyyy-MM-ddTHH:mm:sszzz";caveats=@("Read-only adapter: no API keys","No network calls","Results must be reviewed before knowledge bank")}
    Write-ToolInvocation -ProjectId $ProjectId -PhaseId "research" -AgentId $AgentId -ToolId "TOOL-SEARCH-ADAPTER-001" -RequestedAction "import" -Decision $(if($pass){"ALLOW_WITH_CONTROLS"}else{"REJECT"}) -Reason "Search intake: accepted=$pass issues=$ic" -SandboxMode "dryRun" -HumanApproval $true -NetworkUsed $false -SecretsUsed $false
    return $pkt
}

function Convert-ToResearchPacket { param($IntakePacket)
    return [PSCustomObject]@{researchQuestion=$IntakePacket.query;sourceList=$IntakePacket.sourceRefs;sourcePriority=if($IntakePacket.provider -match "official_docs"){"high"}else{"medium"};factClaims=$IntakePacket.claimedFacts;freshnessRisk="unknown";applicability="to_be_reviewed";recommendedKnowledgeCapsules=@();recommendedSkillCandidates=@();requiredVerifier=if($IntakePacket.provider -match "ai_generated"){"human"}else{"librarian"};caveats=$IntakePacket.caveats}
}
Write-Verbose "Read-only Search Adapter initialized."
