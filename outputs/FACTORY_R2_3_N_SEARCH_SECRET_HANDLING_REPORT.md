# R2.3-N Search Secret Handling Report

## Policy

API keys for external search providers MUST come from environment variables only. They MUST NEVER appear in:
- .env files in packages
- Source code or configuration files
- Output reports (outputs/)
- Governance ledgers (governance/)
- Log files
- Search invocation records

## Implementation

### Secret Presence Check (untime/secret-presence-check.ps1)
- Test-SecretPresence checks env vars without exposing value
- Returns: secretPresent: true/false, envVarFound (name only), keyLength (integer only)
- keyValueRecorded is always alse

### Leak Detection
- Assert-NoSecretLeak scans content for key-like patterns
- Detects: pi_key=..., secret=..., 	oken=..., provider-specific patterns
- Used as pre-write gate for output files

### Ledger Policy
Search invocation ledger records ONLY:
- secretPresent: true/false
- 
etworkBoundary
- humanApproval: true/false
- NEVER: key value, key prefix, key hash, key length

### Missing Key Behavior
If live_api is requested but no API key found:
1. Adapter auto-downgrades to dry_run mode
2. Ledger records DOWNGRADED_TO_DRY_RUN
3. No error returned to caller
4. Caveat added: "live_api downgraded to dry_run: API key not found"

## Verification
- 32/32 PASS including "no API key in recent outputs" scan
- Secret leak detection confirmed working (detects test pattern)
- All ledger entries verified: secretPresent boolean only, no key data
