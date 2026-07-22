$ErrorActionPreference = "Stop"

$runtimeRoot = Split-Path $PSScriptRoot -Parent
$null = . (Join-Path $runtimeRoot "evidence-pack-builder.ps1")
$null = . (Join-Path $runtimeRoot "pre-build-research-gate.ps1")

$script:passed = 0
$script:failed = 0
$script:tempFiles = New-Object System.Collections.Generic.List[string]

function Assert-True {
    param([bool]$Condition, [string]$Message)
    if ($Condition) {
        $script:passed++
        Write-Output "PASS: $Message"
    }
    else {
        $script:failed++
        Write-Output "FAIL: $Message"
    }
}

function Save-TestPack {
    param($Pack)
    $path = Join-Path ([System.IO.Path]::GetTempPath()) ("codex-factory-evidence-{0}.json" -f [guid]::NewGuid().ToString("N"))
    $json = $Pack | ConvertTo-Json -Depth 15
    [System.IO.File]::WriteAllText($path, $json, (New-Object System.Text.UTF8Encoding($false)))
    $script:tempFiles.Add($path)
    return $path
}

function New-LiveResponse {
    param([int]$SourceCount = 5, [string]$Query = "Implement JWT security")
    $sources = @()
    for ($index = 1; $index -le $SourceCount; $index++) {
        $sources += [PSCustomObject]@{
            title = "Evidence source $index"
            url = "https://docs.example.com/source-$index"
            sourceType = if ($index -eq 1) { "official_docs" } else { "community" }
            publishDate = Get-Date -Format "yyyy-MM-dd"
            source_origin = "provider_search_result"
            source_language = "en"
            snippet = "Independent evidence excerpt $index"
        }
    }
    return [PSCustomObject]@{
        accepted = $true
        provider = "glm_search"
        mode = "live_api"
        searchToolInvoked = $true
        sourceRefs = $sources
        normalizedResults = @()
        caveats = @()
        secretPresent = $true
        humanApproval = $true
        query = $Query
    }
}

