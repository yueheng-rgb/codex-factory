param(
  [string]$RunId = ("RUN-V2_1-" + (Get-Date -Format "yyyyMMdd-HHmmss")),
  [string]$FactoryRoot = "C:\Codex_App_Factory"
)
Write-Output "RunId=[$RunId]"
Write-Output "FR=[$FactoryRoot]"
