# V4.0.1 Knowledge-to-Evidence Bridge

## Status: CLOSED

## Changes

| Item | Before (V4.0) | After (V4.0.1) |
|---|---|---|
| `build-evidence` command | Not implemented | Added: exports knowledge to Evidence Pack |
| Evidence traceability | Not enforced | source_file + source_hash + line_count per entry |
| Privacy docs | Basic | Explicit: local-only, never uploaded, never committed |

## Evidence Entry Format

Each entry in the generated evidence pack contains:
- `source_file` — relative path within knowledge pack
- `source_hash` — SHA256 of source
- `source_size` — file size in bytes
- `evidence_type` — spec / documentation / structured_data / text
- `line_count` — lines in source file
- `preview_first_200_chars` — truncated preview
- `extracted_at` — timestamp

## Privacy Guarantees
- Knowledge is local-only by default
- Never uploaded, never committed, never shared
- `knowledge/private/` is gitignored
- Content enters Evidence Pack with attribution, NEVER as raw prompt injection

## Docs Updated
- `docs/knowledge-packs.md` — added Privacy section + evidence export docs
