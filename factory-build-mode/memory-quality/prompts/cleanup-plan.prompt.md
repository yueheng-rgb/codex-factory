# Cleanup Plan Prompt
Generate a cleanup plan for project {project_id}:
1. Scan Context Space inventory
2. Categorize: CORE_EVIDENCE, PHASE_ARTIFACTS, CACHE, STALE, DUPLICATE
3. Estimate sizes per category
4. Produce PLAN report: keep list, delete list, confirm list, size delta
5. Do NOT make any changes
6. Tell user: "Review and re-run with desired mode"
