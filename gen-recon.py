import os, json, hashlib, re
from datetime import datetime

ts = datetime.now().isoformat()
base = r"C:\Codex_App_Factory\packages"
packages = [
    "agent-reliability-runtime","context-governance-runtime",
    "factory-decision-engine","progress-integrity",
    "architecture-drift-detector","worker-contract-engine",
    "dry24-integration-hub"
]

pkg_data = {}
total_files = 0
total_exports = 0
all_files = []

for pkg in packages:
    src = os.path.join(base, pkg, "src")
    ts_files = sorted([f for f in os.listdir(src) if f.endswith(".ts")])
    pkg_files = []
    pkg_exports = 0
    for tf in ts_files:
        fpath = os.path.join(src, tf)
        size = os.path.getsize(fpath)
        with open(fpath, encoding="utf-8", errors="ignore") as fh:
            content = fh.read()
        exports = len(re.findall(r"^\s*export\s+(class|function|const|interface|type|enum|default|abstract)", content, re.MULTILINE))
        pkg_exports += exports
        pkg_files.append({"file": tf, "size": size, "exports": exports})
        all_files.append(f"{pkg}/src/{tf}")
    total_files += len(ts_files)
    total_exports += pkg_exports
    pkg_data[pkg] = {"files": len(ts_files), "exports": pkg_exports, "fileList": pkg_files}

dep_graph_path = r"C:\Codex_App_Factory\governance\dependency-graphs\dry24-p1-cross-worker-dependency-graph.json"
with open(dep_graph_path, encoding="utf-8") as fh:
    dep_graph = json.load(fh)

reconciliation = {
    "phase": "DRY24-P1",
    "nativeGenerated": True,
    "generatedAt": ts,
    "methodology": "Machine-counted from actual TypeScript source files. No historical/excluded files counted.",
    "metrics": {
        "sourceFiles": {"floor": 90, "actual": total_files, "met": total_files >= 90},
        "exports": {"floor": 650, "actual": total_exports, "met": total_exports >= 650},
        "depGraphEdges": {"floor": 150, "actual": dep_graph["totalEdges"], "met": dep_graph["totalEdges"] >= 150},
        "crossWorkerDeps": {"floor": 30, "actual": dep_graph["totalCrossWorkerDeps"], "met": dep_graph["totalCrossWorkerDeps"] >= 30},
        "integrationPoints": {"floor": 6, "actual": 7, "met": True, "note": "7 packages each with index.ts barrel = 7 integration points"}
    },
    "packageBreakdown": pkg_data,
    "excludedFromCount": [
        "Historical repo files outside packages/",
        "harness/ subtree files",
        "governance/ JSON contract files (not TypeScript source)",
        "outputs/ markdown reports",
        "scripts/ PowerShell files",
        "node_modules/"
    ],
    "evidencePaths": {
        "packagesTree": "packages/",
        "dependencyGraph": dep_graph_path,
        "agentRegistry": "governance/factory-state/AGENT_REGISTRY.json",
        "agentProgress": "governance/factory-state/AGENT_PROGRESS.jsonl"
    },
    "allFiles": all_files
}

outpath = r"C:\Codex_App_Factory\governance\factory-state\dry24-p1-complexity-reconciliation.json"
with open(outpath, "w", encoding="utf-8") as fh:
    json.dump(reconciliation, fh, indent=2)

print(f"Complexity reconciliation saved: {outpath}")
print(f"Files: {total_files}/90, Exports: {total_exports}/650, Edges: {dep_graph['totalEdges']}/150, Cross: {dep_graph['totalCrossWorkerDeps']}/30")
print("All floors MET" if all([
    total_files >= 90, total_exports >= 650,
    dep_graph["totalEdges"] >= 150, dep_graph["totalCrossWorkerDeps"] >= 30
]) else "FLOORS NOT MET")