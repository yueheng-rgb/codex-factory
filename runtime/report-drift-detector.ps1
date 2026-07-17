# Report Drift Detector v1.0.0
param(
    [Parameter(Mandatory=$true)][string]$ReportPath,
    [string]$LedgerPath = "C:\Codex_App_Factory\outputs\audit-ledger.json"
)

if (-not (Test-Path $ReportPath)) {
    [PSCustomObject]@{drift_detected=$false; reason="Report not found"} | ConvertTo-Json; return
}
if (-not (Test-Path $LedgerPath)) {
    [PSCustomObject]@{drift_detected=$false; reason="No ledger to compare"} | ConvertTo-Json; return
}

try {
    $report = Get-Content $ReportPath -Raw
    $ledger = @(Get-Content $LedgerPath -Raw | ConvertFrom-Json)
    
    $drifts = @()
    
    # Check: report mentions test count that differs from ledger's last regression entry
    $lastReg = $ledger | Where-Object { $_.event_type -eq "REGRESSION_RUN" } | Select-Object -Last 1
    if ($lastReg) {
        $reportMatch = [regex]::Matches($report, '(\d+)/(\d+)\s*(?:tests?\s*)?PASS')
        foreach ($m in $reportMatch) {
            $claimed = [int]$m.Groups[1].Value
            $ledgerCount = if ($lastReg.result_summary -match '(\d+)/(\d+)') { [int]$Matches[1] } else { 0 }
            if ($claimed -ne $ledgerCount -and $ledgerCount -gt 0) {
                $drifts += "REPORT_DRIFT: Report claims $claimed tests PASS, ledger shows $ledgerCount"
            }
        }
    }
    
    # Check: report mentions engine status that conflicts with ledger
    $lastEngine = $ledger | Where-Object { $_.event_type -eq "ENGINE_RUN" } | Select-Object -Last 1
    if ($lastEngine -and $report -match "semgrep.*not.*available|codeql.*AVAILABLE|k6.*AVAILABLE") {
        $drifts += "REPORT_DRIFT: Engine status in report conflicts with ledger entries"
    }
    
    $result = [PSCustomObject]@{
        drift_id = "DRIFT-$(Get-Date -Format 'yyyyMMddHHmmss')"
        drift_detected = ($drifts.Count -gt 0)
        drifts = $drifts
        report_path = $ReportPath
        ledger_last_entry = if ($ledger.Count -gt 0) { $ledger[-1].entry_id } else { "NONE" }
        timestamp = (Get-Date -Format "yyyy-MM-ddTHH:mm:ss")
    }
    
    $result | ConvertTo-Json -Depth 3
} catch {
    [PSCustomObject]@{drift_detected=$false; error=$_.Exception.Message} | ConvertTo-Json
}
