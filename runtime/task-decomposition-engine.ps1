# Codex Factory V4.1 — Task Decomposition Engine
# Usage: powershell -File runtime/task-decomposition-engine.ps1 -Requirement <path> [-OutputDir <dir>] [-Json]

param([Parameter(Mandatory=$true)][string]$Requirement, [string]$OutputDir, [switch]$Json)

$ErrorActionPreference = "SilentlyContinue"
$RepoRoot = (Get-Location).Path

# ── Load requirement ──
$reqText = if (Test-Path $Requirement) { Get-Content $Requirement -Raw } else { $Requirement }
$reqLines = $reqText -split "`n" | Where-Object { $_ -match '\S' }
if ($reqLines.Count -lt 3) { Write-Output "ERROR: Requirement too short"; exit 1 }

# ── Load config ──
$cfg = if (Test-Path factory.config.json) { Get-Content factory.config.json -Raw | ConvertFrom-Json } else { $null }
$searchType = if ($cfg -and $cfg.providers.search.type) { $cfg.providers.search.type } else { "none" }
$llmType = if ($cfg -and $cfg.providers.llm.type) { $cfg.providers.llm.type } else { "openai" }

# ── Load enabled packs ──
$enabledPacks = @()
if (Test-Path packs/enabled-packs.json) { $enabledPacks = (Get-Content packs/enabled-packs.json -Raw | ConvertFrom-Json).enabled }

# ── Load knowledge evidence ──
$kbEvidence = $null
if (Test-Path knowledge/evidence/evidence-pack.json) { $kbEvidence = Get-Content knowledge/evidence/evidence-pack.json -Raw | ConvertFrom-Json }

# ═══════════════════════════════════════════
# 1. PROJECT TYPE DETECTION
# ═══════════════════════════════════════════
$typePatterns = @{
    "ecommerce" = @("cart","order","payment","product catalog","shop","checkout","inventory","store")
    "admin-system" = @("admin","dashboard","manage","CRUD","role-based","permission","record","appointment","prescription")
    "miniapp" = @("wechat","mini.?program","wxml","wxss","wx\\.","alipay")
    "backend-api" = @("REST API","GraphQL","API endpoint","microservice","backend only","headless")
    "saas" = @("multi.?tenant","subscription","billing","tenant isolation","SaaS")
    "game-threejs" = @("game","three\\.js","webgl","3D","canvas","sprite","animation")
    "cpp-tool" = @("C\\+\\+","native","memory","compiler","cmake","makefile")
}
$scores = @{}
foreach ($t in $typePatterns.Keys) { $scores[$t] = 0; foreach ($p in $typePatterns[$t]) { $scores[$t] += ([regex]::Matches($reqText.ToLower(), $p)).Count } }
$best = ($scores.GetEnumerator() | Sort-Object Value -Descending | Select-Object -First 1)
$detectedType = if ($best.Value -gt 0) { $best.Name } else { "custom-complex-project" }
$confidence = if ($best.Value -ge 3) { "high" } elseif ($best.Value -ge 1) { "medium" } else { "low" }
$projectTypeResult = @{
    detected_project_type = $detectedType
    confidence = $confidence
    scores = $scores
    missing_information = if ($confidence -eq "low") { @("NEED_USER_CLARIFICATION: project type unclear from requirement") } else { @() }
}

