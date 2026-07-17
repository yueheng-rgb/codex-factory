import os, re, json

repo = r"C:\Codex_App_Factory"

# Search patterns
patterns = {
    "scoring": r"\bscor(?:ing|e)\b",
    "rating": r"\brating\b",
    "quality_metric": r"quality.*metric",
    "rubric": r"\brubric\b",
    "evaluation": r"\bevaluat(?:ion|e)\b",
    "assessment": r"\bassessment\b",
    "grade": r"\bgrade\b",
    "priority_policy": r"priority.*policy|DecisionPriority",
    "confidence": r"\bconfidence\b",
    "trust": r"\btrust(?:ed)?\b",
    "reliability_rating": r"ReliabilityRating",
    "verdict": r"\bverdict\b",
    "risk_signal": r"risk.*signal|RiskSignal",
    "diagnosis": r"\bdiagnosis\b",
    "classification": r"\bclassification\b",
    "complexity_budget": r"complexity.*budget|ComplexityBudget",
    "evidence_weight": r"evidence.*weight",
}

# Directories to search
search_dirs = ["packages", "scripts", "governance", "outputs", "harness"]
extensions = [".ts", ".ps1", ".json", ".md", ".jsonl"]

results = {}
for category, pattern in patterns.items():
    hits = []
    for sdir in search_dirs:
        spath = os.path.join(repo, sdir)
        if not os.path.exists(spath):
            continue
        for root, dirs, files in os.walk(spath):
            # Skip node_modules
            dirs[:] = [d for d in dirs if d != "node_modules"]
            for fname in files:
                ext = os.path.splitext(fname)[1].lower()
                if ext not in extensions:
                    continue
                fpath = os.path.join(root, fname)
                try:
                    with open(fpath, encoding="utf-8", errors="ignore") as fh:
                        content = fh.read()
                    if re.search(pattern, content, re.IGNORECASE):
                        hits.append(fpath)
                except:
                    pass
    if hits:
        results[category] = hits[:15]  # cap per category

for category, paths in sorted(results.items()):
    print(f"\n=== {category} ({len(paths)} hits) ===")
    for p in paths:
        rel = os.path.relpath(p, repo)
        print(f"  {rel}")

print(f"\nTotal categories with hits: {len(results)}")
print(f"Total unique files: {len(set(p for paths in results.values() for p in paths))}")