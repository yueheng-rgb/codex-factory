import os, re
packages = [
    "agent-reliability-runtime","context-governance-runtime",
    "factory-decision-engine","progress-integrity",
    "architecture-drift-detector","worker-contract-engine",
    "dry24-integration-hub"
]
base = r"C:\Codex_App_Factory\packages"
pkg_set = set(packages)
total_edges = 0
cross_worker = set()
for pkg in packages:
    src = os.path.join(base, pkg, "src")
    ts_files = sorted([f for f in os.listdir(src) if f.endswith(".ts")])
    ecount = 0
    for tf in ts_files:
        fpath = os.path.join(src, tf)
        with open(fpath, encoding="utf-8", errors="ignore") as fh:
            content = fh.read()
        matches = re.findall(r'(?:import|export)(?:\s+type)?\s+(?:\{[^}]*\}|\*|\w+)\s+from\s+[\x27\x22]([^\x27\x22]+)[\x27\x22]', content)
        for imp in matches:
            ecount += 1
            if imp.startswith("../"):
                parts = imp.split("/")
                # Skip all leading ".." segments
                idx = 0
                while idx < len(parts) and parts[idx] == "..":
                    idx += 1
                if idx < len(parts):
                    target = parts[idx]
                    if target in pkg_set and target != pkg:
                        cross_worker.add(pkg + " -> " + target)
    total_edges += ecount
    print(f"{pkg}: {len(ts_files)} files, {ecount} edges")
print("")
print(f"TOTAL dep edges: {total_edges} (floor 150)")
print(f"Cross-worker deps: {len(cross_worker)} (floor 30)")
for cw in sorted(cross_worker):
    print(f"  {cw}")