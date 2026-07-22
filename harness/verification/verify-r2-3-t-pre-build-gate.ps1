# R2.3-T Pre-Build Research Gate Verification
# Part of: FACTORY-R2.3-T
# Tests: P0 enforcement, P2 no-force, Implementer block, example classifications

param(
    [string]$ResultsFile = (Join-Path $PSScriptRoot "..\..\outputs\FACTORY_R2_3_T_GATE_VERIFICATION_RESULTS.json")
)

. (Join-Path $PSScriptRoot "..\..\runtime\pre-build-research-gate.ps1")

$results = [System.Collections.ArrayList]::new()
$pass = 0; $fail = 0

function Assert-GateLevel {
    param($TaskDescription, $ExpectedLevel, $TestName, $ExtraContext = @{}, $AgentId = "RSRC-001")
    $gate = Invoke-PreBuildResearchGate -TaskDescription $TaskDescription -AgentId $AgentId -Context $ExtraContext
    $ok = ($gate.search_level -eq $ExpectedLevel)
    $evidenceBoundLevel = $ExpectedLevel -in @("P0_MUST_SEARCH", "P1_SHOULD_SEARCH")
    $gateSemanticsOk = if ($evidenceBoundLevel) {
        $gate.gate_passed -eq $false -and $gate.evidence_pack_required -eq $true -and $gate.fatal_violations -contains "EVIDENCE_PACK_REQUIRED"
    } else {
        $gate.gate_passed -eq $true
    }
    $result = if ($ok -and $gateSemanticsOk) { "PASS"; $script:pass++ } else { "FAIL"; $script:fail++ }
    $r = [PSCustomObject]@{test=$TestName;result=$result;expected_level=$ExpectedLevel;actual_level=$gate.search_level;gate_passed=$gate.gate_passed;gate_semantics_ok=$gateSemanticsOk;reason=$gate.reason;search_required=$gate.search_required;ep_required=$gate.evidence_pack_required}
    [void]$script:results.Add($r)
    Write-Output "[$result] $TestName"
    Write-Output "       expected=$ExpectedLevel actual=$($gate.search_level) search_required=$($gate.search_required) ep=$($gate.evidence_pack_required)"
    if (-not $ok) { Write-Output "       FAIL: expected $ExpectedLevel but got $($gate.search_level)" }
    if (-not $gateSemanticsOk) { Write-Output "       FAIL-CLOSED SEMANTICS MISMATCH: gate_passed=$($gate.gate_passed) fatal=$($gate.fatal_violations -join ', ')" }
    return $r
}

Write-Output "============================================"
Write-Output "R2.3-T PRE-BUILD RESEARCH GATE VERIFICATION"
Write-Output "============================================"
Write-Output ""

# === P0_MUST_SEARCH tests ===
Write-Output "--- P0_MUST_SEARCH ---"
Assert-GateLevel "Build a full-stack ecommerce platform with React, Node.js, PostgreSQL, including payment integration and admin dashboard" "P0_MUST_SEARCH" "P0-01: New project — full-stack ecommerce"
Assert-GateLevel "Design the database schema for a multi-tenant SaaS platform with sharding and Redis caching" "P0_MUST_SEARCH" "P0-02: Database design + scalability"
Assert-GateLevel "Integrate Stripe payment gateway with webhook handling and idempotency" "P0_MUST_SEARCH" "P0-03: Third-party API integration"
Assert-GateLevel "Choose between PostgreSQL and MongoDB for a social media app — need to know what the mainstream approach is" "P0_MUST_SEARCH" "P0-04: Tech stack selection with user asking mainstream"
Assert-GateLevel "Upgrade Next.js from 13 to 15 — there may be breaking changes in the app router and middleware" "P0_MUST_SEARCH" "P0-05: Major dependency upgrade"
Assert-GateLevel "Implement JWT authentication with refresh tokens and role-based access control" "P0_MUST_SEARCH" "P0-06: Security + auth critical feature"
Assert-GateLevel "Not sure if this architecture will scale — maybe we need microservices but I'm uncertain" "P0_MUST_SEARCH" "P0-07: Codex uncertainty + architecture risk"

# === P1_SHOULD_SEARCH tests ===
Write-Output ""
Write-Output "--- P1_SHOULD_SEARCH ---"
Assert-GateLevel "Add a dark mode toggle — what's the best practice for persisting theme preference?" "P1_SHOULD_SEARCH" "P1-01: UI pattern with best practice question"
Assert-GateLevel "There are several ways to handle form validation — react-hook-form vs formik vs custom" "P1_SHOULD_SEARCH" "P1-02: Multiple implementation routes"
Assert-GateLevel "Add a responsive data table component — is there a well-tested pattern?" "P1_SHOULD_SEARCH" "P1-03: UI component with community reference"

# === P2_NO_SEARCH_REQUIRED tests ===
Write-Output ""
Write-Output "--- P2_NO_SEARCH_REQUIRED ---"
Assert-GateLevel "Fix the bug where the login button doesn't disable during form submission" "P2_NO_SEARCH_REQUIRED" "P2-01: Local bug fix"
Assert-GateLevel "Change the header color to match the new brand guidelines" "P2_NO_SEARCH_REQUIRED" "P2-02: Small style change"
Assert-GateLevel "Add unit tests for the user service validation logic" "P2_NO_SEARCH_REQUIRED" "P2-03: Add tests"
Assert-GateLevel "Rename the getCwd function to getCurrentWorkingDirectory across the codebase" "P2_NO_SEARCH_REQUIRED" "P2-04: Pure refactor/rename"
Assert-GateLevel "Write the README with setup instructions exactly as specified: npm install, npm run dev" "P2_NO_SEARCH_REQUIRED" "P2-05: Documentation task with explicit instructions"

# === P2 → P1 escalation tests ===
Write-Output ""
Write-Output "--- P2→P1 Escalation ---"
Assert-GateLevel "Fix the error — not sure if it's a dependency conflict or a config issue" "P1_SHOULD_SEARCH" "ESC-01: Bug fix with uncertainty → P1"
Assert-GateLevel "Add a date picker component — let's install react-datepicker but I'm not sure if it's the right choice" "P1_SHOULD_SEARCH" "ESC-02: New dependency with uncertainty → P1"

# === Implementer BLOCK tests ===
Write-Output ""
Write-Output "--- Implementer BLOCK ---"
$impResult = Invoke-PreBuildResearchGate -TaskDescription "Build a full-stack app with payment integration" -AgentId "IMPL-FE-001"
$impBlocked = ($impResult.gate_passed -eq $false -and $impResult.fatal_violations -contains "IMPLEMENTER_SEARCH_ATTEMPT")
$impMark = if ($impBlocked) { "PASS"; $pass++ } else { "FAIL"; $fail++ }
[void]$results.Add([PSCustomObject]@{test="IMP-BLOCK: Implementer search attempt";result=$impMark;expected_level="REJECT";actual_level=$impResult.search_level;gate_passed=$impResult.gate_passed;reason=$impResult.reason;search_required=$false;ep_required=$false})
Write-Output "[$impMark] IMP-BLOCK: Implementer search attempt"
Write-Output "       gate_passed=$($impResult.gate_passed) fatal=$($impResult.fatal_violations -join ', ')"

Write-Output ""
Write-Output "============================================"
Write-Output "SUMMARY: $pass PASS / $fail FAIL / $($results.Count) TOTAL"
Write-Output "============================================"

$results | ConvertTo-Json -Depth 4 | Set-Content $ResultsFile -Encoding UTF8
Write-Output "Results: $ResultsFile"

if ($fail -gt 0) { exit 1 } else { exit 0 }
