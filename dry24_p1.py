import json, os  
from datetime import datetime, timezone, timedelta  
ts = datetime.now(timezone(timedelta(hours=8))).isoformat()  
BASE = r'C:\Codex_App_Factory'  
FS = os.path.join(BASE, 'governance', 'factory-state')  
OUT = os.path.join(BASE, 'outputs')  
# A: State lock  
sf = os.path.join(FS, 'current-factory-state.json')  
state = json.load(open(sf, 'r', encoding='utf-8-sig'))  
state['dry24Status'] = 'BLOCKED_BY_CLOSURE_EVIDENCE_MISMATCH'  
state['dry24P1Status'] = 'IN_PROGRESS'  
state['dry24P1StartedAt'] = ts  
state['dry24ClosureRejectionReason'] = 'Complexity floor inflation (309 includes historical files), exports below 650 floor, cross-worker deps below 30 floor, cross-scope contamination unrepaired, negative evidence gaps'  
state['allowedNextPhase'] = 'LOCKED_PENDING_DRY24_P1'  
state['currentTrustedPhase'] = 'H17'  
state['updatedAt'] = ts  
json.dump(state, open(sf, 'w', encoding='utf-8'), indent=2, ensure_ascii=False)  
print('A: state locked - DRY24 BLOCKED_BY_CLOSURE_EVIDENCE_MISMATCH')  
