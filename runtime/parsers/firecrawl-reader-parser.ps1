# Firecrawl Reader Parser v1.0.0
# Parses Firecrawl scrape output into structured evidence
# CRITICAL: Firecrawl is READER only — NOT canonical search
param(
    [string]$JsonPath,
    [string]$SourceUrl = "unknown"
)

function Invoke-FirecrawlReaderParse {
    param([string]$Path, [string]$Url)
    
    if (-not $Path -or -not (Test-Path $Path)) {
        return [PSCustomObject]@{ parser_status = "NO_INPUT"; error = "Firecrawl output not found: $Path" }
    }
    
    try {
        $data = Get-Content $Path -Raw | ConvertFrom-Json
        $content = $data.content ?? $data.markdown ?? ""
        $contentLength = if ($content) { $content.Length } else { 0 }
        
        return [PSCustomObject]@{
            parser_status = "OK"
            source_origin = "firecrawl_reader"
            source_url = $Url
            content_length = $contentLength
            metadata = $data.metadata ?? @{}
            has_content = $contentLength -gt 0
            non_claim = "This data is from Firecrawl reader — NOT canonical search evidence"
        }
    } catch {
        return [PSCustomObject]@{ parser_status = "PARSE_ERROR"; error = $_.Exception.Message }
    }
}

$result = Invoke-FirecrawlReaderParse -Path $JsonPath -Url $SourceUrl
$result | ConvertToJson -Depth 3
