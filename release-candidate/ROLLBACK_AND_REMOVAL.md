# Rollback and Removal Instructions

## If the RC is distributed

1. Delete the extracted directory
2. Remove any PATH entries referencing factoryctl
3. Remove $env:CODEX_FACTORY_REPO if set
4. Archive but do not delete original governance state

## If final ZIP was created

1. Delete the .zip file
2. Verify no references to extracted path remain
3. Revert current-factory-state.json to pre-ZIP state
4. Set finalZipExists = false

## Rollback Evidence

- No database was created
- No system registry entries were made
- No services were installed
- All changes are file-system only

## Safety

- RC is READONLY by design — no mutations outside its directory
- Plugin is EXPERIMENTAL — no production dependency should exist
- Monitoring is prototype — no scheduled jobs should reference it
