# Reader/Extractor Result Parser v1.0.0
# Part of: FACTORY-R3.0
# Parses firecrawl_reader output — evidence-only, NOT canonical search.
# Firecrawl MUST NOT replace canonical search or become a Search Agent.

function Parse-ReaderResult {
    param(
        [Parameter(Mandatory=$true)][string]$RawOutput,
        [string]$EngineId = "firecrawl_reader"
    )

    $result = @{
        engine_id = $EngineId
        status = "CLEAN"
        findings_count = 0
        findings_by_severity = @{ ERROR = 0; WARNING = 0; INFO = 0 }
        findings = @()
        raw_output_summary = ""
        evidence_binding = @{
            evidence_type = "extracted_content"
            evidence_summary = ""
            evidence_files = @()
        }
    }

    if (-not $RawOutput -or $RawOutput.Trim().Length -eq 0) {
        $result.status = "TOOL_FAILED"
        $result.raw_output_summary = "Empty output"
        return [PSCustomObject]$result
    }

    # Firecrawl is EVIDENCE_ONLY — never block on its output
    # It provides extracted content metadata only

    try {
        $data = $RawOutput | ConvertFrom-Json

        $title = if ($data.title) { $data.title } else { "Untitled" }
        $contentLen = if ($data.content) { $data.content.Length } else { 0 }
        $sourceUrl = if ($data.sourceURL) { $data.sourceURL } else { "unknown" }

        $result.status = "CLEAN"
        $result.raw_output_summary = "Firecrawl: extracted '$title' ($contentLen chars) from $sourceUrl"
        $result.evidence_binding.evidence_summary = $result.raw_output_summary

        # NOTE: This evidence goes to extracted_content, NOT to search evidence.
        # The canonical search path remains /api/paas/v4/web_search + search_std.
        $result.evidence_binding.evidence_type = "extracted_content"
    } catch {
        $result.raw_output_summary = ($RawOutput -split "`n" | Select-Object -First 3) -join "; "
        $result.status = "CLEAN"
        $result.evidence_binding.evidence_summary = "Firecrawl: content extracted (non-JSON output)"
    }

    return [PSCustomObject]$result
}
