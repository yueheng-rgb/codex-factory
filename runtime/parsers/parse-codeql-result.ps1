# CodeQL Result Parser v1.0.0
# Part of: FACTORY-R3.0
# Parses CodeQL SARIF output into standardized findings.

function Parse-CodeQLResult {
    param(
        [Parameter(Mandatory=$true)][string]$RawOutput,
        [string]$EngineId = "codeql"
    )

    $result = @{
        engine_id = $EngineId
        status = "CLEAN"
        findings_count = 0
        findings_by_severity = @{ ERROR = 0; WARNING = 0; INFO = 0 }
        findings = @()
        raw_output_summary = ""
        evidence_binding = @{
            evidence_type = "security_findings"
            evidence_summary = ""
            evidence_files = @()
        }
    }

    if (-not $RawOutput -or $RawOutput.Trim().Length -eq 0) {
        $result.status = "TOOL_FAILED"
        $result.raw_output_summary = "Empty output"
        return [PSCustomObject]$result
    }

    try {
        $data = $RawOutput | ConvertFrom-Json

        # SARIF format
        if ($data.runs) {
            foreach ($run in $data.runs) {
                if ($run.results) {
                    foreach ($finding in $run.results) {
                        $severity = if ($finding.properties."problem.severity") {
                            $finding.properties."problem.severity".ToUpper()
                        } elseif ($finding.level) {
                            $finding.level.ToUpper()
                        } else {
                            "WARNING"
                        }
                        if ($severity -eq "RECOMMENDATION") { $severity = "INFO" }
                        if ($severity -notin @("ERROR","WARNING","INFO")) { $severity = "WARNING" }

                        $result.findings_by_severity[$severity]++
                        $result.findings_count++

                        $result.findings += [PSCustomObject]@{
                            rule_id = $finding.ruleId
                            severity = $severity
                            file = if ($finding.locations[0].physicalLocation.artifactLocation.uri) {
                                $finding.locations[0].physicalLocation.artifactLocation.uri
                            } else { "" }
                            line = if ($finding.locations[0].physicalLocation.region.startLine) {
                                $finding.locations[0].physicalLocation.region.startLine
                            } else { 0 }
                            message = if ($finding.message.text) { $finding.message.text } else { $finding.ruleId }
                        }
                    }
                }
            }
        }

        if ($result.findings_count -gt 0) {
            $result.status = "FINDINGS_PRESENT"
            $result.raw_output_summary = "CodeQL: $($result.findings_count) findings ($($result.findings_by_severity.ERROR) ERROR, $($result.findings_by_severity.WARNING) WARNING, $($result.findings_by_severity.INFO) INFO)"
        } else {
            $result.status = "CLEAN"
            $result.raw_output_summary = "CodeQL: No findings"
        }

        $result.evidence_binding.evidence_summary = $result.raw_output_summary
    } catch {
        $result.raw_output_summary = ($RawOutput -split "`n" | Select-Object -First 10) -join "; "
        $result.status = if ($RawOutput -match "found 0 results") { "CLEAN" } else { "FINDINGS_PRESENT" }
    }

    return [PSCustomObject]$result
}
