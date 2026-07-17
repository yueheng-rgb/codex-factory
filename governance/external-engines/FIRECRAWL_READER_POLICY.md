# Firecrawl Reader Policy

**Version:** 1.0.0
**Status:** READER ONLY — NOT CANONICAL SEARCH

---

## Role

Firecrawl is a **web page reader and content extractor**. It reads the content
of a given URL and returns structured text/markdown.

## What Firecrawl IS

- A reader/extractor for specific URLs
- Useful for reading documentation pages, API references, changelogs
- A supplementary tool when structured content extraction is needed

## What Firecrawl IS NOT

- **NOT canonical search** — does not replace `/api/paas/v4/web_search`
- **NOT an evidence source for P0_MUST_SEARCH gates**
- **NOT a search engine** — cannot discover new URLs, rank results, or answer queries
- **NOT a replacement for the Evidence Pack pipeline**

## Evidence Binding Rules

All Firecrawl output MUST:
1. Be marked `source_origin=firecrawl_reader`
2. Include the source URL
3. Include the non-claim: "This data is from Firecrawl reader — NOT canonical search evidence"
4. NEVER be used as the sole evidence for a P0_MUST_SEARCH gate

## API Key Handling

- Firecrawl requires `FIRECRAWL_API_KEY` environment variable
- The API key MUST NOT appear in:
  - Evidence binding output
  - Engine run logs
  - Command strings
  - Any report file
- Only `secretPresent=true/false` may be reported
- Key prefix, suffix, hash, and length MUST NOT be output

## Current Status

| Item | Status |
|------|--------|
| npm package | NOT_INSTALLED |
| API key | NOT_SET |
| Availability | TOOL_UNAVAILABLE |
| Can be used | No — requires user setup |
