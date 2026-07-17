param([string]$RunId = "DEFAULT-RUN-ID")
Write-Output "Before dot-source: RunId=[$RunId]"
. C:\Codex_App_Factory\runtime\ci-artifact-store.ps1
Write-Output "After dot-source: RunId=[$RunId]"
Write-Output "script:RunId=[$script:RunId]"
