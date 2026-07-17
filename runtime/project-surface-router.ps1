# Project Surface Router v2.0.0
# Part of: FACTORY-R4.1
# Explicit + implicit surface detection with confidence levels.

function Invoke-ProjectSurfaceRouter {
    param(
        [Parameter(Mandatory=$true)][string]$TaskDescription,
        [string[]]$ExplicitSurfaces = @()
    )

    $desc = $TaskDescription.ToLower()
    $surfaces = @()

    # ============================================
    # EXPLICIT detection (confidence: EXPLICIT)
    # ============================================
    if ($desc -match '(?i)\b(api|backend|REST|endpoint|service|server)\b' -or "api-service" -in $ExplicitSurfaces) {
        $surfaces += [PSCustomObject]@{ surface="api-service"; confidence="EXPLICIT" }
    }
    if ($desc -match '(?i)\b(admin|dashboard|panel|management)\b' -or "admin-web" -in $ExplicitSurfaces) {
        $surfaces += [PSCustomObject]@{ surface="admin-web"; confidence="EXPLICIT" }
    }
    if ($desc -match '(?i)\b(public.web|public.site|content.site|landing|blog|documentation|marketing|static)\b' -or "public-web" -in $ExplicitSurfaces) {
        $surfaces += [PSCustomObject]@{ surface="public-web"; confidence="EXPLICIT" }
    }
    if ($desc -match '(?i)\b(frontend|web.app|spa|react|vue|angular)\b' -or "frontend-web" -in $ExplicitSurfaces) {
        $surfaces += [PSCustomObject]@{ surface="frontend-web"; confidence="EXPLICIT" }
    }
    if ($desc -match '(?i)\b(threejs|3[dD].scene|3[dD].model|webgl|canvas.render|interactive.3d)\b' -or "threejs-interactive" -in $ExplicitSurfaces) {
        $surfaces += [PSCustomObject]@{ surface="threejs-interactive"; confidence="EXPLICIT" }
    }
    if ($desc -match '(?i)\b(miniapp|mini.program|wechat)\b' -or "miniapp" -in $ExplicitSurfaces) {
        $surfaces += [PSCustomObject]@{ surface="miniapp"; confidence="EXPLICIT" }
    }
    if ($desc -match '(?i)\b(mobile.app|mobile|ios|android)\b' -or "mobile-app" -in $ExplicitSurfaces) {
        $surfaces += [PSCustomObject]@{ surface="mobile-app"; confidence="EXPLICIT" }
    }
    if ($desc -match '(?i)\b(background|worker|queue|job|cron|async|message)\b' -or "background-worker" -in $ExplicitSurfaces) {
        $surfaces += [PSCustomObject]@{ surface="background-worker"; confidence="EXPLICIT" }
    }
    if ($desc -match '(?i)\b(database|store|persist|repository|data)\b' -or "database" -in $ExplicitSurfaces) {
        $surfaces += [PSCustomObject]@{ surface="database"; confidence="EXPLICIT" }
    }

    # ============================================
    # IMPLICIT detection (confidence: IMPLIED_HIGH / IMPLIED_LOW)
    # ============================================
    $existingSurfaces = $surfaces | ForEach-Object { $_.surface }

    # save user work / gallery → API + database
    if ($desc -match '(?i)(save.user|gallery|stored.scene|user.creation|archive.user.work|persist)') {
        if ("api-service" -notin $existingSurfaces) {
            $surfaces += [PSCustomObject]@{ surface="api-service"; confidence="IMPLIED_HIGH" }
        }
        if ("database" -notin $existingSurfaces) {
            $surfaces += [PSCustomObject]@{ surface="database"; confidence="IMPLIED_HIGH" }
        }
    }

    # upload → API + storage
    if ($desc -match '(?i)(upload|file.storage|asset.storage)') {
        if ("api-service" -notin $existingSurfaces) {
            $surfaces += [PSCustomObject]@{ surface="api-service"; confidence="IMPLIED_HIGH" }
        }
    }

    # login/roles → auth concern (not a surface, but flags database)
    if ($desc -match '(?i)(login|auth|permission|role|rbac)') {
        if ("database" -notin $existingSurfaces) {
            $surfaces += [PSCustomObject]@{ surface="database"; confidence="IMPLIED_LOW" }
        }
    }

    # order/inventory/price → API + database
    if ($desc -match '(?i)(order|inventory|price|payment|checkout)') {
        if ("api-service" -notin $existingSurfaces) {
            $surfaces += [PSCustomObject]@{ surface="api-service"; confidence="IMPLIED_HIGH" }
        }
        if ("database" -notin $existingSurfaces) {
            $surfaces += [PSCustomObject]@{ surface="database"; confidence="IMPLIED_HIGH" }
        }
    }

    # admin manages content → admin-web + public-web + api-service + database
    if ($desc -match '(?i)admin.*manage.*content|admin.*content.*manage') {
        if ("public-web" -notin $existingSurfaces) {
            $surfaces += [PSCustomObject]@{ surface="public-web"; confidence="IMPLIED_HIGH" }
        }
        if ("api-service" -notin $existingSurfaces) {
            $surfaces += [PSCustomObject]@{ surface="api-service"; confidence="IMPLIED_HIGH" }
        }
        if ("database" -notin $existingSurfaces) {
            $surfaces += [PSCustomObject]@{ surface="database"; confidence="IMPLIED_HIGH" }
        }
    }

    return [PSCustomObject]@{
        surfaces = $surfaces
        explicitCount = ($surfaces | Where-Object { $_.confidence -eq "EXPLICIT" }).Count
        implicitHighCount = ($surfaces | Where-Object { $_.confidence -eq "IMPLIED_HIGH" }).Count
        implicitLowCount = ($surfaces | Where-Object { $_.confidence -eq "IMPLIED_LOW" }).Count
        surfaceNames = @($surfaces | ForEach-Object { $_.surface } | Select-Object -Unique)
    }
}
