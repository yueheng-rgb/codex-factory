import os, re
packages = ['agent-reliability-runtime','context-governance-runtime','factory-decision-engine','progress-integrity','architecture-drift-detector','worker-contract-engine','dry24-integration-hub']
base = r'C:\Codex_App_Factory\packages'
total_edges = 0
cross_worker = set()
for pkg in packages:
    src = os.path.join(base, pkg, 'src')
    ts_files = [f for f in os.listdir(src) if f.endswith('.ts')]
    ecount = 0
    for tf in ts_files:
        with open(os.path.join(src, tf), encoding='utf-8', errors='ignore') as fh:
            content = fh.read()
        matches = re.findall(r'(?:import|export)\\s+(?:\\{[^}]*\\}|\\*)\\s+from\\s+[\\x27\\x22]([^\\x27\\x22]+)[\\x27\\x22]', content)
        ecount += len(matches)
        for imp in matches:
            if imp.startswith('../'):
                target = imp.split('/')[1]
                if target in packages and target != pkg:
                    cross_worker.add(pkg + ' -> ' + target)
    total_edges += ecount
    print(f'{pkg}: {len(ts_files)} files, {ecount} edges')
print(f'TOTAL edges: {total_edges} (floor 150)')
print(f'Cross-worker deps: {len(cross_worker)} (floor 30)')
for cw in sorted(cross_worker):
    print(f'  {cw}')