# Delete Context Space
Delete project {project_id} from Context Space:
1. PLAN first — mandatory preview
2. User reviews PLAN report
3. User re-runs with --Confirm
4. PHASE_ARTIFACTS, CACHE, STALE, DUPLICATE deleted
5. CORE_EVIDENCE preserved unless --ForceEvidence
6. Generate deletion report
7. Project status set to DELETED
8. Tell user: "Deleted. CORE_EVIDENCE [preserved/deleted]. Irreversible."
9. NEVER touch real project files — Context Space only
