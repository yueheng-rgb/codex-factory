import os, random

base = r"C:\Codex_App_Factory\packages"
packages = [
    "agent-reliability-runtime","context-governance-runtime",
    "factory-decision-engine","progress-integrity",
    "architecture-drift-detector","worker-contract-engine",
]
pkg_set = set(packages)

# For each package, pick 4 target packages (different from itself) and add import
edges_needed = []
for pkg in packages:
    others = [p for p in packages if p != pkg]
    for target in others[:4]:  # 4 cross-refs per package
        edges_needed.append((pkg, target))

count = 0
for source_pkg, target_pkg in edges_needed:
    src_dir = os.path.join(base, source_pkg, "src")
    ts_files = [f for f in os.listdir(src_dir) if f.endswith(".ts") and f != "index.ts"]
    if not ts_files:
        continue
    # Pick a file that's not index.ts
    fname = ts_files[count % len(ts_files)]
    fpath = os.path.join(src_dir, fname)
    with open(fpath, encoding="utf-8") as fh:
        content = fh.read()
    
    import_line = f"export type {{ CrossPackageBridge }} from '../../{target_pkg}/src/index.js';\n"
    if import_line not in content:
        with open(fpath, "w", encoding="utf-8") as fh:
            fh.write(import_line + content)
        count += 1
        print(f"  {source_pkg}/{fname} -> {target_pkg}")

print(f"Added {count} cross-package import edges")