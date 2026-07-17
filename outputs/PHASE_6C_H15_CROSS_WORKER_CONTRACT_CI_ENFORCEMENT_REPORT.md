# Phase 6C H15 Cross-Worker Contract CI Enforcement Report

**Phase:** H15 / Cross-Worker Contract CI Enforcement
**Date:** 2026-06-23
**Verdict:** PASS
**Verifier:** scripts/phase6c-h15-cross-worker-contract-ci-enforcement-verify.ps1
**Exit Code:** 0
**Check Count:** 31/31 PASS

---

## Summary

H15 operationalized cross-worker contract enforcement as a machine-verifiable CI mechanism. A JSON contract schema, contract validation script, dependency graph extractor, and scope isolation checks were created. 8 worker contracts (4 DRY21 retroactive + 4 H15 native) validate against the schema. 12 negative controls verify CI enforcement gates.

## Key Artifacts

| Artifact | Path | Purpose |
|----------|------|---------|
| Contract Schema | `governance/contracts/worker-contract.schema.json` | Machine-readable schema for all worker contracts |
| Contract Validator | `scripts/contracts/validate-contracts.ps1` | Validates .worker-contract.json files against schema |
| Dependency Graph Extractor | `scripts/contracts/extract-dependency-graph.ps1` | Extracts cross-worker dependency edges from source |
| DRY21 Retroactive Contracts | `governance/contracts/h15/dry21-*.worker-contract.json` | 4 retroactive contracts (retroactive:true) |
| H15 Native Contracts | `governance/contracts/h15/h15-*.worker-contract.json` | 4 native contracts (nativeGenerated:true) |
| Dependency Graph | `governance/dependency-graphs/h15-cross-worker-dependency-graph.json` | 2178 edges, 8 workers |
| Negative Controls | `harness/runs/h15-negative-controls/` | 12 negatives, 0 generic FAIL |

## Contract Schema Coverage

Each contract defines:
- phase, agentId, role, isReadOnly (verifier vs builder)
- scope: owned files/directories, forbidden paths
- allowedImports, forbiddenImports
- exportedApiSurface
- dependencyDeclarations (target agent, scope, type, direction, edge count)
- integrationHandoff (path, format, expected consumer)
- evidencePath, forkContext, nativeGenerated, retroactive

## H15 Workers

| Agent ID | Role | Contract | nativeGenerated |
|----------|------|----------|-----------------|
| h15-contract-validator | verifier | validate-contracts.ps1 | true |
| h15-dep-graph-extractor | builder | extract-dependency-graph.ps1 | true |
| h15-scope-enforcer | builder | scope enforcement | true |
| h15-integration-handoff | integrator | dependency graph integration | true |
| h15-orchestrator-1 | orchestrator | governance/factory-state | true |

## Negative Controls

| ID | Fault Type | Expected Class | Group |
|----|-----------|---------------|-------|
| N01 | Undeclared cross-worker dependency | FAIL_UNDECLARED_CROSS_WORKER_DEPENDENCY | B |
| N02 | Forbidden import | FAIL_FORBIDDEN_IMPORT | B |
| N03 | Scope contamination | FAIL_PROFILE_BOUNDARY_VIOLATION | B |
| N04 | Builder modifies integrator file | FAIL_PROFILE_BOUNDARY_VIOLATION | B |
| N05 | Verifier modifies implementation | FAIL_PROFILE_BOUNDARY_VIOLATION | B |
| N06 | Fake edge count inflation | FAIL_COMPLEXITY_INFLATION | C |
| N07 | Missing worker contract | FAIL_MISSING_WORKER_CONTRACT | A |
| N08 | Stale contract after source change | FAIL_STALE_CONTRACT | C |
| N09 | Handoff path missing | FAIL_MISSING_HANDOFF_PATH | B |
| N10 | Fork context violation | FAIL_FORK_CONTEXT_VIOLATION | A |
| N11 | NativeGenerated false-positive | FAIL_NATIVE_GENERATED_MISATTRIBUTION | A |
| N12 | Parent mismatch | FAIL_PARENT_MISMATCH | C |

- 12/12 negatives with evidence, transcripts, and fault manifests
- 0 generic FAIL, 0 preclassified-only, 0 expectedClass-only, 0 manual PASS

## Remaining Caveats

- DRY21 cross-worker deps are contract-level (not import-level); dependency graph correctly shows 0 undeclared + 0 forbidden
- Full CI pipeline integration requires external CI runner; scripts are standalone-invocable
- Contract SHA256 source evidence field is present but not auto-populated for all DRY21 retroactive contracts

## Recommendation

- **currentTrustedPhase:** H15
- **h15Status:** PASS
- **allowedNextPhase:** DRY22 or H16
- **recommendedNextPhase:** DRY22
