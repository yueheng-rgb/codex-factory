# Knowledge Packs

Import your own project knowledge, docs, and rules into Codex Factory.

## Quick Start

```powershell
# Add a knowledge pack from a docs folder
powershell -File runtime/knowledge-pack-manager.ps1 -Action add -Name my-project -Source ./docs

# List all knowledge packs
powershell -File runtime/knowledge-pack-manager.ps1 -Action list

# Build keyword index for search
powershell -File runtime/knowledge-pack-manager.ps1 -Action index

# Validate integrity
powershell -File runtime/knowledge-pack-manager.ps1 -Action validate

# Remove a knowledge pack
powershell -File runtime/knowledge-pack-manager.ps1 -Action remove -Name my-project
```

## Supported Formats

- Markdown (`.md`)
- Plain text (`.txt`)
- JSON (`.json`)
- YAML (`.yaml`, `.yml`)
- OpenAPI specs (`.openapi`)
- README files

## Privacy

- Knowledge packs are **local-only** by default
- Content enters **Evidence Pack** (traceable), never raw prompt injection
- `knowledge/private/` is gitignored — put confidential docs there
- Every claim must be traceable to a source file

## Structure

```
knowledge/
  index.json              # Pack index
  keyword-index.json      # Searchable keyword index
  packs/
    <pack_name>/
      source-map.json     # SHA256-verified file manifest
      docs/               # Your imported documents
```