# ═══════════════════════════════════════════
# 2. RISK CLASSIFICATION
# ═══════════════════════════════════════════
$riskPatterns = @{
    P0 = @("payment","auth","login","password","credential","delete.*data","production deploy","permission","JWT","bcrypt","argon2","secret","token")
    P1 = @("database","schema","migration","concurrent","transaction","file upload","API contract","interface","cross.module","upload")
    P2 = @("business logic","CRUD","workflow","validation","form","search","filter")
    P3 = @("style","CSS","layout","responsive","doc","readme","format","lint")
}
$riskHits = @{P0=0;P1=0;P2=0;P3=0}
foreach ($level in @("P0","P1","P2","P3")) { foreach ($p in $riskPatterns[$level]) { $riskHits[$level] += ([regex]::Matches($reqText.ToLower(), $p)).Count } }
$maxRisk = if ($riskHits.P0 -gt 0) { "P0" } elseif ($riskHits.P1 -gt 0) { "P1" } elseif ($riskHits.P2 -gt 0) { "P2" } else { "P3" }
$riskResult = @{
    risk_level = $maxRisk
    risk_reasons = @(foreach ($l in @("P0","P1","P2","P3")) { if ($riskHits[$l] -gt 0) { "${l}: $($riskHits[$l]) pattern matches" } })
    required_gates = @("snapshot-verify","secret-scan") + (if ($maxRisk -in @("P0","P1")) { @("review-gate","artifact-gate") } else { @() })
    required_artifacts = @("ci-job-receipt","stdout.log") + (if ($maxRisk -eq "P0") { @("permission-matrix-verify") } else { @() })
    human_review_required = ($maxRisk -in @("P0","P1"))
}

# ═══════════════════════════════════════════
# 3. TASK GRAPH
# ═══════════════════════════════════════════
$taskTemplates = @{
    "admin-system" = @(
        @{id="T1";type="requirement_analysis";title="Requirements Analysis";risk="P2";effort="medium"}
        @{id="T2";type="architecture_design";title="System Architecture Design";risk="P1";effort="large"}
        @{id="T3";type="data_model";title="Database Schema Design";risk="P1";effort="medium"}
        @{id="T4";type="api_contract";title="REST API Contract Definition";risk="P1";effort="medium"}
        @{id="T5";type="backend_module";title="Auth & Permission Module";risk="P0";effort="large"}
        @{id="T6";type="backend_module";title="CRUD Service Modules";risk="P2";effort="large"}
        @{id="T7";type="frontend_module";title="Admin Dashboard UI";risk="P2";effort="large"}
        @{id="T8";type="frontend_module";title="Management Pages";risk="P2";effort="large"}
        @{id="T9";type="integration";title="API-Frontend Integration";risk="P1";effort="medium"}
        @{id="T10";type="test";title="Integration & E2E Tests";risk="P1";effort="medium"}
        @{id="T11";type="documentation";title="API Docs & README";risk="P3";effort="small"}
        @{id="T12";type="final_verification";title="Final Snapshot Verification";risk="P1";effort="small"}
    )
    "ecommerce" = @(
        @{id="T1";type="requirement_analysis";title="Requirements Analysis";risk="P2";effort="medium"}
        @{id="T2";type="architecture_design";title="System Architecture Design";risk="P1";effort="large"}
        @{id="T3";type="data_model";title="Database Schema (Products/Orders/Users)";risk="P1";effort="large"}
        @{id="T4";type="api_contract";title="REST API Contracts";risk="P1";effort="medium"}
        @{id="T5";type="backend_module";title="Auth & User Module";risk="P0";effort="large"}
        @{id="T6";type="backend_module";title="Product Catalog & Search";risk="P2";effort="large"}
        @{id="T7";type="backend_module";title="Cart, Order & Payment Module";risk="P0";effort="xlarge"}
        @{id="T8";type="frontend_module";title="Mini Program Pages (WXML/WXSS)";risk="P2";effort="xlarge"}
        @{id="T9";type="integration";title="WeChat Pay Integration (Mock)";risk="P0";effort="large"}
        @{id="T10";type="test";title="API & Integration Tests";risk="P1";effort="medium"}
        @{id="T11";type="documentation";title="API Docs & README";risk="P3";effort="small"}
        @{id="T12";type="final_verification";title="Final Snapshot Verification";risk="P1";effort="small"}
    )
    "miniapp" = @(
        @{id="T1";type="requirement_analysis";title="Mini Program Requirements";risk="P2";effort="small"}
        @{id="T2";type="architecture_design";title="Mini Program Architecture";risk="P1";effort="medium"}
        @{id="T3";type="frontend_module";title="Mini Program Pages & Components";risk="P2";effort="large"}
        @{id="T4";type="api_contract";title="Backend API Contracts";risk="P1";effort="medium"}
        @{id="T5";type="backend_module";title="Backend API Implementation";risk="P1";effort="large"}
        @{id="T6";type="integration";title="Frontend-Backend Integration";risk="P1";effort="medium"}
        @{id="T7";type="test";title="Integration Tests";risk="P1";effort="small"}
        @{id="T8";type="final_verification";title="Final Verification";risk="P1";effort="small"}
    )
    "saas" = @(
        @{id="T1";type="requirement_analysis";title="SaaS Requirements & Tenant Model";risk="P1";effort="large"}
        @{id="T2";type="architecture_design";title="Multi-Tenant Architecture";risk="P0";effort="large"}
        @{id="T3";type="data_model";title="Database Schema (Tenant Isolation)";risk="P0";effort="large"}
        @{id="T4";type="backend_module";title="Auth, Tenant & Subscription";risk="P0";effort="xlarge"}
        @{id="T5";type="backend_module";title="Core Business Logic";risk="P2";effort="large"}
        @{id="T6";type="frontend_module";title="Dashboard & Admin UI";risk="P2";effort="large"}
        @{id="T7";type="test";title="Multi-Tenant Isolation Tests";risk="P0";effort="medium"}
        @{id="T8";type="final_verification";title="Final Verification";risk="P1";effort="small"}
    )
}
$templateKey = if ($taskTemplates.ContainsKey($detectedType)) { $detectedType } else { "admin-system" }
$tasks = $taskTemplates[$templateKey]
$sortMap = @{requirement_analysis=1;architecture_design=2;data_model=3;api_contract=4;backend_module=5;frontend_module=6;integration=7;test=8;documentation=9;final_verification=10}
$tasks = $tasks | Sort-Object { $sortMap[$_.type] }

