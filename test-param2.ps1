param(
  [string]$RunId = ("RUN-" + (Get-Date -Format "HHmmss")),
  [string]$FactoryRoot = "C:\Codex_App_Factory"
)
Write-Output "RunId=[$RunId]"
