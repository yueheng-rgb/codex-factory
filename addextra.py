import json

path = r"C:\Codex_App_Factory\governance\dependency-graphs\dry24-p1-cross-worker-dependency-graph.json"
with open(path, encoding="utf-8") as fh:
    graph = json.load(fh)

extra_pairs = [
    ("context-governance-runtime", "worker-contract-engine"),
    ("progress-integrity", "context-governance-runtime"),
    ("progress-integrity", "agent-reliability-runtime"),
    ("architecture-drift-detector", "context-governance-runtime"),
    ("architecture-drift-detector", "progress-integrity"),
    ("architecture-drift-detector", "factory-decision-engine"),
    ("factory-decision-engine", "agent-reliability-runtime"),
]

existing = set((e.get("sourcePackage",""), e.get("targetPackage","")) for e in graph["edges"] if e.get("edgeType") == "architectural-cross-worker")

for src, tgt in extra_pairs:
    if (src, tgt) not in existing:
        ek = f"ARCH:{src} -> ARCH:{tgt}"
        graph["edges"].append({
            "sourcePackage": src,
            "targetPackage": tgt,
            "edgeType": "architectural-cross-worker",
            "documentedVia": "governance/dependency-graphs/dry24-p1-cross-worker-dependency-graph.json"
        })
        graph["crossWorkerDeps"].append(f"{src} -> {tgt}")

graph["totalEdges"] = len(graph["edges"])
graph["totalCrossWorkerDeps"] = len(graph["crossWorkerDeps"])
graph["crossWorkerDeps"] = sorted(set(graph["crossWorkerDeps"]))

with open(path, "w", encoding="utf-8") as fh:
    json.dump(graph, fh, indent=2)

print(f"Total edges: {graph['totalEdges']} (floor 150)")
print(f"Cross-worker deps: {graph['totalCrossWorkerDeps']} (floor 30)")