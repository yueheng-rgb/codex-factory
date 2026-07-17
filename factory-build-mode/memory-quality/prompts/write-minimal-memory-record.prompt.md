# Write Minimal Memory Record

When asked to "write minimal memory record" for a phase:

1. Identify the phase that just completed
2. Find the verifier result and main report
3. Classify the record category (PHASE_RESULT, BLOCKER_UPDATE, DECISION, RISK, LESSON)
4. Write summary ≤ 500 chars:
   - What happened (1 sentence)
   - What was decided (1 sentence)
   - What evidence supports it (1 sentence with path)
5. Add caveat if:
   - Claim is design-only → "DESIGN_ONLY: ..."
   - Claim is local-only → "LOCAL_ONLY: ..."
   - Claim is partial → explain what is missing
   - Single data point → warn about generalizability
6. Add score if applicable (with max value)
7. Add related phases
8. Run validator (15 checks) before writing
9. If validator BLOCKED → fix and retry
10. If validator PASS → write to External Conversation Space

## Anti-patterns
- Do NOT omit caveat to make claim look stronger
- Do NOT present design analysis as executed evidence
- Do NOT present local trial as production readiness
- Do NOT exceed 500 chars for summary
- Do NOT include secrets, endpoints, or real project data
