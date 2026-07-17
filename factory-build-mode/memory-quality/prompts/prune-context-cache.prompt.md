# Prune Context Cache
Prune project {project_id}:
1. Run PLAN first — show preview
2. Require user confirmation
3. Remove CACHE: old snapshots, intermediates
4. Retire STALE: outdated claims
5. Dedup DUPLICATE: keep highest sourceTier
6. Preserve CORE_EVIDENCE + PHASE_ARTIFACTS
7. Generate cleanup report with size reclaimed
8. Tell user: "Pruned. Evidence preserved."
