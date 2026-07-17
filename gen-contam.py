import json
from datetime import datetime

ts = datetime.now().isoformat()

contamination = {
    "phase": "DRY24-P1",
    "nativeGenerated": True,
    "generatedAt": ts,
    "investigation": {
        "incident": "Wegener (dry24-builder-decision) wrote to ContractSchema.ts outside owned scope",
        "file": "packages/worker-contract-engine/src/ContractSchema.ts",
        "fileOwnedBy": "Epicurus (dry24-builder-contracts)",
        "modifiedBy": "Wegener (dry24-builder-decision)",
        "fileSize": 639,
        "resolution": "Both builders' writes conflicted. File now correctly owned by Epicurus (contracts builder) after repair.",
        "classification": "NON_BLOCKING_REPAIRED_BEFORE_CLOSURE",
        "repairedBy": "Integrator during DRY24-P1 reconciliation",
        "repairAction": "ContractSchema.ts ownership restored to worker-contract-engine scope; Wegener writes reverted from that file.",
        "doesNotAffectComplexityEvidence": True,
        "doesNotAffectCrossWorkerDeps": True,
        "reasonNotBlocking": "Contamination was detected, classified, and repaired before closure. No permanent scope violation remains."
    },
    "verifierNote": "Original DRY24 verifier reported 16/16 PASS but missed this cross-scope write because file-level scope isolation was not checked.",
    "h17CandidateHardening": "Add file-level scope ownership check to factoryctl verify"
}

outpath = r"C:\Codex_App_Factory\governance\factory-state\dry24-p1-cross-scope-contamination.json"
with open(outpath, "w", encoding="utf-8") as fh:
    json.dump(contamination, fh, indent=2)

print(f"Contamination investigation saved: {outpath}")
print(f"Classification: {contamination['investigation']['classification']}")