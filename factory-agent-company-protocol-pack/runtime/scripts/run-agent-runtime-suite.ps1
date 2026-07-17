param([Parameter(Mandatory=$true)][string]$ManifestPath,[string]$ProtocolPackRoot)
if(-not$ProtocolPackRoot){$ProtocolPackRoot=Split-Path -Parent (Split-Path -Parent $PSScriptRoot)}
$is="$ProtocolPackRoot\runtime\scripts\check-agent-protocol-integrity.ps1"
& powershell -NoProfile -File $is -ManifestPath $ManifestPath -ProtocolPackRoot $ProtocolPackRoot
exit $LASTEXITCODE