try {
    # Builder regression: a fatal quality verdict can never be converted into
    # an accepted/pass Evidence Pack or expose implementation actions.
    $fatalResponse = [PSCustomObject]@{
        accepted = $true
        provider = "glm_search"
        mode = "dry_run"
        searchToolInvoked = $false
        sourceRefs = @([PSCustomObject]@{title="Fixture";url="https://example.com/fixture";sourceType="official_docs";publishDate=(Get-Date -Format "yyyy-MM-dd")})
        normalizedResults = @([PSCustomObject]@{title="Fixture";url="https://example.com/fixture";snippet="Mock data"})
        caveats = @("dry run fixture")
        secretPresent = $false
        humanApproval = $false
        query = "fixture"
    }
    $fatalPack = New-EvidencePack -Task "fixture" -ProjectId "TEST" -TriggerReason "initial_search" -GLMResponse $fatalResponse
    Assert-True ($fatalPack.qualityGateStatus.verdict -eq "FAIL_FATAL") "negative fixture reaches FAIL_FATAL"
    Assert-True ($fatalPack.accepted -eq $false) "FAIL_FATAL is never accepted"
    Assert-True ($fatalPack.qualityGateStatus.passed -eq $false) "FAIL_FATAL is never marked passed"
    Assert-True ("use_in_implementation" -notin @($fatalPack.allowedNextActions)) "failed evidence exposes no implementation action"
    Assert-True ("do_not_use_for_implementation" -in @($fatalPack.forbiddenUse)) "failed evidence is explicitly forbidden for implementation"

    # P0 must fail closed without an Evidence Pack, including Chinese risks.
    $zhTask = -join @([char]23454,[char]29616,[char]30331,[char]24405,[char]35748,[char]35777,[char]21644,[char]35282,[char]33394,[char]26435,[char]38480,[char]25511,[char]21046)
    $missingGate = Invoke-PreBuildResearchGate -TaskDescription $zhTask -AgentId "RSRC-001"
    Assert-True ($missingGate.search_level -eq "P0_MUST_SEARCH") "Chinese auth/permission task is P0"
    Assert-True ($missingGate.security_critical -eq $true) "Chinese security keywords set security_critical"
    Assert-True ($missingGate.gate_passed -eq $false) "P0 without evidence is blocked"
    Assert-True ("EVIDENCE_PACK_REQUIRED" -in @($missingGate.fatal_violations)) "missing P0 evidence records a fatal violation"

    # A valid live pack binds by physical path.
    $p0Task = "Implement JWT security"
    $validPack = New-EvidencePack -Task $p0Task -ProjectId "TEST" -PhaseId "implementation" -TriggerReason "initial_search" -GLMResponse (New-LiveResponse -SourceCount 5 -Query $p0Task)
    $validPath = Save-TestPack -Pack $validPack
    $validGate = Invoke-PreBuildResearchGate -TaskDescription $p0Task -PhaseId "implementation" -ExistingEvidencePackId $validPath -Context @{ProjectId="TEST"}
    if (-not $validGate.gate_passed) { Write-Output "DEBUG P0: $(@($validGate.fatal_violations) -join '; ')" }
    Assert-True ($validPack.accepted -eq $true) "live quality-gated pack is accepted"
    Assert-True ($validGate.gate_passed -eq $true) "valid P0 evidence passes the gate"
    Assert-True ($validGate.evidence_pack_bound -eq $true) "valid P0 evidence is bound"
    Assert-True ($validGate.evidence_validation.contentHashVerified -eq $true) "content hash is recomputed and verified"
    Assert-True ($validGate.evidence_validation.sourceCount -eq 5) "P0 source budget is verified"
    Assert-True ($validGate.evidence_validation.officialSourceCount -ge 1) "P0 official source minimum is verified"
    Assert-True ("use_in_implementation" -notin @($validPack.allowedNextActions)) "builder requires gate binding before implementation"

    # The same pack can be resolved by ID when an explicit bounded path is
    # supplied in Context (filename and evidenceId need not match).
    $idGate = Invoke-PreBuildResearchGate -TaskDescription $p0Task -PhaseId "implementation" -ExistingEvidencePackId $validPack.evidenceId -Context @{ProjectId="TEST";EvidencePackPath=$validPath}
    Assert-True ($idGate.gate_passed -eq $true -and $idGate.evidence_pack_id -eq $validPack.evidenceId) "Evidence Pack ID resolves through Context path"
    $wrongFileHashGate = Invoke-PreBuildResearchGate -TaskDescription $p0Task -PhaseId "implementation" -ExistingEvidencePackId $validPath -Context @{ProjectId="TEST";EvidencePackFileSha256=("0" * 64)}
    Assert-True ($wrongFileHashGate.gate_passed -eq $false -and ((@($wrongFileHashGate.fatal_violations) -join "|") -match "FILE_HASH_MISMATCH")) "caller-supplied file hash mismatch is blocked"

    $caveatPack = $validPack | ConvertTo-Json -Depth 15 | ConvertFrom-Json
    $caveatPack.qualityGateStatus.verdict = "PASS_WITH_CAVEATS"
    $caveatPack.qualityGateStatus.trustRecommendation = "needs_human_review"
    $caveatPack.contentHash = Get-EvidencePackIntegrityHash -EvidencePack $caveatPack
    $caveatPath = Save-TestPack -Pack $caveatPack
    $caveatBlocked = Invoke-PreBuildResearchGate -TaskDescription $p0Task -PhaseId "implementation" -ExistingEvidencePackId $caveatPath -Context @{ProjectId="TEST"}
    $caveatApproved = Invoke-PreBuildResearchGate -TaskDescription $p0Task -PhaseId "implementation" -ExistingEvidencePackId $caveatPath -Context @{ProjectId="TEST";EvidenceHumanApproved=$true}
    Assert-True ($caveatBlocked.gate_passed -eq $false) "PASS_WITH_CAVEATS is blocked without explicit review"
    Assert-True ($caveatApproved.gate_passed -eq $true) "reviewed PASS_WITH_CAVEATS can bind explicitly"

    # Recompute a fully valid hash around a fatal verdict: verdict validation,
    # not only hash validation, must still block it.
    $fatalVerdictPack = $validPack | ConvertTo-Json -Depth 15 | ConvertFrom-Json
    $fatalVerdictPack.accepted = $true
    $fatalVerdictPack.qualityGateStatus.passed = $true
    $fatalVerdictPack.qualityGateStatus.verdict = "FAIL_FATAL"
    $fatalVerdictPack.contentHash = Get-EvidencePackIntegrityHash -EvidencePack $fatalVerdictPack
    $fatalVerdictPath = Save-TestPack -Pack $fatalVerdictPack
    $fatalVerdictGate = Invoke-PreBuildResearchGate -TaskDescription $p0Task -PhaseId "implementation" -ExistingEvidencePackId $fatalVerdictPath -Context @{ProjectId="TEST"}
    Assert-True ($fatalVerdictGate.gate_passed -eq $false) "hash-valid FAIL_FATAL pack is blocked"
    Assert-True ((@($fatalVerdictGate.fatal_violations) -join "|") -match "QUALITY_VERDICT") "fatal verdict rejection is reported"

    # Any content mutation without a new canonical hash is detected.
    $tamperedPack = $validPack | ConvertTo-Json -Depth 15 | ConvertFrom-Json
    $tamperedPack.sources[0].title = "Tampered title"
    $tamperedPath = Save-TestPack -Pack $tamperedPack
    $tamperedGate = Invoke-PreBuildResearchGate -TaskDescription $p0Task -PhaseId "implementation" -ExistingEvidencePackId $tamperedPath -Context @{ProjectId="TEST"}
    Assert-True ($tamperedGate.gate_passed -eq $false) "tampered pack is blocked"
    Assert-True ((@($tamperedGate.fatal_violations) -join "|") -match "CONTENT_HASH_MISMATCH") "tampering reports content hash mismatch"

    $actionTamperedPack = $validPack | ConvertTo-Json -Depth 15 | ConvertFrom-Json
    $actionTamperedPack.allowedNextActions += "use_in_implementation"
    $actionTamperedPath = Save-TestPack -Pack $actionTamperedPack
    $actionTamperedGate = Invoke-PreBuildResearchGate -TaskDescription $p0Task -PhaseId "implementation" -ExistingEvidencePackId $actionTamperedPath -Context @{ProjectId="TEST"}
    Assert-True ($actionTamperedGate.gate_passed -eq $false) "authorization-action tampering is blocked"
    Assert-True ((@($actionTamperedGate.fatal_violations) -join "|") -match "CONTENT_HASH_MISMATCH") "authorization-action tampering is covered by the hash"

    # A caller cannot make model-extracted URLs canonical merely by recomputing
    # the unkeyed integrity hash; provenance is validated separately.
    $wrongOriginPack = $validPack | ConvertTo-Json -Depth 15 | ConvertFrom-Json
    $wrongOriginPack.sources[0].sourceOrigin = "model_text_extraction"
    $wrongOriginPack.contentHash = Get-EvidencePackIntegrityHash -EvidencePack $wrongOriginPack
    $wrongOriginPath = Save-TestPack -Pack $wrongOriginPack
    $wrongOriginGate = Invoke-PreBuildResearchGate -TaskDescription $p0Task -PhaseId "implementation" -ExistingEvidencePackId $wrongOriginPath -Context @{ProjectId="TEST"}
    Assert-True ($wrongOriginGate.gate_passed -eq $false) "model-extracted source provenance is blocked"
    Assert-True ((@($wrongOriginGate.fatal_violations) -join "|") -match "SOURCE_ORIGIN_NOT_CANONICAL") "non-canonical source origin is reported"

    # Stale packs and stale sources fail even with a recomputed valid hash.
    $stalePack = $validPack | ConvertTo-Json -Depth 15 | ConvertFrom-Json
    $stalePack.queryTime = [datetimeoffset]::Now.AddDays(-120).ToString("o")
    foreach ($source in $stalePack.sources) {
        $source.retrievedAt = [datetimeoffset]::Now.AddDays(-120).ToString("o")
        $source.freshness = "current"
    }
    $stalePack.contentHash = Get-EvidencePackIntegrityHash -EvidencePack $stalePack
    $stalePath = Save-TestPack -Pack $stalePack
    $staleGate = Invoke-PreBuildResearchGate -TaskDescription $p0Task -PhaseId "implementation" -ExistingEvidencePackId $stalePath -Context @{ProjectId="TEST"}
    Assert-True ($staleGate.gate_passed -eq $false) "stale Evidence Pack is blocked"
    Assert-True ((@($staleGate.fatal_violations) -join "|") -match "STALE|INSUFFICIENT_FRESH") "staleness failure is reported"

    # Task/phase binding prevents reusing good evidence for a different job.
    $wrongTaskGate = Invoke-PreBuildResearchGate -TaskDescription "Implement OAuth security" -PhaseId "implementation" -ExistingEvidencePackId $validPath -Context @{ProjectId="TEST"}
    Assert-True ($wrongTaskGate.gate_passed -eq $false) "evidence cannot be reused for a different task"
    Assert-True ((@($wrongTaskGate.fatal_violations) -join "|") -match "TASK_MISMATCH") "task binding failure is reported"

    # P1 is also evidence-bound and has the smaller two-source budget.
    $p1Task = "Compare unfamiliar UI components"
    $p1Missing = Invoke-PreBuildResearchGate -TaskDescription $p1Task -PhaseId "implementation"
    Assert-True ($p1Missing.search_level -eq "P1_SHOULD_SEARCH" -and $p1Missing.gate_passed -eq $false) "P1 without evidence is blocked"
    $p1Pack = New-EvidencePack -Task $p1Task -ProjectId "TEST" -PhaseId "implementation" -TriggerReason "initial_search" -GLMResponse (New-LiveResponse -SourceCount 2 -Query $p1Task)
    $p1Path = Save-TestPack -Pack $p1Pack
    $p1Gate = Invoke-PreBuildResearchGate -TaskDescription $p1Task -PhaseId "implementation" -ExistingEvidencePackId $p1Path -Context @{ProjectId="TEST"}
    if (-not $p1Gate.gate_passed) { Write-Output "DEBUG P1: $(@($p1Gate.fatal_violations) -join '; ')" }
    Assert-True ($p1Gate.search_level -eq "P1_SHOULD_SEARCH" -and $p1Gate.gate_passed -eq $true) "valid two-source P1 evidence passes"

    Write-Output "RESULT: $script:passed passed, $script:failed failed"
    if ($script:failed -gt 0) { exit 1 }
}
finally {
    foreach ($tempFile in $script:tempFiles) {
        if ([System.IO.File]::Exists($tempFile) -and [System.IO.Path]::GetFileName($tempFile).StartsWith("codex-factory-evidence-")) {
            [System.IO.File]::Delete($tempFile)
        }
    }
}
