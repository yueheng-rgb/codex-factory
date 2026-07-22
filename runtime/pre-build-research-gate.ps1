# Pre-Build Research Gate v2.1.0
# Part of: FACTORY-R2.8
# R2.6: +API_PATTERN_DESIGN
# R2.8: +USER_INPUT_VALIDATION_DESIGN, regex fixes for space matching
# v2.1: P0/P1 evidence binding, integrity/provenance/freshness checks,
#       bilingual risk detection, and fail-closed gate semantics
# Architecture: need_search -> Pre-Build Research Gate -> Provider Selector -> /web_search -> Quality Gate -> Research Intake -> Evidence Pack -> Agents

. (Join-Path $PSScriptRoot "need-search-detector.ps1")
. (Join-Path $PSScriptRoot "search-operating-doctrine.ps1")

function Get-EvidencePackIntegrityHash {
    param([Parameter(Mandatory=$true)]$EvidencePack)

    $canonicalSources = @()
    foreach ($source in @(@($EvidencePack.sources) | Where-Object { $null -ne $_ })) {
        $canonicalSources += [ordered]@{
            title = [string]$source.title
            url = [string]$source.url
            sourceType = [string]$source.sourceType
            sourceOrigin = [string]$source.sourceOrigin
            authority = [string]$source.authority
            freshness = [string]$source.freshness
            publishedAt = [string]$source.publishedAt
            retrievedAt = [string]$source.retrievedAt
            claimSupported = [string]$source.claimSupported
            evidenceExcerpt = [string]$source.evidenceExcerpt
            uncertainty = [string]$source.uncertainty
        }
    }

    $quality = $EvidencePack.qualityGateStatus
    $canonical = [ordered]@{
        evidenceId = [string]$EvidencePack.evidenceId
        task = [string]$EvidencePack.task
        projectId = [string]$EvidencePack.projectId
        phaseId = [string]$EvidencePack.phaseId
        searchRound = [int]$EvidencePack.searchRound
        queryTime = [string]$EvidencePack.queryTime
        triggerReason = [string]$EvidencePack.triggerReason
        provider = [string]$EvidencePack.provider
        mode = [string]$EvidencePack.mode
        accepted = ($EvidencePack.accepted -eq $true)
        rejectionReason = [string]$EvidencePack.rejectionReason
        sources = $canonicalSources
        sourceCount = [int]$EvidencePack.sourceCount
        qualityGateStatus = [ordered]@{
            passed = ($quality.passed -eq $true)
            score = [int]$quality.score
            verdict = [string]$quality.verdict
            trustRecommendation = [string]$quality.trustRecommendation
            fatalRejections = @(@($quality.fatalRejections) | Where-Object { $null -ne $_ -and [string]$_ -ne "" } | ForEach-Object { [string]$_ })
            warnings = @(@($quality.warnings) | Where-Object { $null -ne $_ -and [string]$_ -ne "" } | ForEach-Object { [string]$_ })
        }
        allowedNextActions = @(@($EvidencePack.allowedNextActions) | Where-Object { $null -ne $_ -and [string]$_ -ne "" } | ForEach-Object { [string]$_ })
        forbiddenUse = @(@($EvidencePack.forbiddenUse) | Where-Object { $null -ne $_ -and [string]$_ -ne "" } | ForEach-Object { [string]$_ })
        usableByAgents = @(@($EvidencePack.usableByAgents) | Where-Object { $null -ne $_ -and [string]$_ -ne "" } | ForEach-Object { [string]$_ })
        notUsableByAgents = @(@($EvidencePack.notUsableByAgents) | Where-Object { $null -ne $_ -and [string]$_ -ne "" } | ForEach-Object { [string]$_ })
        conflictsDetected = ($EvidencePack.conflictsDetected -eq $true)
        deltaFromPreviousRound = [string]$EvidencePack.deltaFromPreviousRound
        roundHistory = @(@($EvidencePack.roundHistory) | Where-Object { $null -ne $_ -and [string]$_ -ne "" } | ForEach-Object { [string]$_ })
        secretPresent = ($EvidencePack.secretPresent -eq $true)
        humanApproval = ($EvidencePack.humanApproval -eq $true)
    }

    $json = $canonical | ConvertTo-Json -Depth 12 -Compress
    $sha = [System.Security.Cryptography.SHA256]::Create()
    try {
        $bytes = [System.Text.Encoding]::UTF8.GetBytes($json)
        return ([System.BitConverter]::ToString($sha.ComputeHash($bytes)) -replace '-', '').ToLowerInvariant()
    }
    finally {
        $sha.Dispose()
    }
}

