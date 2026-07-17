# R2.3 Search System — Regression Command Index
# Frozen: 2026-07-11 (R2.3-AB)
# Lists all repeatable verification commands across R2.3 search phases

# =============================================
# CORE VERIFICATION SCRIPTS
# =============================================

CORE_VERIFICATION = @(
    @{
        id = "R2.3-S-REGRESSION"
        script = "runtime/search-result-quality-gate.ps1"
        purpose = "Quality Gate v5: 20 checkpoints, 7 fatal, source_origin enforcement"
        command = "powershell -File runtime/search-result-quality-gate.ps1"
        requires_api_key = False
        phase = "R2.3-S"
    },
    @{
        id = "R2.3-Y-REGRESSION"
        script = "runtime/search-doctrine-regression-tests.ps1"
        purpose = "18 regression tests: P0/P1/P2 classification, source_origin, implementer block, oversearch guardrails"
        command = "powershell -ExecutionPolicy Bypass -File runtime/search-doctrine-regression-tests.ps1"
        requires_api_key = False
        phase = "R2.3-Y"
        last_result = "17/17 PASS (100%)"
    },
    @{
        id = "R2.3-T-GATE"
        script = "runtime/pre-build-research-gate.ps1"
        purpose = "Pre-Build Research Gate v2.0.1: P0/P1/P2 classification with security-critical detection"
        command = "powershell -Command \". '.\runtime\pre-build-research-gate.ps1'; Invoke-PreBuildResearchGate -TaskDescription '<task>' -AgentId 'RSRC-001'\""
        requires_api_key = False
        phase = "R2.3-T/Y"
    },
    @{
        id = "R2.3-V-CANONICAL"
        script = "runtime/zhipuai-structured-search-adapter.ps1"
        purpose = "Canonical /api/paas/v4/web_search invocation with full gate chain"
        command = "powershell -Command \"$env:ZHIPUAI_API_KEY='<key>'; . '.\runtime\zhipuai-structured-search-adapter.ps1'; ...\""
        requires_api_key = True
        phase = "R2.3-V"
    }
)

# =============================================
# SKILL / CAPABILITY VERIFICATION (earlier phases)
# =============================================

SKILL_VERIFICATION = @(
    @{
        id = "R2.3-C"
        script = "harness/verification/verify-r2-3-c-capability-runtime.ps1"
        purpose = "Capability Registry Integrity"
        phase = "R2.3-C"
    },
    @{
        id = "R2.3-D"
        script = "harness/verification/verify-r2-3-d-capability-governance.ps1"
        purpose = "Capability Governance Integration"
        phase = "R2.3-D"
    },
    @{
        id = "R2.3-E"
        script = "harness/verification/verify-r2-3-e-skill-import.ps1"
        purpose = "Skill Import Pipeline"
        phase = "R2.3-E"
    },
    @{
        id = "R2.3-F"
        script = "harness/verification/verify-r2-3-f-skill-content-runtime.ps1"
        purpose = "Skill Content Runtime Verification"
        phase = "R2.3-F"
    },
    @{
        id = "R2.3-G"
        script = "harness/verification/verify-r2-3-g-skill-audit.ps1"
        purpose = "Skill Audit Capability + Trust Pipeline"
        phase = "R2.3-G"
    }
)

# =============================================
# SANDBOX / TOOL VERIFICATION
# =============================================

SANDBOX_VERIFICATION = @(
    @{
        id = "R2.3-J"
        script = "harness/verification/verify-r2-3-j-tool-sandbox.ps1"
        purpose = "MCP / External Tool Sandbox"
        phase = "R2.3-J"
    },
    @{
        id = "R2.3-K"
        script = "harness/verification/verify-r2-3-k-tool-search-trial.ps1"
        purpose = "Sandboxed Tool Trial & Read-only Search Adapter"
        phase = "R2.3-K"
    },
    @{
        id = "R2.3-L"
        script = "harness/verification/verify-r2-3-l-network-sandbox.ps1"
        purpose = "Network Boundary Refinement & Sandbox Lifecycle"
        phase = "R2.3-L"
    },
    @{
        id = "R2.3-M"
        script = "harness/verification/verify-r2-3-m-capability-ecosystem.ps1"
        purpose = "Capability Ecosystem Consistency & Runtime Promotion"
        phase = "R2.3-M"
    }
)

# =============================================
# LIVE DEMO (requires API key)
# =============================================

LIVE_DEMO = @(
    @{
        id = "R2.3-AA-DEMO"
        script = "runtime/tests/r2-3-x-implementation-trial/rate-limit-server.js"
        purpose = "E2E P0 pipeline demo: Fastify rate limiting"
        command = "node runtime/tests/r2-3-x-implementation-trial/rate-limit-server.js"
        requires_api_key = False
        phase = "R2.3-AA"
    }
)

# =============================================
# QUICK SMOKE COMMANDS
# =============================================

QUICK_SMOKE = @(
    "powershell -Command \". '.\runtime\pre-build-research-gate.ps1'; Invoke-PreBuildResearchGate -TaskDescription 'Implement JWT refresh token' -AgentId 'RSRC-001' | Select-Object search_level, security_critical\"",
    "powershell -Command \". '.\runtime\pre-build-research-gate.ps1'; Invoke-PreBuildResearchGate -TaskDescription 'Fix typo in README' -AgentId 'RSRC-001' | Select-Object search_level\"",
    "powershell -Command \". '.\runtime\pre-build-research-gate.ps1'; Invoke-PreBuildResearchGate -TaskDescription 'Search for libraries' -AgentId 'IMPL-001' | Select-Object search_level, fatal_violations\""
)

Write-Output "Regression Command Index created."
Write-Output "Core scripts: 0"
Write-Output "Skill scripts: 0"
Write-Output "Sandbox scripts: 0"
Write-Output "Live demos: 0"
Write-Output "Quick smokes: 0"
