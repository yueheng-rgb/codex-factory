# R2.3-J Tool Negative Controls Report

## 8 Negative Control Fixtures

| ID | Tool | Trigger | Expected | Actual | Pass |
|----|------|---------|----------|--------|:---:|
| NC-001 | Stitch MCP | No sandbox, no human | PENDING_SANDBOX | PENDING_SANDBOX | ✅ |
| NC-002 | GLM Search | No human approval | PENDING_HUMAN | PENDING_HUMAN | ✅ |
| NC-003 | DB MCP | No sandbox | PENDING_SANDBOX | PENDING_SANDBOX | ✅ |
| NC-004 | MAL-AUTOUPDATE | Quarantined status | REJECT | REJECT | ✅ |
| NC-005 | MAL-EXFIL | Rejected status | REJECT | REJECT | ✅ |
| NC-006 | OLD-LINT | Deprecated status | REJECT | REJECT | ✅ |
| NC-007 | UNKNOWN-999 | Not in registry | REJECT | REJECT | ✅ |
| NC-008 | CodeGen | No sandbox available | PENDING_SANDBOX | PENDING_SANDBOX | ✅ |

## Gate Correctly Blocks

- **Status-based**: quarantine, rejected, deprecated → all REJECT
- **Unknown tools**: Not registered → REJECT
- **Missing sandbox**: sandboxRequired tools without sandbox → PENDING_SANDBOX
- **Missing human approval**: humanConfirmationRequired without approval → PENDING_HUMAN
- **Missing secrets**: requiredSecrets without secretsAllowed → REJECT
- **Missing network**: networkAccess without networkAllowed → REJECT
- **Cross-agent**: agent not in allowedAgents → REJECT

## Conclusion

All 8 negative controls behave correctly. The permission gate prevents high-risk tools from executing without proper controls.
