# V3.1 — CRITICAL Review Pipeline Demo

## Pipeline Flow

```
[CPM-001 Tests] → [Runner: sandbox] → [Artifacts captured]
    ↓
[Without Receipt] → [Review Verifier: FAIL] → [Gate: BLOCKED]
    ↓
[With signed_local_receipt] → [Review Verifier: PASS] → [Gate: ALLOWED_FOR_REVIEW]
```

## Step 1: Execute CRITICAL Task

- **Task:** CPM-001 cross-pack mission tests
- **Runner:** sandbox (isolated workspace)
- **Result:** 17/17 PASS, exit_code=0
- **Artifacts:** stdout.log + stderr.log captured

## Step 2: Gate Check Without Receipt

- **Verifier:** `review-identity-verifier.ps1`
- **Result:** FAIL — receipt not found
- **Gate Decision:** BLOCKED
- **Rule:** CRITICAL CI job without review receipt → BLOCKED

## Step 3: Create signed_local_receipt

- **Receipt:** `reviews/V3_1-REV-CRITICAL-001.json`
- **Identity Mode:** signed_local_receipt
- **Decision:** APPROVED_WITH_RISK
- **Non-Claims:** 4 entries present

## Step 4: Gate Check With Receipt

- **Verifier:** `review-identity-verifier.ps1`
- **Result:** PASS (all checks pass)
- **Gate Decision:** ALLOWED_FOR_REVIEW

## Non-Claims

- signed_local_receipt uses SIMULATED hash, NOT cryptographic signing
- NOT a real external identity verification
- APPROVED_WITH_RISK is NOT production approval
- CRITICAL CI job without receipt = BLOCKED

## Result

**PASS** — Pipeline correctly enforces: BLOCKED without receipt → ALLOWED_FOR_REVIEW with signed_local_receipt