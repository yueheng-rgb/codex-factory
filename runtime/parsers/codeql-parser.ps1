# CodeQL Parser v1.0.0
# Parses CodeQL SARIF output into structured engine evidence
param(
    [string]$SarifPath,
    [string]$TargetProject = "unknown"
)

function Invoke-CodeQLParse {
    param([string]$Path)
    
    if (-not $Path -or -not (Test-Path $Path)) {
        return [PSCustomObject]@{ parser_status = "NO_INPUT"; error = "SARIF file not found: $Path" }
    }
    
    try {
        $sarif = Get-Content $Path -Raw | ConvertFrom-Json
        $runs = $sarif.runs
        if (-not $runs -or $runs.Count -eq 0) {
            return [PSCustomObject]@{ parser_status = "EMPTY_RESULT"; findings = @(); rule_count = 0; message = "No runs in SARIF output" }
        }
        
        $allResults = @()
        $allRules = @{}
        foreach ($run in $runs) {
            if ($run.tool.driver.rules) {
                foreach ($rule in $run.tool.driver.rules) { $allRules[$rule.id] = $rule }
            }
            if ($run.results) {
                foreach ($r in $run.results) {
                    $allResults += [PSCustomObject]@{
                        rule_id = $r.ruleId
                        severity = $r.level
                        message = $r.message.text
                        locations = @($r.locations | ForEach-Object { $_.physicalLocation.artifactLocation.uri })
                    }
                }
            }
        }
        
        return [PSCustomObject]@{
            parser_status = "OK"
            findings_count = $allResults.Count
            rule_count = $allRules.Count
            findings = $allResults
            rules = $allRules
            target_project = $TargetProject
        }
    } catch {
        return [PSCustomObject]@{ parser_status = "PARSE_ERROR"; error = $_.Exception.Message }
    }
}

# Main
$result = Invoke-CodeQLParse -Path $SarifPath
$result | ConvertTo-Json -Depth 4
