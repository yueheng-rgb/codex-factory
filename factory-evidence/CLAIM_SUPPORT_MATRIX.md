# CLAIM_SUPPORT_MATRIX.md
> Part of: FACTORY-EVIDENCE-TAXONOMY-0 / C

## Claim Types and Minimum Evidence

| Claim | Min Level | Forbidden Evidence |
|-------|-----------|-------------------|
| "Design is complete" | E1 | E0, dashboard, snapshot |
| "Policy is compliant" | E2 | E0, dashboard |
| "Files exist" | E3 | E0, chat summary |
| "Script runs on fixture" | E4 | E0-E2, dashboard |
| "Product exists (files+hash)" | E5 | E0-E3, snapshot, dashboard |
| "Works on local machine" | E6 | E0-E4, dashboard |
| "Production ready" | E7 | E0-E5, dashboard, snapshot, attach-packet |
| "Works across project types" | E8 | E0-E6 alone |
| "Universal / always superior" | BLOCKED | All levels (no evidence supports universal claims) |
| "Factory proven universally" | BLOCKED | All levels |

## Claim Validation Rules
- Every claim MUST reference specific evidence level
- Claim level MUST be <= evidence level
- Lower evidence cannot support higher claim (promotion forbidden without execution)
- Dashboard/snapshot/attach-packet/chat-summary NEVER primary evidence
- "Universal" / "always" claims → BLOCKED regardless of evidence level
