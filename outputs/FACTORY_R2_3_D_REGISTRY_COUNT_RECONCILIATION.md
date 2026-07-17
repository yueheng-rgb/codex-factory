# FACTORY R2.3-D Registry Count Reconciliation

## Question

R2.3-C reported "7 registries, 151 entries." R2.3-D has 91 in master + 61 in typed = 152. Why the discrepancy?

## Answer

**The 151 count in R2.3-C was: 90 master entries + 61 typed entries = 151 lines across all 7 files combined.**

R2.3-D added `CAP-SKILL-099` to the master registry, bringing master to 91. Typed registries remain at 61. Total: 152.

## Detailed Breakdown

| File | Entries (R2.3-C) | Entries (R2.3-D) | Delta |
|------|-----------------|-----------------|-------|
| capability-candidate-registry.jsonl (master) | 90 | 91 | +1 (CAP-SKILL-099) |
| skill-candidate-registry.jsonl | 12 | 12 | 0 |
| mcp-candidate-registry.jsonl | 14 | 14 | 0 |
| search-provider-candidate-registry.jsonl | 10 | 10 | 0 |
| template-starter-candidate-registry.jsonl | 9 | 9 | 0 |
| verifier-candidate-registry.jsonl | 10 | 10 | 0 |
| runner-candidate-registry.jsonl | 6 | 6 | 0 |
| **Total (all files)** | **151** | **152** | **+1** |

## Key Clarifications

### 1. Master vs Typed Overlap
The master registry contains ALL 91 capability candidates. Typed registries are **subsets** organized by type. There is intentional overlap — the same capabilityId may appear in both master and its type-specific registry.

### 2. No capabilityId Duplicates
Within any single file, all capabilityIds are unique. Across files, the same capabilityId may appear in master + typed, which is by design.

### 3. No Orphan Entries
Every entry in a typed registry has a corresponding entry in the master registry. No typed entry exists without a master counterpart.

### 4. Master-Only Entries
Some capability types (cli_tool: 8, sdk: 6, generator: 5, cloud_service: 6, knowledge_source: 4) exist only in the master registry, not in any typed registry. These 29 entries are tracked in master but don't have dedicated typed registry files yet.

### 5. CAP-SKILL-099 Status
- Added to master registry: YES
- Added to skill-candidate-registry.jsonl: NO (pending human review)
- Action: `import`, trust: `AVAILABLE`, triggers PENDING_HUMAN in gate

## Summary Formula

```
Total lines across all 7 files = master_entries + sum(typed_entries)
                               = 91 + (12+14+10+9+10+6)
                               = 91 + 61
                               = 152
```

No counting errors. No duplicates. No orphans. The apparent discrepancy was a reporting artifact in R2.3-C that used a stale count before CAP-SKILL-099 was added to the master.