function Resolve-EvidencePackPath {
    param(
        [Parameter(Mandatory=$true)][string]$EvidencePackIdOrPath,
        [hashtable]$Context = @{}
    )

    $candidates = New-Object System.Collections.Generic.List[string]
    if ($Context.ContainsKey("EvidencePackPath") -and $Context["EvidencePackPath"]) {
        $candidates.Add([string]$Context["EvidencePackPath"])
    }
    $candidates.Add($EvidencePackIdOrPath)

    $searchDirectories = New-Object System.Collections.Generic.List[string]
    if ($Context.ContainsKey("EvidenceDirectory") -and $Context["EvidenceDirectory"]) {
        $searchDirectories.Add([string]$Context["EvidenceDirectory"])
    }
    if ($Context.ContainsKey("ProjectRoot") -and $Context["ProjectRoot"]) {
        $projectRoot = [string]$Context["ProjectRoot"]
        $searchDirectories.Add((Join-Path $projectRoot "knowledge\evidence"))
        $searchDirectories.Add((Join-Path $projectRoot "evidence"))
        $searchDirectories.Add((Join-Path $projectRoot "outputs"))
    }
    $factoryRoot = Split-Path $PSScriptRoot -Parent
    $searchDirectories.Add((Join-Path $factoryRoot "knowledge\evidence"))
    $searchDirectories.Add((Join-Path $factoryRoot "evidence"))
    $searchDirectories.Add((Join-Path $factoryRoot "outputs"))
    $searchDirectories.Add((Get-Location).Path)

    foreach ($directory in @($searchDirectories)) {
        $candidates.Add((Join-Path $directory $EvidencePackIdOrPath))
        if (-not $EvidencePackIdOrPath.EndsWith(".json", [System.StringComparison]::OrdinalIgnoreCase)) {
            $candidates.Add((Join-Path $directory "$EvidencePackIdOrPath.json"))
        }
    }

    foreach ($candidate in @($candidates | Select-Object -Unique)) {
        try {
            if (Test-Path -LiteralPath $candidate -PathType Leaf) {
                return (Resolve-Path -LiteralPath $candidate).Path
            }
        }
        catch { }
    }

    # An ID need not be the filename.  Search only the bounded, documented
    # evidence directories and compare the parsed evidenceId; never recurse the
    # whole project or trust a filename wildcard.
    foreach ($directory in @($searchDirectories | Select-Object -Unique)) {
        if (-not (Test-Path -LiteralPath $directory -PathType Container)) { continue }
        foreach ($file in @(Get-ChildItem -LiteralPath $directory -File -Filter "*.json" -ErrorAction SilentlyContinue)) {
            try {
                $candidatePack = Get-Content -LiteralPath $file.FullName -Raw -ErrorAction Stop | ConvertFrom-Json -ErrorAction Stop
                if ([string]$candidatePack.evidenceId -eq $EvidencePackIdOrPath) { return $file.FullName }
            }
            catch { }
        }
    }
    return $null
}

