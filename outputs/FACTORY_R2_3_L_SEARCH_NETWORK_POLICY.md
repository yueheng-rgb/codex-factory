# R2.3-L Search Adapter Network Policy

## Intake Modes by Network Boundary

| Intake Mode | Network Boundary | API Key | Human | Status |
|------|:---:|:---:|:---:|------|
| manual_input | no_network (0) | No | No | ✅ Local-first |
| local_file_intake | no_network (0) | No | No | ✅ Local-first |
| future_glm_api | external_api (4) | Yes | Yes | ❌ Deferred |
| future_browser_search | external_readonly (3) | No | Yes | ❌ Deferred |
| official_docs_manual | no_network (0) | No | No | ✅ Local-first |

## Current Phase Rules

- Search adapter operates at no_network boundary only
- All search results are imported via manual JSON/Markdown files
- Network access for search is DEFERRED to post-R2.3-L
- When GLM API is connected: external_api boundary, secrets required, human approval required, sandbox required
