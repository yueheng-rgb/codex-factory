# Risk Signal Taxonomy (REFERENCE ONLY)

> **WARNING**: This taxonomy is from the risk-classifier package (DRY23-A). It is archived as design reference only. The risk-classifier is a scoring system and must NOT be used as a core PASS/FAIL gate. See SCORING_SYSTEM_GATE.md.

## 18 Risk Signal Types
1. parentMismatch — Parent phase does not match expected.
2. manualPass — PASS verdict without verifier JSON.
3. expectedClassOnly — Expected result without actual execution.
4. missingTranscript — Worker completed but no transcript.
5. postHocCapsule — Handoff capsule created after closure, pretending to be original.
6. postHocContract — Contract created after implementation, pretending pre-existing.
7. genericFail — FAIL without specific gate target.
8. runnerSabotage — Evidence deliberately modified by runner.
9. contextCompression — Compressed summary substituted for evidence.
10. fakeComplexity — Empty/duplicate/comment-inflated files counted.
11. preclassifiedOnly — Label assigned before execution.
12. scopeContamination — Worker wrote outside owned scope.
13. integratorBypass — Builder modified integration hub.
14. verifierWriteViolation — Verifier modified implementation.
15. contractCINotInvoked — CI enforcement not run.
16. factoryctlUnavailable — factoryctl not operational.
17. staleHandoff — Handoff from previous session, not refreshed.
18. finalZipEarly — Final ZIP created before closure.

## Usage
This taxonomy informs verifier gate design. It is NOT a scoring rubric. Each signal maps to a specific verifier gate that produces binary PASS/FAIL, not a weighted score.