# Need Search Detector
# Part of: FACTORY-R2.3-O
# Determines whether a task context requires external search (need_search=true/false)
# Integrates with Evidence Pack sufficiency check

function Test-NeedSearch {
    param(
        [Parameter(Mandatory=$true)][string]$TaskDescription,
        [string]$ProjectType = "fullstack-admin",
        [string]$PhaseId = "implementation",
        [string]$ExistingEvidencePackId = "",
        [hashtable]$Context = @{}
    )

    $score = 0
    $reasons = @()
    $nonReasons = @()

    # === TRIGGER CHECKS (add score) ===

    # T1: Framework/library/API/CLI/config reference
    $fwPatterns = @('next\.?js','react','vue','angular','svelte','express','fastify','django','flask','spring','laravel',
        'prisma','drizzle','typeorm','sequelize','tailwind','chakra','mui','shadcn','vitest','jest','playwright',
        'webpack','vite','turbopack','eslint','prettier','docker','kubernetes','nginx','redis','postgres','mysql',
        'API\b','CLI\b','SDK','config','\.env','\.toml','\.yaml','\.yml','\.json config')
    foreach ($pat in $fwPatterns) {
        if ($TaskDescription -match $pat) { $score += 2; $reasons += "framework_ref:$pat"; break }
    }

    # T2: Version / latest / release notes
    if ($TaskDescription -match '(?i)(version|latest|release.note|upgrade|migrate|v\d+\.\d+|@latest|@\d+)') {
        $score += 2; $reasons += "version_ref"
    }

    # T3: External platform (WeChat, payment, maps, cloud, object storage)
    if ($TaskDescription -match '(?i)(微信|wechat|支付|payment|支付宝|alipay|地图|map|高德|amap|云|cloud|oss|s3|对象存储|object.storage|短信|sms|推送|push)') {
        $score += 3; $reasons += "external_platform"
    }

    # T4: Build/test/lint failure from external dep
    if ($TaskDescription -match '(?i)(build.fail|test.fail|lint.error|compile.error|dependency.conflict|peer.dependency|module.not.found|import.error)') {
        $score += 3; $reasons += "build_test_failure"
    }

    # T5: New dependency introduction
    if ($TaskDescription -match '(?i)(install|add.dependency|引入|添加依赖|npm.install|yarn.add|pnpm.add|new.package)') {
        $score += 2; $reasons += "new_dependency"
    }

    # T6: Evidence Pack insufficient
    if ($ExistingEvidencePackId -and $ExistingEvidencePackId.Length -gt 0) {
        # If evidence pack exists but is stale or low quality
        if ($Context.ContainsKey("evidenceQuality") -and $Context["evidenceQuality"] -in @("needs_review","reject")) {
            $score += 2; $reasons += "evidence_insufficient"
        }
    } elseif ($TaskDescription -match '(?i)(不确定|not.sure|unknown|需要查|need.to.check|verify|confirm)') {
        $score += 1; $reasons += "uncertainty_expressed"
    }

    # T7: Conflicting sources
    if ($TaskDescription -match '(?i)(conflict|冲突|contradict|不一致|disagree|versus|vs\.)') {
        $score += 2; $reasons += "conflicting_info"
    }

    # T8: Security/CVE/dependency upgrade
    if ($TaskDescription -match '(?i)(CVE|security|vulnerability|漏洞|安全|patch|upgrade|update.dep)') {
        $score += 3; $reasons += "security_concern"
    }

    # T9: User requests latest
    if ($TaskDescription -match '(?i)(最新|latest|newest|most.recent|up.to.date)') {
        $score += 2; $reasons += "user_wants_latest"
    }

    # T10: Low confidence in external facts
    if ($TaskDescription -match '(?i)(可能|maybe|perhaps|大概|也许|should.be|might.be|I.think)') {
        $score += 1; $reasons += "low_confidence"
    }

    # === NON-TRIGGER CHECKS (reduce score) ===

    # N1: Pure internal logic
    if ($TaskDescription -match '(?i)(refactor|重构|rename|重命名|move.file|extract.function|internal.only)') {
        $score -= 2; $nonReasons += "internal_only"
    }

    # N2: User provided complete docs
    if ($TaskDescription -match '(?i)(根据文档|per.documentation|as.per.docs|following.the.spec|按需求文档)') {
        $score -= 3; $nonReasons += "docs_provided"
    }

    # N3: Simple refactor
    if ($TaskDescription -match '(?i)(simple.refactor|简单重构|rename.variable|extract.method)') {
        $score -= 2; $nonReasons += "simple_refactor"
    }

    # N4: Style only
    if ($TaskDescription -match '(?i)(style.only|format.only|CSS.only|color.change|font.change|padding|margin)') {
        $score -= 2; $nonReasons += "style_only"
    }

    # N5: Evidence pack sufficient
    if ($ExistingEvidencePackId -and $Context.ContainsKey("evidenceQuality") -and $Context["evidenceQuality"] -in @("high_quality","acceptable")) {
        $score -= 3; $nonReasons += "evidence_sufficient"
    }

    # Decision
    $needSearch = $score -ge 2
    $confidence = if ($score -ge 5) { "high" } elseif ($score -ge 3) { "medium" } elseif ($score -ge 1) { "low" } else { "very_low" }

    # Determine which trigger type
    $triggerType = "none"
    if ($needSearch) {
        if ($reasons -contains "build_test_failure") { $triggerType = "error_driven_search" }
        elseif ($reasons -contains "version_ref") { $triggerType = "version_uncertainty_search" }
        elseif ($reasons -contains "new_dependency") { $triggerType = "dependency_introduction_search" }
        elseif ($reasons -contains "conflicting_info") { $triggerType = "conflicting_sources_search" }
        elseif ($reasons -contains "evidence_insufficient") { $triggerType = "verification_failure_search" }
        else { $triggerType = "initial_search" }
    }

    return [PSCustomObject]@{
        needSearch = $needSearch
        score = $score
        confidence = $confidence
        triggerType = $triggerType
        triggerReasons = $reasons
        nonTriggerReasons = $nonReasons
        recommendedMode = "dry_run"
        maxRoundsRecommended = if ($score -ge 5) { 5 } elseif ($score -ge 3) { 3 } else { 2 }
        checkedAt = Get-Date -Format "yyyy-MM-ddTHH:mm:sszzz"
    }
}

Write-Verbose "Need Search Detector loaded."
