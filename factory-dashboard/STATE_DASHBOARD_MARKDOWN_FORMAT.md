# STATE_DASHBOARD_MARKDOWN_FORMAT.md

> Part of: FACTORY-STATE-DASHBOARD-0
> Section: D — Markdown Dashboard Format
> Version: 1.0.0

---

## Purpose

Define the human-readable Markdown format for `factory state` output. Must be scannable in a terminal.

---

## Format Specification

### Section 1: Project Identity
```markdown
## 🏷 Project: {projectName}
- **ID:** {projectId}
- **Status:** {projectStatus} {healthIndicator}
- **Root:** {rootPath}
```

### Section 2: Current Phase
```markdown
## 📋 Phase
- **Current:** {currentPhase} {healthIndicator}
- **Last Close:** {lastPhaseClose}
- **Latest Verifier:** {latestVerifier.verdict} ({latestVerifier.timestamp})
- **Latest Report:** {latestPhaseReport}
```

### Section 3: Mode & Multi-Agent
```markdown
## ⚙ Mode
- **Build Mode:** {buildMode}
- **Multi-Agent:** {multiAgentState} ({multiAgentDecision})
```

### Section 4: Blockers & Risks
```markdown
## 🚨 Blockers & Risks
### Blockers ({blockerCount})
- {blocker.description} {healthIndicator}

### Risks ({riskCount})
- {risk.description} {healthIndicator}
```

### Section 5: Paths
```markdown
## 📁 Paths
- **Working Copy:** {workingCopyPath}
- **Factory Install:** {factoryInstallPath}
- **External Space:** {externalConversationSpacePath}
- **Governance:** {governancePath}
- **Outputs:** {outputsPath}
```

### Section 6: Gates
```markdown
## 🛡 Gates
{enabledGates list}
```

### Section 7: Memory & Context
```markdown
## 🧠 Memory & Context
- **Memory:** {memoryStatus} {healthIndicator}
- **Mount:** {mountStatus summary}
- **Cleanup:** {cleanupStatus summary} {healthIndicator}
```

### Section 8: Agent Ledger
```markdown
## 🤖 Agent Ledger
- **Entries:** {entryCount}
- **Last Activity:** {lastActivityTimestamp}
- **Agents:** {agentRoles list}
```

### Section 9: Warnings
```markdown
## ⚠ Warnings
### Foreign Context ({foreignCount})
- {warning}

### Stale ({staleCount})
- {warning}

### Missing Evidence ({missingCount})
- {warning}
```

### Section 10: Next Action
```markdown
## ▶ Next
{nextRecommendedAction}
```

---

## UNKNOWN_WITH_REASON Format

When a path or value is unknown:
```
- **Field:** UNKNOWN_WITH_REASON: {explanation}
```

Never omit a field silently.

---

## Template

See: `factory-dashboard/templates/state-dashboard.template.md`
