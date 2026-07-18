[CmdletBinding()]
param(
    [string]$ProjectRoot,
    [switch]$MultiAgent,
    [switch]$NoExternalContext,
    [ValidateSet("none", "glm")]
    [string]$Search = "none",
    [ValidateRange(2, 8)]
    [int]$MaxThreads = 4
)

$ErrorActionPreference = "Stop"
$packageRoot = Split-Path -Parent $MyInvocation.MyCommand.Path

if (-not (Get-Command node -ErrorAction SilentlyContinue)) {
    throw "Node.js 24 or newer is required. Install Node.js, then run this installer again."
}
if (-not (Get-Command npm -ErrorAction SilentlyContinue)) {
    throw "npm is required. Install it with Node.js, then run this installer again."
}

$nodeVersionText = (& node --version).TrimStart("v")
$nodeMajor = [int]($nodeVersionText.Split(".")[0])
if ($nodeMajor -lt 24) {
    throw "Node.js 24 or newer is required; found $nodeVersionText."
}

Push-Location $packageRoot
try {
    & npm install
    if ($LASTEXITCODE -ne 0) { throw "npm install failed with exit code $LASTEXITCODE." }

    & npm run build
    if ($LASTEXITCODE -ne 0) { throw "Factory CLI build failed with exit code $LASTEXITCODE." }

    & npm link
    if ($LASTEXITCODE -ne 0) { throw "npm link failed with exit code $LASTEXITCODE." }
}
finally {
    Pop-Location
}

Write-Host "Codex App Factory CLI installed: factoryctl"

if ($ProjectRoot) {
    $resolvedProject = (Resolve-Path -LiteralPath $ProjectRoot).Path
    $factoryArguments = @("init", "--project", $resolvedProject, "--search", $Search, "--max-threads", "$MaxThreads")
    if ($MultiAgent) { $factoryArguments += "--multi-agent" }
    if ($NoExternalContext) { $factoryArguments += "--no-external-context" } else { $factoryArguments += "--external-context" }
    & factoryctl @factoryArguments
    if ($LASTEXITCODE -ne 0) { throw "Factory project initialization failed with exit code $LASTEXITCODE." }
    Write-Host "Project initialized. Run: factoryctl doctor --project `"$resolvedProject`""
}

if ($Search -eq "glm") {
    Write-Host "GLM search is enabled. Set ZHIPUAI_API_KEY or create .codex-factory/secrets.env in the project; do not pass the key on the command line."
}
