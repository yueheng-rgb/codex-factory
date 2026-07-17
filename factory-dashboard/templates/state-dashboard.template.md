## 🏷 Project: {{projectName}}
- **ID:** {{projectId}}
- **Status:** {{projectStatus}} {{statusHealth}}
- **Root:** {{rootPath}}

## 📋 Phase
- **Current:** {{currentPhase}} {{phaseHealth}}
- **Last Close:** {{lastPhaseClose}}
- **Latest Verifier:** {{latestVerifierVerdict}} ({{latestVerifierTimestamp}})
- **Latest Report:** {{latestPhaseReport}}

## ⚙ Mode
- **Build Mode:** {{buildMode}}
- **Multi-Agent:** {{multiAgentState}}

## 🚨 Blockers & Risks
### Blockers ({{blockerCount}})
{{#blockers}}
- {{description}} {{health}}
{{/blockers}}
{{^blockers}}
- ✅ None
{{/blockers}}

### Risks ({{riskCount}})
{{#risks}}
- {{description}} {{health}}
{{/risks}}
{{^risks}}
- ✅ None
{{/risks}}

## 📁 Paths
- **Working Copy:** {{workingCopyPath}}
- **Factory Install:** {{factoryInstallPath}}
- **External Space:** {{externalConversationSpacePath}}
- **Governance:** {{governancePath}}
- **Outputs:** {{outputsPath}}

## 🛡 Gates
{{#enabledGates}}
- {{name}}
{{/enabledGates}}
{{^enabledGates}}
- ⚪ No gates enabled
{{/enabledGates}}

## 🧠 Memory & Context
- **Memory:** {{memoryStatus}} {{memoryHealth}}
- **Mount:** {{mountSummary}}
- **Cleanup:** {{cleanupSummary}} {{cleanupHealth}}

## 🤖 Agent Ledger
- **Entries:** {{agentEntryCount}}
- **Last Activity:** {{agentLastActivity}}
- **Agents:** {{agentRoles}}

## ⚠ Warnings
### Foreign Context ({{foreignCount}})
{{#foreignWarnings}}
- {{description}}
{{/foreignWarnings}}
{{^foreignWarnings}}
- ✅ None
{{/foreignWarnings}}

### Stale ({{staleCount}})
{{#staleWarnings}}
- {{description}}
{{/staleWarnings}}
{{^staleWarnings}}
- ✅ None
{{/staleWarnings}}

### Missing Evidence ({{missingCount}})
{{#missingWarnings}}
- {{description}}
{{/missingWarnings}}
{{^missingWarnings}}
- ✅ None
{{/missingWarnings}}

## ▶ Next
{{nextRecommendedAction}}