$nodes = @()
$edges = @()
$prevId = $null
foreach ($t in $tasks) {
    $nodes += @{
        id=$t.id; type=$t.type; title=$t.title; description=$t.title
        risk_level=$t.risk; estimated_effort=$t.effort
        related_skill_packs=@(); related_knowledge_sources=@()
        validation_required=$true
        owner_agent=if($t.type -match 'frontend'){"worker-frontend"}elseif($t.type -match 'backend|api|data'){"worker-backend"}elseif($t.type -match 'test|verification'){"worker-qa"}elseif($t.type -match 'integration'){"integrator"}else{"main-agent"}
        input_artifacts=@(); output_artifacts=@("$($t.id)-output")
    }
    if ($prevId) { $edges += @{from=$prevId; to=$t.id; type="depends_on"} }
    $prevId = $t.id
}
$taskGraph = @{ project_name=(Split-Path $Requirement -Leaf).Replace('.md',''); generated_at=(Get-Date -Format "o"); nodes=$nodes; edges=$edges }

# ═══════════════════════════════════════════
# 4. SKILL PACK MATCHING
# ═══════════════════════════════════════════
$skillMap = @{
    "admin-system" = @("admin-system","auth-permission-security","frontend-ui-system","database-schema-design")
    "ecommerce" = @("ecommerce","auth-permission-security","database-schema-design","frontend-ui-system")
    "miniapp" = @("mobile-miniapp-patterns","auth-permission-security","frontend-ui-system")
    "saas" = @("saas","auth-permission-security","database-schema-design","frontend-ui-system")
    "game-threejs" = @("game-threejs","frontend-ui-system")
    "backend-api" = @("backend-api-design","auth-permission-security","database-schema-design")
    "cpp-tool" = @("cpp-memory-safety")
    "custom-complex-project" = @("product-architecture","auth-permission-security")
}
$recommended = if ($skillMap.ContainsKey($detectedType)) { $skillMap[$detectedType] } else { @("product-architecture") }
$selected = @($recommended | Where-Object { $_ -in $enabledPacks })
$missing = @($recommended | Where-Object { $_ -notin $enabledPacks })
$skillPackResult = @{
    selected_skill_packs = $selected
    why_selected = "Matched by project type: $detectedType"
    unused_enabled_packs = @($enabledPacks | Where-Object { $_ -notin $selected })
    recommended_missing_packs = $missing
}

