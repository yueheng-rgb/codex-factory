# Runtime Risk Classifier v2.0.0
# Part of: FACTORY-R2.13 / R4.1
# Context-aware classification with content-site downgrade and smarter L_CLASS.
# Preserves all R2.13/R2.14/R3.1 rules. Adds v2 context-aware logic.

function Invoke-RuntimeRiskClassifier {
    param(
        [Parameter(Mandatory=$true)][string]$TaskDescription,
        [string[]]$ChangedFiles = @(),
        [string]$ProjectType = "",
        [string]$SurfacePlanId = "",
        [string]$ProfileId = ""
    )

    if (-not $ProfileId) { $ProfileId = "RRP-$(Get-Date -Format 'yyyyMMddHHmmss')" }

    $desc = $TaskDescription.ToLower()
    $riskScore = 0
    $reasons = @()
    $criticalFields = @()
    $requiredReviewers = @()
    $requiredTests = @()
    $blockers = @()
    $verifierReqs = @()
    $invariants = @()
    $affectedSurfaces = @()

    # =============================================
    # v2: Content-site detection (runs first)
    # =============================================
    $isContentSite = $false
    if ($desc -match '(?i)\b(landing.page|content.site|marketing.page|static.page|documentation.site|public.read.only|blog|brochure|portfolio|readme.only|docs.only)\b') {
        $isContentSite = $true
        $reasons += "CONTENT_SITE: Static/content site detected"
    }
    if ($isContentSite) {
        if ($desc -match '(?i)\b(form|login|auth|payment|upload|database.write|user.generated|comment|registration|checkout)\b') {
            $isContentSite = $false
            $reasons += "CONTENT_SITE_UPGRADE: User interaction detected"
        }
    }

    # =============================================
    # v2: L_CLASS patterns — context-aware
    # =============================================
    $isLClass = $false

    # Count surfaces
    $detectedSurfaceCount = 0
    if ($desc -match '(?i)\b(api|backend|REST|endpoint|service)\b') { $detectedSurfaceCount++ }
    if ($desc -match '(?i)\b(admin|dashboard|panel|management)\b') { $detectedSurfaceCount++ }
    if ($desc -match '(?i)\b(database|store|persist|repository)\b') { $detectedSurfaceCount++ }
    if ($desc -match '(?i)\b(frontend|web.app|ui|page|site|portal)\b') { $detectedSurfaceCount++ }
    if ($desc -match '(?i)\b(threejs|3[dD]|scene|canvas|interactive)\b') { $detectedSurfaceCount++ }
    if ($desc -match '(?i)\b(miniapp|mini.program|wechat)\b') { $detectedSurfaceCount++ }
    if ($desc -match '(?i)\b(mobile.app|mobile|ios|android)\b') { $detectedSurfaceCount++ }
    if ($desc -match '(?i)\b(background|worker|queue|job|cron|async)\b') { $detectedSurfaceCount++ }

    $hasCriticalFieldInDesc = ($desc -match '(?i)\b(price|payment|order|inventory|permission|auth|role|transaction|multi.tenant)\b')
    $hasComplexLanguage = ($desc -match '(?i)\b(complex|large.scale|million.user|production.grade|multi.platform|platform|distributed|microservice)\b')
    $hasMiniappCombo = ($desc -match '(?i)(miniapp|mini.program|wechat).*(admin|backend|api|dashboard)')

    if ($hasMiniappCombo) {
        $isLClass = $true
        $reasons += "L_CLASS: Miniapp + admin/API multi-surface platform"
        $riskScore += 100
    } elseif (($detectedSurfaceCount -ge 4) -or $hasComplexLanguage -or ($detectedSurfaceCount -ge 3 -and $hasCriticalFieldInDesc)) {
        $isLClass = $true
        $reasons += "L_CLASS: $detectedSurfaceCount surfaces + critical fields or complex architecture"
        $riskScore += 100
    }

        # =============================================
    # v2: 3+ surfaces without critical fields = at least HIGH
    # =============================================
    if (-not $isLClass -and $detectedSurfaceCount -ge 3) {
        $riskScore += 10
        $reasons += "MULTI_SURFACE: $detectedSurfaceCount surfaces detected — baseline HIGH complexity"
    }
# =============================================
    # CRITICAL patterns (unchanged from R2.13)
    # =============================================
    $isCritical = $false
    if ($desc -match '(?i)\b(price|amount|fee|charge|discount)\b') {
        $isCritical = $true; $reasons += "CRITICAL: Price/amount modification"
        $criticalFields += "price"; $invariants += "price_non_negative"; $riskScore += 25
    }
    if ($desc -match '(?i)\b(inventory|stock|quantity|in.stock)\b') {
        $isCritical = $true; $reasons += "CRITICAL: Inventory modification"
        $criticalFields += "inventory"; $invariants += "inventory_non_negative"; $riskScore += 25
    }
    if ($desc -match '(?i)\b(order|purchase|transaction|checkout|cart)\b') {
        $isCritical = $true; $reasons += "CRITICAL: Order/transaction logic"
        $criticalFields += "order"; $invariants += "order_total_matches_items"; $riskScore += 25
    }
    if ($desc -match '(?i)\b(payment|refund|charge|wallet|balance)\b') {
        $isCritical = $true; $reasons += "CRITICAL: Payment processing"
        $criticalFields += "payment"; $invariants += "payment_idempotency_required"; $riskScore += 25
    }
    if ($desc -match '(?i)\b(delete|destroy|remove.permanent|permanent.delete)\b') {
        $isCritical = $true; $reasons += "CRITICAL: Destructive operation"
        $criticalFields += "destructive"; $invariants += "destructive_action_requires_confirmation"; $riskScore += 25
    }
    if ($desc -match '(?i)(permission.bypass|escalat|role.change|admin.grant)') {
        $isCritical = $true; $reasons += "CRITICAL: Permission bypass risk"
        $criticalFields += "auth"; $riskScore += 25
    }
    if ($desc -match '(?i)\b(data.consistency|race.condition|atomic|transaction.critical)\b') {
        $isCritical = $true; $reasons += "CRITICAL: Data consistency risk"
        $criticalFields += "data"; $riskScore += 25
    }
    if ($desc -match '(?i)\b(password|secret|api.key|token.generat|credential)\b') {
        $isCritical = $true; $reasons += "CRITICAL: Credential/secret handling"
        $criticalFields += "secret"; $riskScore += 25
    }

    # =============================================
    # HIGH patterns (unchanged from R2.13)
    # =============================================
    if ($desc -match '(?i)\b(auth|login|authentication|jwt|token|session|oauth)\b') {
        $reasons += "HIGH: Authentication change"; $riskScore += 10
    }
    if ($desc -match '(?i)\b(permission|rback|access.control|role|admin.only)\b') {
        $reasons += "HIGH: Permission/access control change"; $riskScore += 10
    }
    if ($desc -match '(?i)\b(file.upload|upload.file|multipart|file.process)\b') {
        $reasons += "HIGH: File upload handling"; $riskScore += 10
    }
    if ($desc -match '(?i)\b(database.write|insert|update.record|patch.status|status.transition|lifecycle)\b') {
        $reasons += "HIGH: Database write or state transition"; $riskScore += 10
    }
    if ($desc -match '(?i)\b(validation|schema.change|schema.modif|contract.change|api.contract)\b') {
        $reasons += "HIGH: Schema/contract change"; $riskScore += 10
    }
    if ($desc -match '(?i)\b(error.handling|exception.flow|edge.case)\b') {
        $reasons += "HIGH: Error handling change"; $riskScore += 10
    }

    # =============================================
    # PERFORMANCE / CONCURRENCY patterns (R3.1)
    # =============================================
    $isPerfClaim = $false
    if ($desc -match '(?i)\b(performance|load.test|loadtest|stress.test|benchmark|throughput|QPS|TPS|RPS|concurrency|high.traffic|high.load|high.volume)\b' -or
        $desc -match '(?i)\b(100w|百万|千万|亿级|万级.QPS|10w|10万|百万并发|千万并发|高并发|性能测试|压测|吞吐量|性能要求)\b') {
        $isPerfClaim = $true
        $reasons += "PERFORMANCE: Load/concurrency claim detected"; $riskScore += 12
    }
    if ($desc -match '(?i)(100w|一百万|百万用户|million.user|100万|extreme.scale|massive.concurrent)\b') {
        $isPerfClaim = $true; $isCritical = $true
        $reasons += "PERFORMANCE_CRITICAL: Extreme scale claim (100w+) requires architecture review + load test + human audit"
        $criticalFields += "performance"; $riskScore += 30
    }

    # =============================================
    # MEDIUM patterns (unchanged)
    # =============================================
    if (-not $isContentSite) {
        if ($desc -match '(?i)\b(crud|create|read|update|list|pagination|search|filter)\b') {
            $reasons += "MEDIUM: CRUD operation"; $riskScore += 3
        }
        if ($desc -match '(?i)\b(api.endpoint|route|controller|handler|service.layer)\b') {
            $reasons += "MEDIUM: API/route change"; $riskScore += 3
        }
        if ($desc -match '(?i)\b(component|page|layout|form|table)\b') {
            $reasons += "MEDIUM: UI component change"; $riskScore += 3
        }
        if ($desc -match '(?i)\b(test|spec|test.case|coverage)\b') {
            $reasons += "MEDIUM: Test change"; $riskScore += 3
        }
    }

    # =============================================
    # LOW patterns (unchanged)
    # =============================================
    if ($desc -match '(?i)\b(readme|document|comment|typo|wording|format|style|css|color|font|spacing)\b') {
        $reasons += "LOW: Documentation/style change"
    }

    # =============================================
    # v2: Risk level determination
    # =============================================
    $riskLevel = if ($isLClass) { "L_CLASS" }
                 elseif ($isContentSite) { "LOW" }
                 elseif ($isCritical) { "CRITICAL" }
                 elseif ($riskScore -ge 10) { "HIGH" }
                 elseif ($riskScore -ge 1) { "MEDIUM" }
                 else { "LOW" }

    # =============================================
    # Required reviewers (unchanged + R3.1 perf)
    # =============================================
    switch ($riskLevel) {
        "L_CLASS"   { $requiredReviewers = @("architect", "security", "verifier", "human"); $blockers += "Requires decomposition plan"; $blockers += "Requires surface plan approval" }
        "CRITICAL"  { $requiredReviewers = @("security", "verifier", "human"); $blockers += "Requires business invariant spec"; $blockers += "Requires invariant test coverage" }
        "HIGH"      { $requiredReviewers = @("verifier"); $blockers += "Requires targeted test coverage" }
        "MEDIUM"    { $requiredReviewers = @() }
        "LOW"       { $requiredReviewers = @() }
    }
    if ($isPerfClaim) { $requiredReviewers += "perf"; $requiredTests += "load-test" }

    # =============================================
    # Required tests (unchanged + R3.1 perf)
    # =============================================
    switch ($riskLevel) {
        "L_CLASS"   { $requiredTests = @("integration-tests", "multi-surface-smoke", "security-audit", "invariant-tests") }
        "CRITICAL"  { $requiredTests = @("unit-tests", "invariant-tests", "security-review", "edge-case-tests") }
        "HIGH"      { $requiredTests = @("unit-tests", "edge-case-tests") }
        "MEDIUM"    { $requiredTests = @("unit-tests") }
        "LOW"       { $requiredTests = @() }
    }

    # =============================================
    # Human audit / verifier (unchanged)
    # =============================================
    $humanAudit = $riskLevel -in @("L_CLASS", "CRITICAL")
    $humanAuditReason = if ($humanAudit) { $reasons -join "; " } else { "" }
    if ($riskLevel -in @("L_CLASS", "CRITICAL")) {
        $verifierReqs = @("hash-lock-required", "evidence-pack-required", "invariant-coverage-report")
    } elseif ($riskLevel -eq "HIGH") {
        $verifierReqs = @("test-results-required")
    }

    # =============================================
    # Affected surfaces (unchanged)
    # =============================================
    foreach ($f in $ChangedFiles) {
        if ($f -match 'testbed|tests|test') { $affectedSurfaces += "test-infrastructure" }
        elseif ($f -match 'starter') { $affectedSurfaces += "starter-layer" }
        elseif ($f -match 'runtime|governance|schemas') { $affectedSurfaces += "factory-core" }
        elseif ($f -match 'outputs') { $affectedSurfaces += "documentation" }
    }
    if ($affectedSurfaces.Count -eq 0) { $affectedSurfaces = @("unknown") }
    $affectedSurfaces = $affectedSurfaces | Select-Object -Unique

    # =============================================
    # Invariants (unchanged + R3.1 perf)
    # =============================================
    if ($desc -match '(?i)\b(status|state|transition|lifecycle)\b') { $invariants += "status_transition_allowed" }
    if ($desc -match '(?i)\b(archive|archived|deprecated|inactive|discontinued)\b') { $invariants += "archived_entity_not_mutable" }
    if ($desc -match '(?i)\b(user|role|protect|immutable|field.protect)\b') { $invariants += "user_cannot_modify_protected_fields" }
    $invariants = $invariants | Select-Object -Unique
    if ($isPerfClaim) { $invariants += "load_test_evidence_required"; $invariants += "performance_claim_must_be_verified" }

    # =============================================
    # Output
    # =============================================
    return [PSCustomObject]@{
        profileId = $ProfileId
        taskDescription = $TaskDescription
        projectType = $ProjectType
        surfacePlanId = $SurfacePlanId
        riskLevel = $riskLevel
        riskScore = $riskScore
        riskReasons = $reasons
        affectedSurfaces = @($affectedSurfaces)
        criticalFields = $criticalFields | Select-Object -Unique
        requiredReviewers = $requiredReviewers
        requiredTests = $requiredTests
        humanAuditRequired = $humanAudit
        humanAuditReason = $humanAuditReason
        implementationBlockers = $blockers
        verifierRequirements = $verifierReqs
        invariantsSuggested = @($invariants)
        enforcementStatus = "PENDING"
        blockedReason = ""
        detectedSurfaceCount = $detectedSurfaceCount
        isContentSite = $isContentSite
        createdAt = (Get-Date -Format "yyyy-MM-ddTHH:mm:sszzz")
    }
}
