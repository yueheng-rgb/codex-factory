# Semgrep Result Parser v1.0.0
# Part of: FACTORY-R3.0
# Parses semgrep JSON output into standardized findings.

function Parse-SemgrepResult {
    param(
        [Parameter(Mandatory=$true)][string]$RawOutput,
        [string]$EngineId = "semgrep"
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
        # Semgrep outputs progress text + JSON. Extract the JSON portion.
        $jsonStart = $RawOutput.IndexOf("{`"version`":")
        if ($jsonStart -ge 0) {
            $jsonPart = $RawOutput.Substring($jsonStart)
            $jsonEnd = $jsonPart.LastIndexOf("}")
            if ($jsonEnd -ge 0) {
                $jsonPart = $jsonPart.Substring(0, $jsonEnd + 1)
            }
        } else {
            $jsonPart = $RawOutput
        }
        $data = $jsonPart | ConvertFrom-Json

        if ($data.results) {
            $result.findings_count = $data.results.Count
            foreach ($finding in $data.results) {
                $severity = if ($finding.extra.severity) { $finding.extra.severity.ToString().ToUpper() } else { "WARNING" }
                if ($severity -notin @("ERROR","WARNING","INFO")) { $severity = "WARNING" }

                $result.findings_by_severity[$severity]++

                $result.findings += [PSCustomObject]@{
                    rule_id = $finding.check_id
                    severity = $severity
                    file = $finding.path
                    line = if ($finding.start) { $finding.start.line } else { 0 }
                    message = if ($finding.extra.message) { $finding.extra.message } else { $finding.check_id }
                }
            }
        }

        if ($result.findings_count -gt 0) {
            $result.status = "FINDINGS_PRESENT"
            $result.raw_output_summary = "semgrep: $($result.findings_count) findings ($($result.findings_by_severity.ERROR) ERROR, $($result.findings_by_severity.WARNING) WARNING, $($result.findings_by_severity.INFO) INFO)"
        } else {
            $result.status = "CLEAN"
            $result.raw_output_summary = "semgrep: No findings"
        }

        $result.evidence_binding.evidence_summary = $result.raw_output_summary
    } catch {
        # Fallback: try line-by-line parsing
        $lines = $RawOutput -split "`n"
        $result.raw_output_summary = ($lines | Select-Object -First 10) -join "; "
        $result.status = if ($RawOutput -match "No findings") { "CLEAN" } else { "FINDINGS_PRESENT" }
    }

    return [PSCustomObject]$result
}
