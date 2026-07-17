# Factory Behavior Diagnosis Template

## Phase: {PHASE}
## Date: {DATE}

### 1. Complexity Preservation
- Did Codex attempt to simplify the task? {YES/NO/NA}
- Were any complexity floors unmet on first pass? {YES/NO}
- If yes, what was the shortfall pattern? {DESCRIPTION}

### 2. Agent Behavior
- Were all spawned agents registered? {YES/NO}
- Any spawn failures? {YES/NO — count}
- Any Main Agent undeclared fallback? {YES/NO}
- Any scope contamination? {YES/NO — classification}

### 3. Verifier Effectiveness
- Did verifier catch all unmet floors? {YES/NO}
- Any verifier PASS over underlying FAIL? {YES/NO}
- Any false positives? {YES/NO}
- Any gate missing from verifier? {YES/NO}

### 4. Negative Control Coverage
- Total negatives designed: {N}
- Executed: {N}
- Detected: {N}
- Gaps: {0}
- Any UNEXPECTED_PASS? {NO}
- Any FAIL_TARGET_NOT_TRIGGERED? {NO}

### 5. Recommendations
- What should the next phase strengthen?
- Any new verifier gates needed?
- Any policy changes recommended?

### 6. Verdict
- Phase classification: {POSITIVE_NEGATIVE_CLOSED / BLOCKED / PASS_WITH_CAVEAT}
- Recommended next phase: {PHASE}