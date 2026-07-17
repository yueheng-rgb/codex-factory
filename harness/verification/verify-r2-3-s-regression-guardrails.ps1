# R2.3-S Regression Guardrails Verification v2
# Fixed: results array scoping, Write-Output capture

. (Join-Path $PSScriptRoot "..\..\runtime\search-result-quality-gate.ps1")

$fixtureDir = Join-Path $PSScriptRoot "..\..\runtime\tests\regression"
$results = [System.Collections.ArrayList]::new()

function Invoke-RegressionTest {
    param($FixturePath, $TestName, $ExpectedDecision)
    if (-not (Test-Path $FixturePath)) {
        return [PSCustomObject]@{test=$TestName;result="SKIP";expected=$ExpectedDecision;actual="N/A";verdict="N/A";score=0;fatalRejections="fixture not found"}
    }
    $fixture = Get-Content $FixturePath -Raw | ConvertFrom-Json
    $intake = $fixture.intakePacket
    $searchInvoked = if ($fixture.searchInvoked -ne $null) { [bool]$fixture.searchInvoked } else { $false }
    $actualMode = if ($fixture.actualMode) { $fixture.actualMode.ToString() } else { "dry_run" }
    $ep = if ($fixture.evidencePack) { $fixture.evidencePack } else { $null }

    $quality = Test-SearchResultQuality -IntakePacket $intake -SearchInvoked $searchInvoked -ActualMode $actualMode -EvidencePack $ep
    $actualDecision = if ($quality.verdict -eq "reject") { "REJECT" } else { "PASS" }
    $passed = ($actualDecision -eq $ExpectedDecision)

    return [PSCustomObject]@{
        test = $TestName
        result = if ($passed) { "PASS" } else { "FAIL" }
        expected = $ExpectedDecision
        actual = $actualDecision
        verdict = $quality.verdict
        score = $quality.score
        maxScore = $quality.maxScore
        fatalRejections = ($quality.fatalRejections -join "; ")
    }
}

$tests = @(
    @{Path=(Join-Path $fixtureDir "positive-live-search-fixture.json"); Name="REGRESSION-A: Positive live-search"; Expected="PASS"},
    @{Path=(Join-Path $fixtureDir "negative-plain-chat-fixture.json"); Name="REGRESSION-B: Negative plain-chat (LLM knowledge)"; Expected="REJECT"},
    @{Path=(Join-Path $fixtureDir "negative-api-endpoint-fixture.json"); Name="REGRESSION-C: Negative API-endpoint-source"; Expected="REJECT"},
    @{Path=(Join-Path $fixtureDir "negative-mock-dryrun-fixture.json"); Name="REGRESSION-D: Negative mock/dry_run mislabeled"; Expected="REJECT"}
)

$pass = 0; $fail = 0
foreach ($t in $tests) {
    $r = Invoke-RegressionTest -FixturePath $t.Path -TestName $t.Name -ExpectedDecision $t.Expected
    [void]$results.Add($r)
    $mark = if ($r.result -eq "PASS") { "PASS"; $pass++ } else { "FAIL"; $fail++ }
    Write-Output "[$mark] $($r.test)"
    Write-Output "     expected=$($r.expected) actual=$($r.actual) verdict=$($r.verdict) score=$($r.score)/$($r.maxScore)"
    if ($r.fatalRejections) { Write-Output "     fatal: $($r.fatalRejections)" }
}

$resultsFile = Join-Path $PSScriptRoot "..\..\outputs\FACTORY_R2_3_S_REGRESSION_RESULTS.json"
$results | ConvertTo-Json -Depth 4 | Set-Content $resultsFile -Encoding UTF8

Write-Output "`n============================================"
Write-Output "SUMMARY: $pass PASS / $fail FAIL / $($results.Count) TOTAL"
Write-Output "Results: $resultsFile"
if ($fail -gt 0) { exit 1 } else { exit 0 }
