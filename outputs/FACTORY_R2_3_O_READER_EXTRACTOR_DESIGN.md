# R2.3-O Reader / Extractor Design

## Abstraction Layer
Content extraction from URLs/documents. Currently supports manual + dry_run modes. External readers (Jina, Firecrawl, Tavily, Exa, Kimi) are registered but gated behind API keys + human approval.

## Supported Provider Types

| Provider | Mode | Network | Status |
|----------|:---:|:---:|:---:|
| manual_excerpt | manual | no_network | active |
| local_markdown | manual | no_network | active |
| dry_run_fixture | dry_run | no_network | active |
| jina_reader | dry_run | external_api (future) | candidate |
| firecrawl | dry_run | external_api (future) | candidate |
| tavily_extract | dry_run | external_api (future) | candidate |
| exa_context | dry_run | external_api (future) | candidate |
| kimi_crawl | dry_run | external_api (future) | candidate |

## Usage

### Manual Excerpt
`
Invoke-ReaderExtractor -ProviderType "manual_excerpt" -Mode "manual" -ManualExcerpts @("Content here") -Urls @("https://...")
`

### Dry Run Fixture
`
Invoke-ReaderExtractor -ProviderType "dry_run_fixture" -Mode "dry_run" -Urls @("https://nextjs.org/docs")
# Returns: [DRY_RUN FIXTURE] simulated content
`

### Future External Readers
All require API key + human approval. Currently return dry_run simulation when called.

## Integration Point
Reader/Extractor sits between Search Adapter and Quality Gate in the pipeline:
Search Adapter → Reader/Extractor → Quality Gate → Research Intake → Evidence Pack
