# Project Surface Model — Surface Type Registry
# Part of: FACTORY-R2.12
# Defines every known surface type, its recommended starter, dependencies, risk level, and required tests.
# Used by project-surface-router.ps1 to compose multi-surface project plans.

$SURFACE_REGISTRY = @(
    @{
        surface_type = "api-service"
        description = "Backend REST API service providing data endpoints"
        recommended_starter = "node-api-postgres"
        fallback_starter = ""
        typical_dependencies = @("database")
        provides_to = @("admin-web", "public-web", "frontend-web", "miniapp", "mobile-app", "threejs-interactive")
        risk_level = "medium"
        required_tests = @("typecheck", "api-tests", "health-check")
        integration_protocol = "REST"
        runnable = $true
    },
    @{
        surface_type = "admin-web"
        description = "Internal admin dashboard for data management"
        recommended_starter = "next-fullstack-admin"
        fallback_starter = ""
        typical_dependencies = @("api-service")
        provides_to = @()
        risk_level = "medium"
        required_tests = @("typecheck", "build", "smoke")
        integration_protocol = "REST"
        runnable = $true
    },
    @{
        surface_type = "public-web"
        description = "Public-facing marketing/content website"
        recommended_starter = "vite-react-content-site"
        fallback_starter = ""
        typical_dependencies = @()
        provides_to = @()
        risk_level = "low"
        required_tests = @("typecheck", "build")
        integration_protocol = "none"
        runnable = $true
    },
    @{
        surface_type = "frontend-web"
        description = "User-facing web application (SaaS, tool, interactive)"
        recommended_starter = "next-saas-ai-tool"
        fallback_starter = "vite-react-content-site"
        typical_dependencies = @("api-service")
        provides_to = @()
        risk_level = "medium"
        required_tests = @("typecheck", "build", "smoke")
        integration_protocol = "REST"
        runnable = $true
    },
    @{
        surface_type = "miniapp"
        description = "WeChat mini-program or uni-app cross-platform"
        recommended_starter = "miniapp-basic"
        fallback_starter = ""
        typical_dependencies = @("api-service")
        provides_to = @()
        risk_level = "medium"
        required_tests = @("build", "preview")
        integration_protocol = "REST"
        runnable = $false
    },
    @{
        surface_type = "mobile-app"
        description = "Expo / React Native mobile application"
        recommended_starter = "expo-mobile-app"
        fallback_starter = ""
        typical_dependencies = @("api-service")
        provides_to = @()
        risk_level = "medium"
        required_tests = @("build", "preview")
        integration_protocol = "REST"
        runnable = $false
    },
    @{
        surface_type = "threejs-interactive"
        description = "Interactive 3D Web prototype or scene"
        recommended_starter = "vite-threejs-interactive"
        fallback_starter = ""
        typical_dependencies = @()
        provides_to = @()
        risk_level = "medium"
        required_tests = @("typecheck", "build")
        integration_protocol = "none"
        runnable = $true
    },
    @{
        surface_type = "background-worker"
        description = "Async job processor / scheduled tasks"
        recommended_starter = "node-api-postgres"
        fallback_starter = ""
        typical_dependencies = @("database")
        provides_to = @("api-service", "admin-web")
        risk_level = "medium"
        required_tests = @("typecheck", "unit-tests")
        integration_protocol = "event"
        runnable = $false
    },
    @{
        surface_type = "database"
        description = "PostgreSQL database with Prisma/Drizzle schema"
        recommended_starter = "node-api-postgres"
        fallback_starter = ""
        typical_dependencies = @()
        provides_to = @("api-service", "background-worker")
        risk_level = "high"
        required_tests = @("migration", "seed")
        integration_protocol = "shared-db"
        runnable = $true
    },
    @{
        surface_type = "docs-release"
        description = "Documentation site or release notes"
        recommended_starter = "vite-react-content-site"
        fallback_starter = ""
        typical_dependencies = @()
        provides_to = @()
        risk_level = "low"
        required_tests = @("typecheck", "build")
        integration_protocol = "none"
        runnable = $true
    }
)
