# reject-preclassified-only-negative.ps1 — Phase 6C-H6
# Returns FAIL_MISSING_EVIDENCE if a negative relies solely on pre-classified domain-negative-result.json
param([Parameter(Mandatory=$true)][string]$RunDir)
$ErrorActionPreference = "Continue"

$dnr = Join-Path $RunDir "reports\domain-negative-result.json"
$tr = Join-Path $RunDir "reports\acceptance-transcript.json"
$fm = Join-Path $RunDir "fault-manifest.json"

$hasTranscript = Test-Path $tr
$hasFaultManifest = Test-Path $fm
$hasDnr = Test-Path $dnr

if ($hasDnr -and -not $hasTranscript -and -not $hasFaultManifest) {
    $result = @{verdict="FAIL"; classification="FAIL_MISSING_EVIDENCE"; reason="Pre-classified domain-negative-result.json without live execution evidence"; hasTranscript=$false; hasFaultManifest=$false; hasDomainNegativeResult=$true; timestamp=(Get-Date).ToString("o")}
} elseif ($hasTranscript -and $hasFaultManifest) {
    $result = @{verdict="ALLOW"; classification="LIVE_EVIDENCE_PRESENT"; reason="Live execution evidence found"; hasTranscript=$true; hasFaultManifest=$true; hasDomainNegativeResult=$hasDnr; timestamp=(Get-Date).ToString("o")}
} elseif ($hasDnr -and $hasFaultManifest -and -not $hasTranscript) {
    $result = @{verdict="FAIL"; classification="FAIL_MISSING_EVIDENCE"; reason="Fault manifest present but no execution transcript"; hasTranscript=$false; hasFaultManifest=$true; hasDomainNegativeResult=$true; timestamp=(Get-Date).ToString("o")}
} else {
    $result = @{verdict="FAIL"; classification="FAIL_MISSING_EVIDENCE"; reason="Insufficient evidence for target-gate negative"; hasTranscript=$hasTranscript; hasFaultManifest=$hasFaultManifest; hasDomainNegativeResult=$hasDnr; timestamp=(Get-Date).ToString("o")}
}

Write-Output ($result | ConvertTo-Json)
if ($result.verdict -eq "FAIL") { exit 1 } else { exit 0 }

