# Workflow Search Consistency Check (R2.6)
# Verifies: Gate classification matches actual search execution

function Test-WorkflowSearchConsistency {
    param(
        [string]$GateLevel,
        [int]$SearchQueriesExecuted,
        [string]$EvidencePackRef,
        [string]$EscalationReason = ""
    )

    $result = [PSCustomObject]@{
        consistent = $true
        violations = @()
        severity = "PASS"
    }

    # Rule 1: P2 must not execute search
    if ($GateLevel -eq "P2_NO_SEARCH_REQUIRED" -and $SearchQueriesExecuted -gt 0) {
        if (-not $EscalationReason) {
            $result.consistent = $false
            $result.violations += "P2_SEARCH_EXECUTED_WITHOUT_ESCALATION: Gate=$GateLevel, queries=$SearchQueriesExecuted, escalation='$EscalationReason'"
            $result.severity = "FAIL_WORKFLOW_CONSISTENCY"
        } else {
            $result.violations += "P2_ESCALATED: reason='$EscalationReason'. Queries executed but with documented escalation."
            $result.severity = "PASS_WITH_ESCALATION"
        }
    }

    # Rule 2: If search executed, EP must exist
    if ($SearchQueriesExecuted -gt 0 -and -not $EvidencePackRef) {
        $result.consistent = $false
        $result.violations += "SEARCH_WITHOUT_EP: queries=$SearchQueriesExecuted, but no Evidence Pack ref"
        $result.severity = "FAIL_WORKFLOW_CONSISTENCY"
    }

    # Rule 3: If EP exists but Gate says P2 with no escalation
    if ($EvidencePackRef -and $GateLevel -eq "P2_NO_SEARCH_REQUIRED" -and -not $EscalationReason) {
        $result.consistent = $false
        $result.violations += "EP_WITH_P2_NO_ESCALATION: EP ref='$EvidencePackRef' but Gate=P2 with no escalation"
        $result.severity = "FAIL_WORKFLOW_CONSISTENCY"
    }

    # Rule 4: P0/P1 may search (consistent)
    if ($GateLevel -in @("P0_MUST_SEARCH","P1_SHOULD_SEARCH")) {
        # Normal — search is allowed
    }

    return $result
}

Write-Output "Workflow Search Consistency Check loaded (R2.6)"
