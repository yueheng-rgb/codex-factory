# Codex Factory V4.0 — Project Onboarding Wizard
# Usage: powershell -File runtime/project-onboarding-wizard.ps1 [-ProjectName <name>] [-Quick]

param([string]$ProjectName, [switch]$Quick, [switch]$Json)

$result = @{
    wizard_version = "4.0.0"
    timestamp = (Get-Date -Format "o")
    project = @{}
    recommendations = @{}
}

if (-not $ProjectName) { $ProjectName = Read-Host "Project name" }
$result.project.name = $ProjectName

$projectTypes = @(
    @{id="backend-api"; label="Backend API (REST/GraphQL)"},
    @{id="admin-system"; label="Admin Dashboard / Management System"},
    @{id="ecommerce"; label="E-commerce Platform"},
    @{id="miniapp"; label="Mini Program (WeChat/Alipay)"},
    @{id="saas"; label="SaaS / Multi-tenant Application"},
    @{id="game-threejs"; label="Game (Three.js / WebGL)"},
    @{id="cpp-tool"; label="C++ Tool / Library"},
    @{id="custom-complex-project"; label="Custom Complex Project"}
)

if (-not $Quick) {
    Write-Output "=== Codex Factory Project Onboarding ==="
    Write-Output ""
    Write-Output "Project: $ProjectName"
    Write-Output ""
    Write-Output "── Project Type ──"
    for ($i=0; $i -lt $projectTypes.Count; $i++) { Write-Output "  [$($i+1)] $($projectTypes[$i].label)" }
    $typeChoice = Read-Host "Select type (1-$($projectTypes.Count))"
    $idx = [int]$typeChoice - 1
    if ($idx -ge 0 -and $idx -lt $projectTypes.Count) {
        $result.project.type = $projectTypes[$idx].id
    } else { $result.project.type = "custom-complex-project" }
} else {
    $result.project.type = "custom-complex-project"
}

# Recommendations based on type
switch ($result.project.type) {
    "backend-api" {
        $result.recommendations = @{
            skill_packs = @("backend-api-design", "auth-permission-security", "database-schema-design")
            search = "optional"
            ci = "recommended"
            evidence_requirements = @("api-contract-test", "regression-test", "secret-scan")
        }
    }
    "admin-system" {
        $result.recommendations = @{
            skill_packs = @("admin-system", "auth-permission-security", "frontend-ui-system")
            search = "optional"
            ci = "recommended"
            evidence_requirements = @("ui-component-test", "permission-matrix-verify", "crud-regression")
        }
    }
    "ecommerce" {
        $result.recommendations = @{
            skill_packs = @("ecommerce", "auth-permission-security", "database-schema-design", "frontend-ui-system")
            search = "recommended"
            ci = "required"
            evidence_requirements = @("checkout-flow-test", "inventory-consistency", "payment-mock-test", "secret-scan")
        }
    }
    "saas" {
        $result.recommendations = @{
            skill_packs = @("saas", "auth-permission-security", "database-schema-design", "frontend-ui-system")
            search = "optional"
            ci = "required"
            evidence_requirements = @("tenant-isolation-test", "billing-mock-test", "multi-tenant-regression")
        }
    }
    default {
        $result.recommendations = @{
            skill_packs = @()
            search = "optional"
            ci = "recommended"
            evidence_requirements = @("basic-smoke-test")
        }
    }
}

$result.project.onboarded_at = (Get-Date -Format "o")

# Write output files
$outDir = "knowledge/packs/$ProjectName"
New-Item -ItemType Directory -Force -Path $outDir | Out-Null
$result | ConvertTo-Json -Depth 4 | Out-File -FilePath "$outDir/project.factory.json" -Encoding utf8 -NoNewline

Write-Output ""
Write-Output "=== Onboarding Complete ==="
Write-Output "Project: $ProjectName"
Write-Output "Type: $($result.project.type)"
Write-Output "Recommended Skill Packs: $($result.recommendations.skill_packs -join ', ')"
Write-Output "Search: $($result.recommendations.search)"
Write-Output "CI: $($result.recommendations.ci)"
Write-Output ""
Write-Output "Plan saved to: $outDir/project.factory.json"
Write-Output ""
Write-Output "Next steps:"
Write-Output "  1. Review recommendations above"
Write-Output "  2. Install recommended skill packs: powershell -File runtime/skill-pack-manager.ps1 -Action create -Name <pack>"
Write-Output "  3. Add project knowledge: powershell -File runtime/knowledge-pack-manager.ps1 -Action add -Name $ProjectName -Source <docs-folder>"
Write-Output "  4. Start building with Codex!"
