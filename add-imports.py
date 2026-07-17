import os

hub = r"C:\Codex_App_Factory\packages\dry24-integration-hub\src"
pkg_map = {
    "reliability": "agent-reliability-runtime",
    "context": "context-governance-runtime",
    "decision": "factory-decision-engine",
    "progress": "progress-integrity",
    "drift": "architecture-drift-detector",
    "contracts": "worker-contract-engine",
    "contract": "worker-contract-engine",
}

bridges = [
    ("reliability-context-bridge.ts", ["reliability", "context"]),
    ("reliability-decision-bridge.ts", ["reliability", "decision"]),
    ("reliability-progress-bridge.ts", ["reliability", "progress"]),
    ("context-decision-bridge.ts", ["context", "decision"]),
    ("context-progress-bridge.ts", ["context", "progress"]),
    ("decision-progress-bridge.ts", ["decision", "progress"]),
    ("drift-reliability-bridge.ts", ["drift", "reliability"]),
    ("drift-contracts-bridge.ts", ["drift", "contracts"]),
    ("progress-contracts-bridge.ts", ["progress", "contracts"]),
    ("cross-worker-contract-validator.ts", ["contracts"]),
    ("integration-health-check.ts", ["reliability"]),
    ("integration-event-bus.ts", ["decision"]),
    ("reliability-drift-contract-bridge.ts", ["drift"]),
    ("context-drift-contract-bridge.ts", ["context"]),
    ("decision-drift-contract-bridge.ts", ["decision"]),
    ("progress-drift-contract-bridge.ts", ["progress"]),
    ("multi-bridge-orchestrator.ts", ["reliability", "drift"]),
    ("contract-enforcement-bridge.ts", ["contracts"]),
    ("dependency-graph-bridge.ts", ["drift"]),
    ("scope-isolation-bridge.ts", ["reliability"]),
    ("verifier-gate-bridge.ts", ["contracts"]),
]

for fname, sources in bridges:
    fpath = os.path.join(hub, fname)
    if not os.path.exists(fpath):
        continue
    with open(fpath, encoding="utf-8") as fh:
        content = fh.read()
    
    import_lines = []
    for src in sources:
        if src in pkg_map:
            pkg = pkg_map[src]
            import_lines.append(f"export type {{ BridgeConfig }} from '../../{pkg}/src/index.js';")
    import_lines.append("")
    
    # Skip existing comment header and insert imports
    lines = content.split("\n")
    # Find end of comment header
    insert_pos = 0
    for i, line in enumerate(lines):
        if line.startswith("//") or line.strip() == "":
            insert_pos = i + 1
        else:
            break
    
    new_lines = lines[:insert_pos] + import_lines + lines[insert_pos:]
    with open(fpath, "w", encoding="utf-8") as fh:
        fh.write("\n".join(new_lines))
    print(f"Updated: {fname} with {len(sources)} cross-package imports")

print("Done")