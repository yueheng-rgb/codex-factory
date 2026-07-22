# Legacy V4 artifact warning

Status: **INVALID — archive/audit use only**

Do not install, publish, mirror, or cite `codex-factory-v4-capability-package.zip` as evidence for the current repository.

## Why it is invalid

The files next to the ZIP do not describe one consistent immutable artifact. Observed in this workspace on 2026-07-22:

| Record | Archive size asserted (bytes) | Archive SHA-256 asserted |
|---|---:|---|
| Physical `codex-factory-v4-capability-package.zip` | 9,009,474 | `97C09BBFD5036E857A9EBB7F90641B87DF091971E32F8CEB578A72B4693775BF` |
| Values declared inside `codex-factory-v4-capability-package.manifest.json` (manifest file itself is 791 bytes) | 81,545 | `CD6F9D996B6CA06028DDCBF870D71A262A8C6159E63855E5A77D7677E048753E` |
| Value declared by `codex-factory-v4-capability-package.sha256.txt` (sidecar file itself is 64 bytes) | not recorded | `CD6F9D996B6CA06028DDCBF870D71A262A8C6159E63855E5A77D7677E048753E` |

The release-notes hash happens to match the current physical ZIP, but the conflicting manifest and checksum sidecar mean this directory does not provide a single trustworthy release identity. A matching hash in one text file cannot repair contradictory release metadata or prove which payload was intended.

The ZIP is retained so the mismatch remains auditable. Its presence is not a PASS and its contents are not the current installation source.

## Current authoritative path

Use the V5 Preview source at [`packages/factory-cli`](../packages/factory-cli/) and the [V5 installation guide](../docs/CONTROL_PLANE_V5_GUIDE.zh-CN.md). To create a reproducible package candidate from the exact checkout being tested:

```powershell
Set-Location C:\Codex_App_Factory\packages\factory-cli
npm ci
npm run typecheck
npm test
npm run build
npm pack --dry-run
npm pack
```

Record the current Git commit, the generated `.tgz` SHA-256, and the current Windows/Ubuntu CI run together. A package or PASS report from another commit does not certify current HEAD.
