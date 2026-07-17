# Run Socratic Clarification

Trigger ONLY when high-risk ambiguity is detected:
- Direction conflict between active strategies
- Unclear phase scope that could lead to overreach
- Release/deploy/security/secret boundary
- Evidence classification ambiguous (design vs execution)
- User intent unclear (release vs trial)

## Rules
1. Ask 1-3 specific questions about the ambiguity
2. Each question must be:
   - Specific to the ambiguity (not generic)
   - Multiple choice with clear tradeoffs
   - Not already answered in this session
3. Do NOT ask:
   - "Are you sure?" (too vague)
   - Questions about normal execution steps
   - More than 3 questions
   - The same question twice in a session
4. After answers: proceed with clarified direction

## Non-triggers (do NOT use Socratic)
- Normal build/install/bootstrap/preflight/phase-close
- Documentation phases
- Formatting/cleanup tasks
- User explicitly confirms a direction