function Test-EvidencePackForResearchGate {
    param(
        [Parameter(Mandatory=$true)]$EvidencePack,
        [Parameter(Mandatory=$true)][string]$EvidencePackPath,
        [Parameter(Mandatory=$true)][string]$RequestedIdOrPath,
        [Parameter(Mandatory=$true)][string]$TaskDescription,
        [Parameter(Mandatory=$true)][string]$PhaseId,
        [Parameter(Mandatory=$true)][ValidateSet("P0_MUST_SEARCH", "P1_SHOULD_SEARCH")][string]$SearchLevel,
        [hashtable]$Context = @{}
    )

    $errors = @()
    $warnings = @()
    $acceptedVerdicts = @("PASS_CLEAN", "PASS_WITH_WARNINGS", "PASS_WITH_CAVEATS", "high_quality", "acceptable")
    $minimumSources = if ($SearchLevel -eq "P0_MUST_SEARCH") { 5 } else { 2 }
    $minimumOfficial = if ($SearchLevel -eq "P0_MUST_SEARCH") { 1 } else { 0 }
    $maxAgeDays = if ($SearchLevel -eq "P0_MUST_SEARCH") { 30 } else { 90 }
    if ($Context.ContainsKey("EvidenceMaxAgeDays")) {
        $configuredAge = 0
        if ([int]::TryParse([string]$Context["EvidenceMaxAgeDays"], [ref]$configuredAge) -and $configuredAge -gt 0) {
            $maxAgeDays = $configuredAge
        }
    }

    $requestLooksLikePath = (Test-Path -LiteralPath $RequestedIdOrPath -PathType Leaf -ErrorAction SilentlyContinue) -or
                            $RequestedIdOrPath -match '[\\/]' -or
                            $RequestedIdOrPath.EndsWith(".json", [System.StringComparison]::OrdinalIgnoreCase)
    if (-not $EvidencePack.evidenceId) { $errors += "EVIDENCE_ID_MISSING" }
    elseif (-not $requestLooksLikePath -and [string]$EvidencePack.evidenceId -ne $RequestedIdOrPath) {
        $errors += "EVIDENCE_ID_MISMATCH"
    }

    $normalizedExpectedTask = ([regex]::Replace($TaskDescription.Trim(), '\s+', ' '))
    $normalizedPackTask = if ($EvidencePack.task) { [regex]::Replace(([string]$EvidencePack.task).Trim(), '\s+', ' ') } else { "" }
    if (-not $normalizedPackTask) { $errors += "EVIDENCE_TASK_MISSING" }
    elseif ($normalizedPackTask -ine $normalizedExpectedTask) { $errors += "EVIDENCE_TASK_MISMATCH" }

    if (-not $EvidencePack.phaseId) { $errors += "EVIDENCE_PHASE_MISSING" }
    elseif ([string]$EvidencePack.phaseId -ine $PhaseId) { $errors += "EVIDENCE_PHASE_MISMATCH" }

    if ($Context.ContainsKey("ProjectId") -and $Context["ProjectId"] -and
        [string]$EvidencePack.projectId -ine [string]$Context["ProjectId"]) {
        $errors += "EVIDENCE_PROJECT_MISMATCH"
    }

    if ($EvidencePack.accepted -ne $true) { $errors += "EVIDENCE_NOT_ACCEPTED" }
    if (-not $EvidencePack.qualityGateStatus) { $errors += "QUALITY_GATE_STATUS_MISSING" }
    else {
        $qualityVerdict = [string]$EvidencePack.qualityGateStatus.verdict
        if ($EvidencePack.qualityGateStatus.passed -ne $true) { $errors += "QUALITY_GATE_NOT_PASSED" }
        if ($qualityVerdict -notin $acceptedVerdicts) { $errors += "QUALITY_VERDICT_REJECTED:$qualityVerdict" }
        if ($qualityVerdict -in @("FAIL_FATAL", "reject")) { $errors += "QUALITY_VERDICT_FATAL:$qualityVerdict" }
        if (($qualityVerdict -eq "PASS_WITH_CAVEATS" -or [string]$EvidencePack.qualityGateStatus.trustRecommendation -eq "needs_human_review") -and
            (-not $Context.ContainsKey("EvidenceHumanApproved") -or $Context["EvidenceHumanApproved"] -ne $true)) {
            $errors += "EVIDENCE_HUMAN_REVIEW_REQUIRED"
        }
    }

    if ([string]$EvidencePack.mode -notin @("live_api", "live_search")) {
        $errors += "NON_LIVE_EVIDENCE_MODE:$([string]$EvidencePack.mode)"
    }

    $queryTime = [datetimeoffset]::MinValue
    if (-not $EvidencePack.queryTime -or -not [datetimeoffset]::TryParse([string]$EvidencePack.queryTime, [ref]$queryTime)) {
        $errors += "EVIDENCE_QUERY_TIME_INVALID"
    }
    else {
        $age = [datetimeoffset]::Now - $queryTime
        if ($age.TotalDays -gt $maxAgeDays) { $errors += "EVIDENCE_PACK_STALE:$([math]::Floor($age.TotalDays))d" }
        if ($age.TotalHours -lt -24) { $errors += "EVIDENCE_QUERY_TIME_IN_FUTURE" }
    }

    $sources = @($EvidencePack.sources)
    if ($sources.Count -lt $minimumSources) { $errors += "INSUFFICIENT_SOURCES:$($sources.Count)/$minimumSources" }
    $validUrls = @{}
    $freshCount = 0
    $officialCount = 0
    $supportedSourceCount = 0
    foreach ($source in $sources) {
        if (-not $source.title) { $errors += "SOURCE_TITLE_MISSING" }
        if ([string]$source.sourceOrigin -ne "provider_search_result") { $errors += "SOURCE_ORIGIN_NOT_CANONICAL:$([string]$source.url)" }
        if (-not $source.evidenceExcerpt) { $errors += "SOURCE_EVIDENCE_EXCERPT_MISSING:$([string]$source.url)" }
        else { $supportedSourceCount++ }
        $uri = $null
        $validUri = $source.url -and [uri]::TryCreate([string]$source.url, [System.UriKind]::Absolute, [ref]$uri) -and $uri.Scheme -in @("http", "https")
        if (-not $validUri) { $errors += "SOURCE_URL_INVALID:$([string]$source.url)" }
        elseif ($validUrls.ContainsKey($uri.AbsoluteUri)) { $errors += "SOURCE_URL_DUPLICATE:$($uri.AbsoluteUri)" }
        else { $validUrls[$uri.AbsoluteUri] = $true }

        if ([string]$source.sourceType -in @("official_doc", "official_documentation", "official_SDK_repo", "official_example", "release_note")) {
            $officialCount++
        }

        $freshnessLabel = [string]$source.freshness
        $freshnessLabelUsable = $freshnessLabel -in @("current", "recent", "unknown", "")
        if ($freshnessLabel -eq "stale") { $errors += "SOURCE_FRESHNESS_STALE:$([string]$source.url)" }
        elseif (-not $freshnessLabelUsable) { $errors += "SOURCE_FRESHNESS_INVALID:$([string]$source.url)" }
        elseif ($freshnessLabel -in @("unknown", "")) { $warnings += "SOURCE_FRESHNESS_UNKNOWN:$([string]$source.url)" }
        $retrievedAt = [datetimeoffset]::MinValue
        $retrievedAtValid = $source.retrievedAt -and [datetimeoffset]::TryParse([string]$source.retrievedAt, [ref]$retrievedAt)
        $retrievedAtFresh = $false
        if ($retrievedAtValid) {
            $retrievedAge = [datetimeoffset]::Now - $retrievedAt
            $retrievedAtFresh = ($retrievedAge.TotalDays -le $maxAgeDays -and $retrievedAge.TotalHours -ge -24)
            if (-not $retrievedAtFresh) { $errors += "SOURCE_RETRIEVAL_STALE_OR_FUTURE:$([string]$source.url)" }
        }
        else { $errors += "SOURCE_RETRIEVED_AT_INVALID:$([string]$source.url)" }
        if ($freshnessLabelUsable -and $freshnessLabel -ne "stale" -and $retrievedAtFresh) { $freshCount++ }
    }
    if ($officialCount -lt $minimumOfficial) { $errors += "INSUFFICIENT_OFFICIAL_SOURCES:$officialCount/$minimumOfficial" }
    if ($freshCount -lt $minimumSources) { $errors += "INSUFFICIENT_FRESH_SOURCES:$freshCount/$minimumSources" }
    if ($supportedSourceCount -lt $minimumSources) { $errors += "INSUFFICIENT_SUPPORTED_SOURCES:$supportedSourceCount/$minimumSources" }

    if ([string]$EvidencePack.contentHashAlgorithm -ine "SHA256") { $errors += "CONTENT_HASH_ALGORITHM_INVALID" }
    if ([string]$EvidencePack.contentHash -notmatch '^[a-fA-F0-9]{64}$') { $errors += "CONTENT_HASH_MISSING_OR_INVALID" }
    else {
        $computedHash = Get-EvidencePackIntegrityHash -EvidencePack $EvidencePack
        if ($computedHash -ine [string]$EvidencePack.contentHash) { $errors += "CONTENT_HASH_MISMATCH" }
    }

    if ($Context.ContainsKey("EvidencePackFileSha256") -and $Context["EvidencePackFileSha256"]) {
        $actualFileHash = (Get-FileHash -LiteralPath $EvidencePackPath -Algorithm SHA256).Hash
        if ($actualFileHash -ine [string]$Context["EvidencePackFileSha256"]) { $errors += "FILE_HASH_MISMATCH" }
    }

    return [PSCustomObject]@{
        valid = ($errors.Count -eq 0)
        errors = @($errors | Select-Object -Unique)
        warnings = @($warnings | Select-Object -Unique)
        evidenceId = [string]$EvidencePack.evidenceId
        path = $EvidencePackPath
        sourceCount = $sources.Count
        officialSourceCount = $officialCount
        freshSourceCount = $freshCount
        supportedSourceCount = $supportedSourceCount
        maxAgeDays = $maxAgeDays
        contentHashVerified = ($errors -notcontains "CONTENT_HASH_MISSING_OR_INVALID" -and $errors -notcontains "CONTENT_HASH_MISMATCH" -and $errors -notcontains "CONTENT_HASH_ALGORITHM_INVALID")
    }
}

