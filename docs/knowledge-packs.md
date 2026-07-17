# Knowledge Packs

Import your own project knowledge, docs, and rules into Codex Factory.

## Privacy & Security

- Knowledge packs are **local-only** by default
- Your documents are NEVER uploaded, NEVER committed, NEVER shared
- `knowledge/private/` is gitignored — put confidential docs there
- Content enters **Evidence Pack** with full source traceability (source file + SHA256 + line count)
- Every claim must be traceable to a source file — no raw prompt injection

## Quick Start

```powershell
# Add a knowledge pack from a docs folder
pwsh -File runtime/knowledge-pack-manager.ps1 -Action add -Name my-project -Source ./docs

# List all knowledge packs
pwsh -File runtime/knowledge-pack-manager.ps1 -Action list

# Build keyword index for search
pwsh -File runtime/knowledge-pack-manager.ps1 -Action index

# Export to Evidence Pack (traceable, source-attributed)
pwsh -File runtime/knowledge-pack-manager.ps1 -Action build-evidence

# Validate integrity (SHA256 check)
pwsh -File runtime/knowledge-pack-manager.ps1 -Action validate

# Remove a knowledge pack
pwsh -File runtime/knowledge-pack-manager.ps1 -Action remove -Name my-project
```

## Evidence Pack Export

The `build-evidence` command generates `knowledge/evidence/evidence-pack.json` containing:

| Field | Description |
|---|---|
| `source_file` | Path relative to knowledge pack |
| `source_hash` | SHA256 of the source file |
| `source_size` | File size in bytes |
| `evidence_type` | `spec`, `documentation`, `structured_data`, or `text` |
| `line_count` | Number of lines in source |
| `preview_first_200_chars` | Content preview (truncated) |

This evidence pack can be fed into Codex Factory's verification pipeline without exposing raw user documents.

## Supported Formats

- Markdown (`.md`)
- Plain text (`.txt`)
- JSON (`.json`)
- YAML (`.yaml`, `.yml`)
- OpenAPI specs (`.openapi`)

## Structure

```
knowledge/
  index.json              # Pack index
  keyword-index.json      # Searchable keyword index
  evidence/               # Generated evidence packs
  packs/
    <pack_name>/
      source-map.json     # SHA256-verified file manifest
      docs/               # Your imported documents
```