# ═══════════════════════════════════════════
# 5. KNOWLEDGE REFERENCES
# ═══════════════════════════════════════════
$knowledgeRefs = @()
if ($kbEvidence -and $kbEvidence.entries) {
    foreach ($node in $nodes) {
        $related = @($kbEvidence.entries | Where-Object { 
            $_.evidence_type -in @("spec","documentation") -or $_.source_file -match $node.type
        } | Select-Object -First 2 | ForEach-Object {
            @{ source_file=$_.source_file; source_hash=$_.source_hash; line_or_section_reference="full"; evidence_type=$_.evidence_type }
        })
        if ($related.Count -gt 0) { $knowledgeRefs += @{ task_id=$node.id; references=$related } }
    }
}
$knowledgeResult = if ($knowledgeRefs.Count -gt 0) { @{used=$true; references=$knowledgeRefs} } else { @{used=$false; message="no_knowledge_pack_used"} }

# ═══════════════════════════════════════════
# 6. SEARCH STRATEGY
# ═══════════════════════════════════════════
$needsSearch = ($detectedType -in @("ecommerce","saas","custom-complex-project")) -or ($riskResult.risk_level -in @("P0","P1"))
$searchStrat = @{
    search_required = $needsSearch
    search_provider = $searchType
    search_tasks = if ($needsSearch) { @("research external APIs","verify best practices","check dependency versions") } else { @() }
    expected_evidence_pack = if ($needsSearch) { "search-evidence-pack" } else { "none" }
    missing_search_config = if ($needsSearch -and $searchType -eq "none") { "SEARCH_PROVIDER_NOT_CONFIGURED: search is recommended but provider is none. DeepSeek users may consider glm_zhipu. GPT/Claude users can use native search tools." } else { "none" }
}

# ═══════════════════════════════════════════
# 7. VALIDATION PLAN
# ═══════════════════════════════════════════
$validationPlan = @{
    per_task_validation = @($nodes | ForEach-Object {
        $methods = @("artifact")
        if ($_.type -match 'test|verification') { $methods += "test" }
        if ($_.risk_level -in @("P0","P1")) { $methods += "review" }
        if ($_.type -match 'api_contract|data_model') { $methods += "static_check" }
        @{ task_id=$_.id; methods=$methods; required_evidence=@("$($_.id)-output"); blocking=$true }
    })
    global_gates = @(
        @{gate="snapshot-verifier";status="required";condition="before merge"}
        @{gate="secret-scan";status="required";condition="on every commit"}
        @{gate="ci-artifact-upload";status=if($cfg -and $cfg.providers.ci.type -eq "github_actions"){"required"}else{"skipped"};condition=""}
        @{gate="review-gate";status=if($riskResult.human_review_required){"required"}else{"optional"};condition=""}
    )
    non_claims = @("No artifact = no PASS","Every task has at least one validation method")
}

# ═══════════════════════════════════════════
# 8. WORKER PLAN
# ═══════════════════════════════════════════
$workerTasks = @{}
foreach ($n in $nodes) {
    $agent = $n.owner_agent
    if (-not $workerTasks[$agent]) { $workerTasks[$agent] = @() }
    $workerTasks[$agent] += $n.id
}
$workers = @()
foreach ($agent in $workerTasks.Keys) {
    if ($agent -in @("main-agent","integrator")) { continue }
    $workers += @{
        id=$agent; role=$agent; scope="$($workerTasks[$agent].Count) tasks"
        assigned_tasks=$workerTasks[$agent]
        allowed_files=@("src/$agent/","tests/$agent/")
        forbidden_files=@("src/*/auth*","config/secrets*")
        handoff_requirements=@("stdout.log","artifact receipt")
        completion_criteria=@("all assigned tasks have output artifacts")
    }
}
$workerPlan = @{
    main_agent = @{ role="Project Lead"; responsibilities=@("Final decision","Acceptance","Rejection"); final_decision_authority=$true }
    integrator_agent = @{ role="Integration Lead"; scope="Merge and integrate all worker outputs"; integrates=@($workers.id) }
    workers = $workers
    non_claims = @("Workers cannot write entire repo","Integrator is sole integration point","Main Agent has final decision","Workers must produce handoff artifacts")
}

