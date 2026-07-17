# register-verifier-hash.ps1 — Phase 6C-H1
# Registers a verifier script's SHA256 hash into the verifier registry.
param(
    [Parameter(Mandatory=$true)][string]$ScriptPath,
    [Parameter(Mandatory=$true)][string]$RegistryPath,
    [string]$Phase = "Phase 6C-H1",
    [string]$Purpose = "",
    [string]$RegisteredBy = "H1-Factory-Core"
)
$ErrorActionPreference = "Stop"
if (-not (Test-Path $ScriptPath)) { Write-Error "Script not found: $ScriptPath"; exit 1 }
if (-not (Test-Path $RegistryPath)) {
    @{ schemaVersion="H1-R1"; registry=@(); createdAt=(Get-Date).ToString("o") } | ConvertTo-Json -Depth 4 | Set-Content $RegistryPath -Encoding UTF8
}
$registry = Get-Content $RegistryPath -Raw -Encoding UTF8 | ConvertFrom-Json
$hash = (Get-FileHash $ScriptPath -Algorithm SHA256).Hash
$scriptRel = (Resolve-Path $ScriptPath).Path -replace [regex]::Escape((Resolve-Path (Join-Path $PSScriptRoot "..\..")).Path + "\"), ""
$entry = [ordered]@{
    scriptPath = $scriptRel
    sha256 = $hash
    registeredAt = (Get-Date).ToString("o")
    registeredBy = $RegisteredBy
    phase = $Phase
    purpose = $Purpose
    previousHash = if ($registry.registry.Count -gt 0) { $registry.registry[-1].registryEntryHash } else { "GENESIS" }
}
$canonical = [ordered]@{}
foreach ($k in ($entry.Keys | Sort-Object)) { $canonical[$k] = $entry[$k] }
$entry.registryEntryHash = (Get-FileHash -InputStream ([System.IO.MemoryStream]::new([System.Text.Encoding]::UTF8.GetBytes(($canonical | ConvertTo-Json -Compress)))) -Algorithm SHA256).Hash
$newRegistry = [ordered]@{ schemaVersion = $registry.schemaVersion; registry = @($registry.registry) + @($entry); updatedAt = (Get-Date).ToString("o") }
$newRegistry | ConvertTo-Json -Depth 4 | Set-Content $RegistryPath -Encoding UTF8
Write-Output (ConvertTo-Json -Depth 3 -Compress @{ status="REGISTERED"; scriptPath=$scriptRel; sha256=$hash; registryEntryHash=$entry.registryEntryHash })
