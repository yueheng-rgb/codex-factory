# detect-domain-knowledge-gaps.ps1 — Phase 6C-H3
# Checks a compiled run package for domain knowledge coverage gaps.
param(
    [Parameter(Mandatory=$true)][string]$CompiledDir
)

$ErrorActionPreference = "Continue"
$gaps = [System.Collections.ArrayList]::new()
$passes = [System.Collections.ArrayList]::new()
$exitCode = 0
$severityCounts = @{ critical=0; high=0; medium=0; low=0 }

$domainPath = Join-Path $CompiledDir "domain-skill-pack.json"
$verifierPath = Join-Path $CompiledDir "domain-verifier-pack.json"
$contractPath = Join-Path $CompiledDir "run-contract.json"

if (-not (Test-Path $domainPath)) { [void]$gaps.Add(@{type="MISSING_DOMAIN";severity="critical";detail="domain-skill-pack.json not found"}); $severityCounts.critical++; $exitCode=1 }
if (-not (Test-Path $verifierPath)) { [void]$gaps.Add(@{type="MISSING_VERIFIER";severity="critical";detail="domain-verifier-pack.json not found"}); $severityCounts.critical++; $exitCode=1 }

if ((Test-Path $domainPath) -and (Test-Path $verifierPath)) {
    try { $domain = Get-Content $domainPath -Raw -Encoding UTF8 | ConvertFrom-Json } catch { [void]$gaps.Add(@{type="DOMAIN_JSON_INVALID";severity="critical";detail="Cannot parse domain-skill-pack.json"}); $severityCounts.critical++; $exitCode=1 }
    try { $verifier = Get-Content $verifierPath -Raw -Encoding UTF8 | ConvertFrom-Json } catch { [void]$gaps.Add(@{type="VERIFIER_JSON_INVALID";severity="critical";detail="Cannot parse domain-verifier-pack.json"}); $severityCounts.critical++; $exitCode=1 }

    if ($domain -and $verifier) {
        # Gap 1: Business rule without acceptance scenario
        $scenarioNames = $verifier.acceptanceScenarios | ForEach-Object { $_.scenarioId }
        if ($domain.businessRules) {
            foreach ($rule in $domain.businessRules) {
                # Check if any scenario covers this rule (via acceptanceImplication keyword match)
                $covered = $false
                foreach ($sc in $verifier.acceptanceScenarios) {
                    if ($sc.description -match $rule.ruleId -or $sc.description -match $rule.description.Substring(0,[Math]::Min(20,$rule.description.Length))) { $covered = $true; break }
                }
                if (-not $covered) {
                    [void]$gaps.Add(@{type="RULE_WITHOUT_SCENARIO";severity=$rule.severity;detail="Rule $($rule.ruleId): $($rule.description)";ruleId=$rule.ruleId})
                    $severityCounts[$rule.severity]++
                    $exitCode = 1
                }
            }
            if ($gaps.Count -eq 0) { [void]$passes.Add("All business rules have acceptance scenarios") }
        }

        # Gap 2: Business rule without negative control
        if ($verifier.negativeControls) {
            $negTargets = $verifier.negativeControls | ForEach-Object { $_.targetsScenario }
            foreach ($sc in $verifier.acceptanceScenarios) {
                if ($sc.scenarioId -notin $negTargets) {
                    [void]$gaps.Add(@{type="SCENARIO_WITHOUT_NEGATIVE";severity="medium";detail="Scenario $($sc.scenarioId): $($sc.description) has no negative control";scenarioId=$sc.scenarioId})
                    $severityCounts.medium++
                    $exitCode = 1
                }
            }
            if (($verifier.acceptanceScenarios | Where-Object { $_.scenarioId -notin $negTargets }).Count -eq 0) {
                [void]$passes.Add("All scenarios have negative controls")
            }
        }

        # Gap 3: Invariant not covered by scenario
        if ($domain.invariants -and $verifier.invariantChecks) {
            $coveredInvariants = $verifier.invariantChecks | ForEach-Object { $_.invariant }
            foreach ($inv in $domain.invariants) {
                $found = $coveredInvariants | Where-Object { $inv -match $_ -or $_ -match $inv }
                if (-not $found) {
                    [void]$gaps.Add(@{type="INVARIANT_WITHOUT_SCENARIO";severity="high";detail="Invariant not covered: $inv";invariant=$inv})
                    $severityCounts.high++
                    $exitCode = 1
                }
            }
            if (($domain.invariants | Where-Object { $inv = $_; -not ($coveredInvariants | Where-Object { $inv -match $_ -or $_ -match $inv }) }).Count -eq 0) {
                [void]$passes.Add("All invariants covered by scenarios")
            }
        }

        # Gap 4: Domain entity not assigned to any worker
        if ($domain.domainEntities -and $domain.requiredWorkerResponsibilities) {
            $domainEntityIds = $domain.domainEntities | ForEach-Object { $_.entityId }
            $assigned = @()
            $domain.requiredWorkerResponsibilities | ForEach-Object {
                if ($_.assignedEntities) { $script:assigned += $_.assignedEntities }
            }
            foreach ($eid in $domainEntityIds) {
                if ($eid -notin $assigned) {
                    [void]$gaps.Add(@{type="ENTITY_NOT_ASSIGNED";severity="high";detail="Entity $eid not assigned to any worker";entityId=$eid})
                    $severityCounts.high++
                    $exitCode = 1
                }
            }
            if (($domainEntityIds | Where-Object { $_ -notin $assigned }).Count -eq 0) {
                [void]$passes.Add("All entities assigned to workers")
            }
        }

        # Gap 5: Forbidden assumption without verifier coverage
        if ($domain.forbiddenAssumptions) {
            foreach ($fa in $domain.forbiddenAssumptions) {
                $covered = $false
                foreach ($sc in $verifier.acceptanceScenarios) {
                    $keywords = $fa -split "\s+"
                    if ($keywords | Where-Object { $sc.description -match $_ }) { $covered = $true; break }
                }
                if (-not $covered) {
                    [void]$gaps.Add(@{type="ASSUMPTION_NOT_COVERED";severity="medium";detail="Forbidden assumption not covered: $fa";assumption=$fa})
                    $severityCounts.medium++
                    $exitCode = 1
                }
            }
        }

        # Gap 6: No example data for required workflow
        if ($domain.workflows -and $domain.exampleData) {
            $wfNames = $domain.workflows | ForEach-Object { $_.name }
            $exNames = $domain.exampleData | ForEach-Object { $_.scenario }
            foreach ($wf in $wfNames) {
                if ($wf -notin $exNames) {
                    [void]$gaps.Add(@{type="WORKFLOW_WITHOUT_EXAMPLE";severity="low";detail="Workflow without example data: $wf";workflow=$wf})
                    $severityCounts.low++
                }
            }
        }
    }
}

$verdict = if ($exitCode -eq 0) { "PASS" } else { "FAIL_GAPS_DETECTED" }
$result = @{
    verdict = $verdict
    gapCount = $gaps.Count
    gaps = $gaps
    severityCounts = $severityCounts
    passCount = $passes.Count
    passDetails = $passes
    checkedAt = (Get-Date).ToString("o")
}
Write-Output ($result | ConvertTo-Json -Depth 4)
exit $exitCode