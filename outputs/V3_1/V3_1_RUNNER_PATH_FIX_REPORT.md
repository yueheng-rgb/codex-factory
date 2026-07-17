# Codex Factory V3.1 — Runner Path Fix Report

## Before (V3.0 Bug)

The V3.0 `execution-runner.ps1` used **relative paths** for `stdout_path`, `stderr_path`, and artifact paths:

```powershell
stdout_path = "workspaces/runs/$RunId/stdout.log"       # RELATIVE
stderr_path = "workspaces/runs/$RunId/stderr.log"       # RELATIVE
```

When the runner executed `Push-Location $execWorkDir` (into the sandbox workspace directory), these relative paths were resolved against the **new CWD**, resulting in **double nesting**:

```
C:\Codex_App_Factory\workspaces\runs\RUN-xxx\workspaces\runs\RUN-xxx\stdout.log
                                       ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
                                       DOUBLE NESTED!
```

## After (V3.1 Fix)

All paths are now resolved to **absolute** before `Push-Location`:

```powershell
$RepoRoot = (Get-Location).Path
$wsDirAbs = "$RepoRoot\workspaces\runs\$RunId"           # ABSOLUTE
$stdoutPathAbs = "$wsDirAbs\stdout.log"                   # ABSOLUTE
$stderrPathAbs = "$wsDirAbs\stderr.log"                   # ABSOLUTE
$runRecordPathAbs = "$artifactsDirAbs\run-record.json"    # ABSOLUTE
```

Output paths are now stable regardless of CWD changes:

```
C:\Codex_App_Factory\workspaces\runs\FIXFINAL-xxx\stdout.log  (correct)
C:\Codex_App_Factory\artifacts\runs\FIXFINAL-xxx\run-record.json  (correct)
```

## Additional Fixes

| Fix | Description |
|-----|-------------|
| Path resolution | All artifact/output paths now absolute (resolved from `$RepoRoot`) |
| `-LiteralPath` | Used for `Out-File` to avoid path interpretation issues |
| `-Exclude` removed | Sandbox copy now includes `node_modules` for full isolation |
| Stderr filtering | `Where-Object` correctly separates stdout from stderr |
| `-Force` flag | `Copy-Item` uses `-Force` to avoid prompts |

## Verification

- **FIXFINAL run**: exit_code=0, final_status=PASS, 23/23 tests, paths stable
- **No double nesting**: All paths resolve to correct absolute locations