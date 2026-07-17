# Playwright Result Parser v1.0.0
# Part of: FACTORY-R3.0
# Parses Playwright JSON reporter output.

function Parse-PlaywrightResult {
    param(
        [Parameter(Mandatory=$true)][string]$RawOutput,
        [string]$EngineId = "playwright"
    )

    $result = @{
        engine_id = $EngineId
        status = "CLEAN"
        findings_count = 0
        findings_by_severity = @{ ERROR = 0; WARNING = 0; INFO = 0 }
        findings = @()
        raw_output_summary = ""
        evidence_binding = @{
            evidence_type = "e2e_results"
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

        $passed = 0; $failed = 0; $skipped = 0

        if ($data.suites) {
            foreach ($suite in $data.suites) {
                if ($suite.specs) {
                    foreach ($spec in $suite.specs) {
                        if ($spec.tests) {
                            foreach ($test in $spec.tests) {
                                $testResults = @($test.results | Where-Object { $_.status -ne "expected" })
                                if ($testResults.Count -eq 0) { $passed++ }
                                else {
                                    $failed++
                                    $result.findings += [PSCustomObject]@{
                                        rule_id = "playwright-e2e-failure"
                                        severity = "ERROR"
                                        file = $spec.file
                                        line = $test.line
                                        message = "$($spec.title) > $($test.title)"
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }

        $result.findings_count = $failed
        $result.findings_by_severity.ERROR = $failed
        $result.findings_by_severity.INFO = $passed

        if ($failed -gt 0) {
            $result.status = "FINDINGS_PRESENT"
        } else {
            $result.status = "CLEAN"
        }

        $result.raw_output_summary = "Playwright: $passed passed, $failed failed, $skipped skipped"
        $result.evidence_binding.evidence_summary = $result.raw_output_summary
    } catch {
        # Fallback: parse text output
        $result.raw_output_summary = ($RawOutput -split "`n" | Select-Object -First 5) -join "; "
        if ($RawOutput -match "(\d+) passed") { $result.status = "CLEAN" }
        elseif ($RawOutput -match "(\d+) failed") { $result.status = "FINDINGS_PRESENT" }
        else { $result.status = "FINDINGS_PRESENT" }
    }

    return [PSCustomObject]$result
}
