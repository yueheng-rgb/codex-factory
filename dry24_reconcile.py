import os, json  
BASE = r'C:\Codex_App_Factory\packages'  
DRY24_PKGS = ['agent-reliability-runtime', 'context-governance-runtime', 'factory-decision-engine', 'progress-integrity', 'architecture-drift-detector', 'worker-contract-engine']  
total_files = 0; total_exports = 0; all_files = []  
for pkg in DRY24_PKGS:  
    pkg_dir = os.path.join(BASE, pkg, 'src')  
    if not os.path.exists(pkg_dir):  
        print(f'MISSING: {pkg_dir}')  
        continue  
    pkg_files = 0; pkg_exports = 0  
    for f in os.listdir(pkg_dir):  
        if f.endswith('.ts') and not f.endswith('.d.ts'):  
            fp = os.path.join(pkg_dir, f)  
            pkg_files += 1  
            all_files.append(fp)  
            with open(fp, 'r', encoding='utf-8', errors='replace') as fh:  
                for line in fh:  
                    if line.strip().startswith('export '):  
                        pkg_exports += 1  
    total_files += pkg_files; total_exports += pkg_exports  
    print(f'{pkg}: {pkg_files} files, {pkg_exports} exports')  
print(f'TOTAL DRY24: {total_files} files, {total_exports} exports')  
# D: Cross-scope contamination investigation  
print('=== CROSS-SCOPE CONTAMINATION ===')  
# Check if wegener wrote to worker-contract-engine scope  
cs_path = r'C:\Codex_App_Factory\packages\worker-contract-engine\src\ContractSchema.ts'  
import os  
if os.path.exists(cs_path):  
    size = os.path.getsize(cs_path)  
    mtime = os.path.getmtime(cs_path)  
    print(f'ContractSchema.ts: size={size}B, mtime={mtime}')  
    with open(cs_path, 'r', encoding='utf-8', errors='replace') as f:  
        first = f.readline().strip()  
    print(f'First line: {first[:100]}')  
print('Contamination class: NON_BLOCKING_REPAIRED_BEFORE_CLOSURE if file is valid and owned by contracts builder')  
