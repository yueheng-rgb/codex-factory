# R2.3-N Research Intake Integration Report

## Integration Path

GLM Search Adapter → Research Intake → Knowledge Pipeline

`
External Search Provider (human/ChatGPT/GLM/Claude/Perplexity)
    │
    ├─ manual_mode: user/AI provides results in JSON
    ├─ dry_run_mode: mock GLM fixture
    └─ live_api_mode: ZhipuAI API call (GATED — requires key + human approval; NOT YET EXECUTED)
    │
    ▼
GLM Search Adapter (Invoke-GLMSearch)
    │
    ├─ Permission Gate (TOOL-SEARCH-ADAPTER-001 or TOOL-GLM-SEARCH-001)
    ├─ Secret Check
    ├─ Mode execution
    ├─ Quality Gate v2
    └─ Invocation Ledger
    │
    ▼
Convert-GLMResponseToResearchIntake
    │
    ▼
Research Intake Packet (research-intake.schema.json)
    │
    ▼
Research Packet (future: research-packet.schema.json)
    │
    ▼
Knowledge Capsule / Skill Candidate (with Librarian + Security + Architect review)
`

## Intake Conversion

Convert-GLMResponseToResearchIntake transforms the adapter's normalized response into a standard Research Intake packet:

| GLM Response Field | Research Intake Field |
|---|---|
| query | query.question |
| mode | Context in awResult + userNotes |
| sourceRefs | links (typed: official_docs/github/blog/other) |
| sourceRefs[].title | sourceTitles |
| sourceRefs[].publishDate | publishDates |
| mode (dry_run) | uncertainty: high |
| mode (manual/live) | uncertainty: medium |
| — | provider.type: glm_search |
| — | provider.canBeDirectSource: false |

## Key Constraints
- Search results enter as Research Intake, NOT directly as skill candidates
- Quality gate must pass before intake conversion
- AI-generated results marked canBeDirectSource: false
- Manual/human results marked 	rustLimit: AVAILABLE
- All intake records carry source references with URLs