# ═══════════════════════════════════════════
# 9. AGENT EXECUTION PLAN
# ═══════════════════════════════════════════
$agentPlan = @{
    phase_order = @("requirement_analysis","architecture_design","data_model","api_contract","backend_module","frontend_module","integration","test","documentation","final_verification")
    agent_assignments = $workerTasks
    task_dependencies = @($edges | ForEach-Object { "$($_.from)->$($_.to)" })
    gate_sequence = @("snapshot-verifier","secret-scan") + (if ($riskResult.human_review_required) { @("review-gate") } else { @() })
    evidence_inputs = @("factory.config.json","project.factory.json") + (if ($knowledgeResult.used) { @("knowledge/evidence/evidence-pack.json") } else { @() })
    expected_outputs = @("task_graph.json","worker_plan.json","validation_plan.json","agent_execution_plan.json","ci-job-receipt.json")
    final_acceptance_criteria = @("All tasks have output artifacts","Snapshot verifier 15/15 PASS","Secret scan clean","All review gates passed (if required)")
}

# ═══════════════════════════════════════════
# OUTPUT
# ═══════════════════════════════════════════
$allResults = @{
    engine_version = "4.1.0"
    generated_at = (Get-Date -Format "o")
    requirement_source = $Requirement
    project_type_detection = $projectTypeResult
    risk_classification = $riskResult
    task_graph = $taskGraph
    skill_pack_matching = $skillPackResult
    knowledge_references = $knowledgeResult
    search_strategy = $searchStrat
    validation_plan = $validationPlan
    worker_plan = $workerPlan
    agent_execution_plan = $agentPlan
}

if ($OutputDir) {
    New-Item -ItemType Directory -Force -Path $OutputDir | Out-Null
    $allResults.task_graph | ConvertTo-Json -Depth 5 | Out-File -FilePath "$OutputDir/task_graph.json" -Encoding utf8 -NoNewline
    $allResults.worker_plan | ConvertTo-Json -Depth 5 | Out-File -FilePath "$OutputDir/worker_plan.json" -Encoding utf8 -NoNewline
    $allResults.validation_plan | ConvertTo-Json -Depth 5 | Out-File -FilePath "$OutputDir/validation_plan.json" -Encoding utf8 -NoNewline
    $allResults.risk_classification | ConvertTo-Json -Depth 3 | Out-File -FilePath "$OutputDir/risk_classification.json" -Encoding utf8 -NoNewline
    $allResults.agent_execution_plan | ConvertTo-Json -Depth 5 | Out-File -FilePath "$OutputDir/agent_execution_plan.json" -Encoding utf8 -NoNewline
    $allResults | ConvertTo-Json -Depth 6 | Out-File -FilePath "$OutputDir/engine-full-output.json" -Encoding utf8 -NoNewline
    Write-Output "Output written to: $OutputDir"
}

if ($Json) { $allResults | ConvertTo-Json -Depth 6 }
else {
    Write-Output "=== Task Decomposition Engine V4.1 ==="
    Write-Output "Project Type: $detectedType (confidence: $confidence)"
    Write-Output "Risk Level: $($riskResult.risk_level) | Human Review: $($riskResult.human_review_required)"
    Write-Output "Tasks: $($nodes.Count) | Workers: $($workers.Count)"
    Write-Output "Skill Packs: $($selected.Count) selected / $($missing.Count) recommended-missing"
    Write-Output "Search: $searchType | Needed: $needsSearch | Missing: $($searchStrat.missing_search_config -ne 'none')"
    Write-Output "Knowledge: $(if($knowledgeResult.used){'used'}else{'none'})"
    Write-Output "Validation: $($validationPlan.per_task_validation.Count) task-level + $($validationPlan.global_gates.Count) global gates"
}
