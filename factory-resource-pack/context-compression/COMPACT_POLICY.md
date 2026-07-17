# Context Compression Protocol — H24-P2 Updated

## Compression Truth
- Codex compresses context (VERIFIED_FACT — observed across H18-H24)
- Compressed summaries are **lossy** — they omit details, state transitions, evidence references
- Compressed summaries are **NOT trusted evidence** — this is an architectural rule

## Compact Detection
- **HYPOTHESIS**: No automatic compact-detection API has been observed
- Factory uses "CONFIRMED compact" — user reports or visible tool evidence of compaction
- Because detection is HYPOTHESIS, Factory cannot claim automatic compact-triggered rotation

## Protocol After CONFIRMED Compact
1. Current window: finish current narrow task only
2. If a new major phase (H/DRY/FINAL) is needed: perform session rotation
3. Generate session-rotation-handoff.json with all evidence hashes
4. New window/fork/thread: run startup artifact verification
5. Do NOT rely on compressed summary as evidence
6. After multiple compactions: rotation is mandatory

## What Is NOT Claimed
- Automatic window creation after compact (REJECTED)
- Full pre-compact context available after fork (REJECTED — lossy compression)
- Compact can be detected automatically (HYPOTHESIS — no API)