function Invoke-PreBuildResearchGate {
    param(
        [Parameter(Mandatory=$true)][string]$TaskDescription,
        [string]$ProjectType = "fullstack-admin",
        [string]$PhaseId = "implementation",
        [string]$AgentId = "RSRC-001",
        [string]$ExistingEvidencePackId = "",
        [hashtable]$Context = @{}
    )

    $result = [PSCustomObject]@{
        search_level = ""; reason = ""; security_critical = $false
        search_required = $false; skip_justification = ""
        research_questions = @(); query_intents = @(); expected_evidence = @()
        evidence_pack_required = $false; implementer_allowed_to_search = $false
        evidence_pack_bound = $false; evidence_pack_id = ""; evidence_pack_path = ""
        evidence_validation = $null; classification_passed = $true
        budget = @{}; stop_conditions_met = @(); fatal_violations = @(); gate_passed = $true
    }

    # INVARIANT: Implementer block
    if ($AgentId -match "IMPL") {
        $result.search_level = "REJECT"; $result.reason = "IMPLEMENTER_DIRECT_SEARCH_FORBIDDEN"
        $result.gate_passed = $false; $result.fatal_violations += "IMPLEMENTER_SEARCH_ATTEMPT"
        return $result
    }

    # P2 Early Exit: Pure style/text tasks
    if ($TaskDescription -match '(?i)(fix.padding|adjust.margin|CSS.fix|style.fix|formatting.only|font.size.only|typo.fix|wording.fix|copy.update.only|button.style|icon.change|change.color.of|仅.{0,4}(样式|文案|排版|间距|错别字)|修改.{0,4}(颜色|字体|图标|文案)|调整.{0,4}(边距|间距|排版))') {
        $result.search_level = "P2_NO_SEARCH_REQUIRED"; $result.reason = "P2: Pure style/text task"
        return $result
    }

    # Explicitly bounded documentation and local UI-state fixes should not be
    # escalated merely because they contain command names (for example
    # "npm install") or the word "login". Research/latest/architecture cues
    # still bypass these narrow exceptions and continue through classification.
    $explicitDocumentationOnly = (
        $TaskDescription -match '(?i)(README|documentation|docs?|setup.instructions|使用说明|安装说明|文档)' -and
        $TaskDescription -match '(?i)(write|update|edit|wording|exactly.as.specified|explicit.instructions|编写|更新|修改|按.{0,8}(指定|说明))' -and
        $TaskDescription -notmatch '(?i)(latest|current|research|verify|official|architecture|dependency.choice|最新|当前|调研|验证|官方|架构|依赖选型)'
    )
    if ($explicitDocumentationOnly) {
        $result.search_level = "P2_NO_SEARCH_REQUIRED"; $result.reason = "P2: Explicit documentation-only task"
        return $result
    }
    $localSubmissionUiFix = (
        $TaskDescription -match '(?i)(fix|bug|修复).{0,40}(login|sign[. -]?in|form|登录|表单).{0,40}(button|按钮).{0,40}(disable|loading|submission|disabled|禁用|加载|提交中)' -or
        $TaskDescription -match '(?i)(login|sign[. -]?in|form|登录|表单).{0,40}(button|按钮).{0,40}(disable|loading|submission|disabled|禁用|加载|提交中).{0,40}(fix|bug|修复)'
    )
    if ($localSubmissionUiFix) {
        $result.search_level = "P2_NO_SEARCH_REQUIRED"; $result.reason = "P2: Bounded local form UI-state bug"
        return $result
    }

    # Broader P2 check: P2 keywords without P0 action keywords
    $hasP2Keywords = $TaskDescription -match '(?i)(fix.padding|change.color|adjust.margin|CSS.fix|style.fix|formatting|spacing|typo|wording|copy.update|样式|文案|排版|间距|错别字|颜色|字体|图标)'
    $hasP0ActionKeywords = $TaskDescription -match '(?i)(\b(add|implement|design|create|integrate|build|develop|upgrade|migrate|refactor.major|architect|new.module|new.feature)\b|新增|实现|设计|创建|集成|搭建|开发|升级|迁移|重构|架构|新模块|新功能)'
    if ($hasP2Keywords -and -not $hasP0ActionKeywords) {
        $result.search_level = "P2_NO_SEARCH_REQUIRED"; $result.reason = "P2: Style/text task without implementation action"
        return $result
    }

    # Security-Critical Detection
    $securityPatterns = @(
        "login|auth|JWT|refresh.token|session|OAuth|SSO|登录|认证|鉴权|会话|单点登录",
        "RBAC|permission|access.control|角色权限|权限|访问控制|越权",
        "password|credential|secret|API.key|密码|凭据|密钥|令牌",
        "file.upload|multipart|mime.type|文件上传|分片上传|文件类型",
        "CORS|CSRF|XSS|sanitiz|injection|跨域|注入|转义|清洗",
        "rate.limit|throttle|idempot|限流|节流|幂等",
        "logout|revok|invalidat|登出|注销|吊销|失效"
    )
    $securityCritical = $false
    foreach ($pat in $securityPatterns) { if ($TaskDescription -match "(?i)($pat)") { $securityCritical = $true; break } }
    $result.security_critical = $securityCritical

    $p0Score = 0; $p0Reasons = @()
    $p1Score = 0; $p1Reasons = @()

    # P0-1: Security Critical
    if ($securityCritical) { $p0Score += 10; $p0Reasons += "SECURITY_CRITICAL" }

    # P0-2: External Dependency
    if ($TaskDescription -match '(?i)(new.package|new.SDK|integrate|plugin|middleware|library|npm.install|新依赖|外部依赖|第三方|软件包|插件|中间件|安装依赖|接入.{0,12}(SDK|服务|平台))') { $p0Score += 5; $p0Reasons += "EXTERNAL_DEPENDENCY" }

    # P0-3: Architecture Decision
    if ($TaskDescription -match '(?i)(new.project|full[. -]?stack|ecommerce.platform|SaaS.platform|scaffold|architecture|database.schema|tech[. -]?stack|choose.between.{0,60}(database|framework|stack|architecture|storage|queue|PostgreSQL|MongoDB)|database.choice|design|deployment|CI/CD|docker|scalab|新项目|完整项目|全栈|脚手架|架构|选型|技术选型|数据库.{0,6}(模式|结构|设计|选型)|表结构|部署|持续集成|容器化|扩展性|技术栈)') { $p0Score += 4; $p0Reasons += "ARCHITECTURE_DECISION" }

    # P0-4: Uncertainty
    if ($TaskDescription -match '(?i)(UNSURE|not.sure|uncertain|which.way|best.practice|mainstream|recommend|official|standard|不确定|不知道|哪种方案|怎么选|最佳实践|主流|推荐|官方|标准)') { $p0Score += 3; $p0Reasons += "UNCERTAINTY" }

    # P0-5: High Rework Risk
    if ($TaskDescription -match '(?i)(rewrite|rework|wrong.approach|breaking.change|migration|upgrade|重写|返工|错误方案|破坏性变更|迁移|升级)') { $p0Score += 3; $p0Reasons += "HIGH_REWORK_RISK" }

    # P0-6 (R2.6): API_PATTERN_DESIGN
    if ($TaskDescription -match '(?i)(cursor.pagination|offset.pagination|pagina|filter.API|sorting.API|search.query.design|list.endpoint|API.response.metadata|API.contract|database.query.pattern|index.sensitive.query|public.API|reusable.API|游标分页|偏移分页|分页接口|筛选接口|排序接口|搜索参数|列表接口|接口契约|API.{0,4}(设计|契约)|数据库查询模式|公共接口)') {
        $p0Score += 4; $p0Reasons += "API_PATTERN_DESIGN"
    }

    # P0-7 (R2.8): USER_INPUT_VALIDATION_DESIGN
    $inputValidationMatch = $TaskDescription -match '(?i)(input[.\s-]?validation|request[.\s-]?body[.\s-]?validation|required[.\s-]?fields?|type[.\s-]?checking|field[.\s-]?(whitelist|allowlist)|user[.\s-]?(input|controlled)|validation[.\s-]?error|request[.\s-]?sanitiz|boundary[.\s-]?validation|payload[.\s-]?contract|输入校验|请求体校验|必填字段|类型检查|字段白名单|用户输入|校验错误|边界校验|载荷契约)'
    if ($inputValidationMatch) {
        # Exclude minor changes to existing validation
        $minorValidationChangePattern = '(?i)(modify.*(message|text|wording)|change.*(message|text|wording|label)|fix.*bug|simple.*field.only|log.*format|existing.*message.*only|copy.*existing.*pattern|follow.*existing)'
        if ($TaskDescription -notmatch $minorValidationChangePattern) {
            $p0Score += 4; $p0Reasons += "USER_INPUT_VALIDATION_DESIGN"
        }
    }

    # P1: Community Reference
    if ($TaskDescription -match '(?i)(UI.pattern|UX|component|design.system|multiple.approach|several.ways|form.validation|react-hook-form|formik|\bvs\b|community|simpler.way|unfamiliar|界面模式|用户体验|组件方案|设计系统|多种方案|社区方案|更简单的方式|不熟悉)') { $p1Score += 3; $p1Reasons += "COMMUNITY_REFERENCE" }

    # An uncertainty/best-practice cue alone is P1. It becomes P0 when combined
    # with security, dependency, architecture, migration, or another P0 signal.
    if ($p0Score -gt 0 -and $p0Score -lt 4 -and $p0Reasons -contains "UNCERTAINTY") {
        $p1Score += 3; $p1Reasons += "UNCERTAINTY_REFERENCE"
    }

    # UI context override for design system
    if ($TaskDescription -match "(?i)(design.system|button.variant|change.variant|existing.component|change.prop)") {
        if ($p0Score -ge 4 -and ($p0Reasons -contains "ARCHITECTURE_DECISION")) {
            $p0Score -= 4; $p0Reasons = $p0Reasons | Where-Object { $_ -ne "ARCHITECTURE_DECISION" }
        }
    }

    # Decision
    if ($p0Score -ge 4) {
        $result.search_level = "P0_MUST_SEARCH"; $result.search_required = $true
        $result.evidence_pack_required = $true; $result.reason = "P0: $($p0Reasons -join ', ')"
        $result.budget = @{ maxQueries = 6; minSources = 5; maxSources = 10; officialMin = 1 }
        $result.research_questions = @("Official approach?","Best practices?","Common pitfalls?","Version constraints?")
        if ($securityCritical) { $result.research_questions += @("Security controls?","Insecure patterns?") }
        $result.query_intents = @("official_api_check","best_practice","risk_pattern","alternative_options")
        $result.expected_evidence = @("accepted live Evidence Pack", "quality verdict PASS_*", "at least 5 unique fresh sources", "at least 1 official source", "verified SHA256 content hash", "exact task and phase binding")
    }
    elseif ($p1Score -ge 3) {
        $result.search_level = "P1_SHOULD_SEARCH"; $result.search_required = $true
        $result.evidence_pack_required = $true
        $result.reason = "P1: $($p1Reasons -join ', ')"
        $result.budget = @{ maxQueries = 3; minSources = 2; maxSources = 5; officialMin = 0 }
        $result.expected_evidence = @("accepted live Evidence Pack", "quality verdict PASS_*", "at least 2 unique fresh sources", "verified SHA256 content hash", "exact task and phase binding")
    }
    else {
        $result.search_level = "P2_NO_SEARCH_REQUIRED"; $result.search_required = $false
        $result.reason = "P2: Low-risk local change"
    }

    # Classification alone is not a gate pass.  P0/P1 must bind a physically
    # resolvable, parseable and integrity-checked Evidence Pack.
    if ($result.evidence_pack_required) {
        if (-not $ExistingEvidencePackId) {
            $result.fatal_violations += "EVIDENCE_PACK_REQUIRED"
            $result.evidence_validation = [PSCustomObject]@{valid=$false;errors=@("EVIDENCE_PACK_REQUIRED");warnings=@()}
        }
        else {
            $evidencePath = Resolve-EvidencePackPath -EvidencePackIdOrPath $ExistingEvidencePackId -Context $Context
            if (-not $evidencePath) {
                $result.fatal_violations += "EVIDENCE_PACK_NOT_FOUND"
                $result.evidence_validation = [PSCustomObject]@{valid=$false;errors=@("EVIDENCE_PACK_NOT_FOUND");warnings=@()}
            }
            else {
                $result.evidence_pack_path = $evidencePath
                try {
                    $evidencePack = Get-Content -LiteralPath $evidencePath -Raw -ErrorAction Stop | ConvertFrom-Json -ErrorAction Stop
                    $validation = Test-EvidencePackForResearchGate -EvidencePack $evidencePack -EvidencePackPath $evidencePath `
                        -RequestedIdOrPath $ExistingEvidencePackId -TaskDescription $TaskDescription -PhaseId $PhaseId `
                        -SearchLevel $result.search_level -Context $Context
                    $result.evidence_validation = $validation
                    $result.evidence_pack_id = [string]$evidencePack.evidenceId
                    if ($validation.valid) {
                        $result.evidence_pack_bound = $true
                        $result.stop_conditions_met += @("evidence_pack_resolved", "quality_gate_passed", "source_budget_met", "freshness_verified", "content_hash_verified")
                    }
                    else {
                        foreach ($validationError in @($validation.errors)) {
                            $result.fatal_violations += "EVIDENCE_INVALID:$validationError"
                        }
                    }
                }
                catch {
                    $result.fatal_violations += "EVIDENCE_PACK_PARSE_FAILED"
                    $result.evidence_validation = [PSCustomObject]@{valid=$false;errors=@("EVIDENCE_PACK_PARSE_FAILED");warnings=@();detail=$_.Exception.Message}
                }
            }
        }
    }

    $result.gate_passed = ($result.fatal_violations.Count -eq 0 -and (-not $result.evidence_pack_required -or $result.evidence_pack_bound))
    return $result
}

# Security Design Completeness Check
function Test-SecurityDesignCompleteness {
    param($Design, $EvidencePack)
    $missing = @()
    foreach ($f in @("security_controls_to_implement","rejected_insecure_patterns","dependency_version_notes","test_plan_for_security_paths","EP_source_references","implementation_constraints")) {
        if (-not $Design.$f) { $missing += $f }
    }
    [PSCustomObject]@{ complete=($missing.Count -eq 0); missing_fields=$missing; security_design_score=if($missing.Count -eq 0){2}elseif($missing.Count -le 2){1}else{0} }
}

Write-Output "Pre-Build Research Gate v2.1.0 loaded (P0/P1 evidence binding, SHA256 integrity, bilingual risk detection)"


