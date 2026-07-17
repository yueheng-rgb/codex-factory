# Reader / Extractor Adapter
# Part of: FACTORY-R2.3-O
# Abstraction for content extraction. Manual + dry_run modes only in this phase.
# Future: Jina Reader, Firecrawl, Tavily Extract, Exa Context

function Invoke-ReaderExtractor {
    param(
        [Parameter(Mandatory=$true)][string]$ExtractorId,
        [Parameter(Mandatory=$true)][ValidateSet("manual_excerpt","local_markdown","dry_run_fixture","jina_reader","firecrawl","tavily_extract","exa_context","kimi_crawl")][string]$ProviderType,
        [Parameter(Mandatory=$true)][ValidateSet("manual","dry_run")][string]$Mode,
        [string[]]$Urls = @(),
        [string[]]$ManualExcerpts = @(),
        [string[]]$LocalMarkdownPaths = @(),
        [string]$ProjectId = "PROJ-EXTRACTOR"
    )

    # Gate: only manual and dry_run supported now
    if ($Mode -eq "live_api" -and $ProviderType -in @("jina_reader","firecrawl","tavily_extract","exa_context","kimi_crawl")) {
        return [PSCustomObject]@{
            extractorId = $ExtractorId; providerType = $ProviderType; mode = $Mode
            accepted = $false; reason = "live_api not supported for external readers in current phase"
            extractedContent = @(); extractionMethod = "none"; limitations = @("Requires API key + human approval (deferred)")
        }
    }

    $content = @()
    $method = ""
    $limitations = @()

    switch ($ProviderType) {
        "manual_excerpt" {
            $method = "manual_excerpt"
            $limitations += "Human-provided; may be incomplete or biased"
            for ($i = 0; $i -lt $ManualExcerpts.Count; $i++) {
                $url = if ($i -lt $Urls.Count) { $Urls[$i] } else { "" }
                $content += [PSCustomObject]@{
                    url = $url; title = "Manual Excerpt $($i+1)"
                    content = $ManualExcerpts[$i]
                    wordCount = ($ManualExcerpts[$i] -split '\s+').Count
                    extractedAt = Get-Date -Format "yyyy-MM-ddTHH:mm:sszzz"
                }
            }
        }
        "local_markdown" {
            $method = "local_markdown"
            $limitations += "Local files only; not fetched from web"
            foreach ($path in $LocalMarkdownPaths) {
                if (Test-Path $path) {
                    $mdContent = Get-Content $path -Raw -Encoding UTF8
                    $content += [PSCustomObject]@{
                        url = "file://$path"; title = (Split-Path $path -Leaf)
                        content = $mdContent
                        wordCount = ($mdContent -split '\s+').Count
                        extractedAt = Get-Date -Format "yyyy-MM-ddTHH:mm:sszzz"
                    }
                }
            }
        }
        "dry_run_fixture" {
            $method = "dry_run_fixture"
            $limitations += "Mock data only; NOT real web content"
            foreach ($url in $Urls) {
                $content += [PSCustomObject]@{
                    url = $url; title = "DRY_RUN: Content from $url"
                    content = "[DRY_RUN FIXTURE] This is simulated extracted content for: $url. No real HTTP request was made. Use manual_excerpt or local_markdown for real content."
                    wordCount = 25
                    extractedAt = Get-Date -Format "yyyy-MM-ddTHH:mm:sszzz"
                }
            }
        }
        default {
            # Future external readers — gated
            if ($Mode -eq "dry_run") {
                $method = "dry_run_$ProviderType"
                $limitations += "Dry run for $ProviderType — no real API call"
                foreach ($url in $Urls) {
                    $content += [PSCustomObject]@{
                        url = $url; title = "DRY_RUN $ProviderType : $url"
                        content = "[DRY_RUN $ProviderType] Simulated extraction. Real extraction requires API key + human approval."
                        wordCount = 20; extractedAt = Get-Date -Format "yyyy-MM-ddTHH:mm:sszzz"
                    }
                }
            }
        }
    }

    return [PSCustomObject]@{
        extractorId = $ExtractorId; providerType = $ProviderType; mode = $Mode
        accepted = $true
        extractedContent = $content
        extractionMethod = $method
        contentCount = $content.Count
        limitations = $limitations
        apiRequired = ($ProviderType -in @("jina_reader","firecrawl","tavily_extract","exa_context","kimi_crawl"))
        networkBoundary = if ($ProviderType -in @("manual_excerpt","local_markdown","dry_run_fixture")) { "no_network" } else { "external_api" }
    }
}

Write-Verbose "Reader/Extractor Adapter loaded. Modes: manual, dry_run. External readers deferred."
