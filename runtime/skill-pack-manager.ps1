# Codex Factory V4.0.1 — Skill Pack Manager
# Usage: powershell -File runtime/skill-pack-manager.ps1 -Action <list|validate|create-template|enable|disable|remove> [-Name <name>] [-Json]

param([Parameter(Mandatory=$true)][string]$Action, [string]$Name, [switch]$Json)

$packsDir = "packs"
$enabledFile = "packs/enabled-packs.json"
if (-not (Test-Path $packsDir)) { New-Item -ItemType Directory -Force -Path $packsDir | Out-Null }

function Get-Enabled { if (Test-Path $enabledFile) { return Get-Content $enabledFile -Raw | ConvertFrom-Json } else { return @{ enabled=@(); updated=(Get-Date -Format "o") } } }
function Save-Enabled($e) { $e.updated = (Get-Date -Format "o"); $e | ConvertTo-Json -Depth 3 | Out-File -FilePath $enabledFile -Encoding utf8 -NoNewline }

$result = @{ action=$Action; timestamp=(Get-Date -Format "o"); status="OK" }

switch ($Action) {
    "list" {
        $packs = Get-ChildItem $packsDir -Directory -ErrorAction SilentlyContinue | Where-Object { $_.Name -ne "_template" }
        $en = Get-Enabled
        $result.packs = @($packs | ForEach-Object {
            $m = if (Test-Path "$($_.FullName)/pack.json") { Get-Content "$($_.FullName)/pack.json" -Raw | ConvertFrom-Json } else { $null }
            @{ name=$_.Name; version=if($m){$m.version}else{"?"}; enabled=($en.enabled -contains $_.Name); description=if($m){$m.description}else{"No manifest"} }
        })
        $result.count = $result.packs.Count
    }
    "validate" {
        $targets = if ($Name) { @($Name) } else { @(Get-ChildItem $packsDir -Directory | Where-Object { $_.Name -ne "_template" } | ForEach-Object { $_.Name }) }
        $result.details = @()
        foreach ($t in $targets) {
            $packPath = "$packsDir/$t"
            $checks = @{}
            $checks.packJson = Test-Path "$packPath/pack.json"
            $checks.rules = Test-Path "$packPath/rules.md"
            $checks.prompts = Test-Path "$packPath/prompts.md"
            $checks.validation = Test-Path "$packPath/validation.md"
            $checks.examples = Test-Path "$packPath/examples/"
            $valid = $checks.packJson
            $result.details += @{ name=$t; valid=$valid; checks=$checks }
        }
        $result.status = if (($result.details | Where-Object { -not $_.valid }).Count -eq 0) { "VALID" } else { "INVALID" }
    }
    "create-template" {
        if (-not $Name) { $result.status="ERROR"; $result.detail="Name required"; break }
        $packPath = "$packsDir/$Name"
        if (Test-Path $packPath) { $result.status="EXISTS"; $result.detail="$packPath already exists"; break }
        New-Item -ItemType Directory -Force -Path $packPath, "$packPath/examples" | Out-Null

        # pack.json
        @{ name=$Name; version="1.0.0"; description="User skill pack: $Name"; target_project_types=@("custom-complex-project"); triggers=@(); rules=@(); forbidden_actions=@(); validation_requirements=@(); required_artifacts=@(); enabled=$false; dependencies=@(); compatible_factory_version="4.0" } | ConvertTo-Json -Depth 3 | Out-File -FilePath "$packPath/pack.json" -Encoding utf8

        # rules.md
        @"
# $Name — Rules

<!-- Define rules this skill pack enforces during project execution -->

## Code Rules
- 

## Architecture Rules
- 

## Security Rules
- 

## Testing Rules
- 
"@ | Out-File -FilePath "$packPath/rules.md" -Encoding utf8

        # prompts.md
        @"
# $Name — Prompts

<!-- Define reusable prompt templates for this domain -->

## Project Start Prompt
\`\`\`
[Context: new project in $Name domain]
[Task: describe what Codex should do]
\`\`\`

## Validation Prompt
\`\`\`
[Context: verify $Name project]
[Task: describe what to validate]
\`\`\`
"@ | Out-File -FilePath "$packPath/prompts.md" -Encoding utf8

        # validation.md
        @"
# $Name — Validation Requirements

<!-- Define what must be verified for this skill pack to PASS -->

## Required Checks
1. 

## Artifact Requirements
1. 

## Evidence Requirements
1. 
"@ | Out-File -FilePath "$packPath/validation.md" -Encoding utf8

        # examples/example-task.md
        @"
# Example Task: $Name

## Context
Project type: [fill in]
Goal: [fill in]

## Expected Codex Behavior
1. 

## Verification
- [ ] Check 1
- [ ] Check 2
"@ | Out-File -FilePath "$packPath/examples/example-task.md" -Encoding utf8

        $result.detail = "Created template at $packPath (pack.json + rules.md + prompts.md + validation.md + examples/)"
        $result.files = @("pack.json","rules.md","prompts.md","validation.md","examples/example-task.md")
    }
    "enable" {
        if (-not $Name) { $result.status="ERROR"; $result.detail="Name required"; break }
        if (-not (Test-Path "$packsDir/$Name/pack.json")) { $result.status="NOT_FOUND"; break }
        $en = Get-Enabled
        if ($en.enabled -notcontains $Name) { $en.enabled += $Name }
        Save-Enabled $en
        $result.detail = "Enabled: $Name"
    }
    "disable" {
        if (-not $Name) { $result.status="ERROR"; $result.detail="Name required"; break }
        $en = Get-Enabled
        $en.enabled = @($en.enabled | Where-Object { $_ -ne $Name })
        Save-Enabled $en
        $result.detail = "Disabled: $Name"
    }
    "remove" {
        if (-not $Name) { $result.status="ERROR"; $result.detail="Name required"; break }
        $packPath = "$packsDir/$Name"
        if (-not (Test-Path $packPath)) { $result.status="NOT_FOUND"; break }
        $en = Get-Enabled; $en.enabled = @($en.enabled | Where-Object { $_ -ne $Name }); Save-Enabled $en
        Remove-Item $packPath -Recurse -Force
        $result.detail = "Removed: $Name"
    }
    default { $result.status="ERROR"; $result.detail="Unknown action. Use list|validate|create-template|enable|disable|remove" }
}

if ($Json) { $result | ConvertTo-Json -Depth 4 }
else { Write-Output "Skill Pack Manager: $Action — $($result.status): $($result.detail)"; if ($result.packs) { $result.packs | ForEach-Object { $icon = if($_.enabled){'[ON]'}else{'[OFF]'}; Write-Output "  $icon $($_.name) v$($_.version)" } } if ($result.details) { $result.details | ForEach-Object { Write-Output "  $($_.name): valid=$($_.valid)" } } }
