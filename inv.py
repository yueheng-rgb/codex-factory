import json, os
from datetime import datetime
ts = datetime.now().isoformat()
R = r"C:\Codex_App_Factory"
caps = []

def add(name,cat,paths,phase,evidence,verifier,neg,caveats,replaced,replacedBy,riskIn,riskOut,disp):
    caps.append({"capabilityName":name,"category":cat,"sourcePaths":paths,"firstSeenPhase":phase,
        "currentUsageEvidence":evidence,"verifierEvidence":verifier,"negativeControlEvidence":neg,
        "knownCaveats":caveats,"replacedByNewerMechanism":replaced,"replacedBy":replacedBy,
        "riskIfPackaged":riskIn,"riskIfExcluded":riskOut,"recommendedDisposition":disp})

add("risk-classifier","scoring_system",["packages/risk-classifier/src/"],"DRY23-A",
    "18 RiskType signals, 4 severity levels, full evaluation pipeline","None","None",
    ["Heuristic-based severity","No negative control for HIGH masking P0","Scores could replace evidence"],
    False,"","HIGH: Score-based gating instead of verifier. Could mask hard floors.",
    "LOW: Signal taxonomy useful as reference only.","REFERENCE_ARCHIVED")