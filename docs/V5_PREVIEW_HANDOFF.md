# V5 Preview Handoff

Package: `@codex-app-factory/cli@5.0.0-preview.1`.
Verified source: `14684e78d2a5611bacb50c8ab5d20670fc2b9e8f`.
[GitHub Actions run 34944225959](https://github.com/yueheng-rgb/codex-factory/actions/runs/34944225959)
completed successfully on 2026-09-15 UTC. Documentation-only changes after this
snapshot do not replace its package provenance.

## Evidence

| Check | Windows / Node 24 | Ubuntu / Node 24 |
| --- | --- | --- |
| Unit and integration tests | 202 passed, 0 failed | 201 passed, 0 failed, 1 Windows-only test skipped |
| Source and evaluation type checks | Passed | Passed |
| Build and package-content audit | Passed | Passed |
| Offline tarball install and installed command | Passed | Passed |
| Repeatable initialization, 9 domain Skills, SQLite integrity | Passed | Passed |

The separate Windows legacy compatibility job also passed. The earlier run
34843750872 failed 12 teaching-related tests because Windows drive-letter casing
made equivalent repository paths compare unequal. Commit `768be48` uses native
path resolution and adds positive and negative regression tests. The failed run
remains part of the history.

Both CI packages were downloaded and independently checked against their
`result.json`: source commit matched, source worktree was clean, and both tarball
SHA-256 values were
`ca69e0591b4512641ed3fae87f821198f2a63879abfedd5297ce418c89d6c6cc`.
The downloaded Windows package also installed offline and reported the expected
version locally. This byte equality is observed for this snapshot, not promised
for all future cross-platform builds.

Package smoke runs with multi-agent and external search disabled. Its Doctor
status is `READY_WITH_LIMITATIONS`; it does not establish trusted Hook delivery,
live Agent completion, model compatibility, or performance improvements.

## Build And Install

The linked CI run retains two `factory-cli-v5-<os>-<commit>` artifacts for 30 days.
Each contains only the tested `.tgz` and `result.json`. Download requires GitHub
access; these are temporary preview artifacts, not a permanent public release.
With authenticated GitHub CLI, from the repository root:

```powershell
gh run download 34944225959 --dir dist/v5-preview-14684e7/ci-artifacts
```

Use Node.js 24+, npm and Git. In a checkout of the source revision being tested:

```powershell
Set-Location C:\Codex_App_Factory\packages\factory-cli
npm ci
npm run typecheck
npm run eval:typecheck
npm test
npm run test:package
```

`test:package` builds and installs a real `.tgz` into a temporary consumer project.
It prints the directory containing the package and `result.json`, including its
SHA-256, source commit, source-worktree cleanliness and generation time. Retain
those exact bytes with their test evidence. This command uses
source-only test scripts; it is not a command supplied by the installed package.

Install a verified local `.tgz` into a dedicated tool directory:

```powershell
$toolRoot = 'C:\Tools\factory-v5-preview'
$packageFile = 'C:\path\to\codex-app-factory-cli-5.0.0-preview.1.tgz'
New-Item -ItemType Directory -Force -Path $toolRoot | Out-Null
npm install --prefix $toolRoot --offline --ignore-scripts --omit=dev --no-audit --no-fund $packageFile
& "$toolRoot\node_modules\.bin\factoryctl.cmd" --help
```

Initialize an existing target project with that installed command, then run
`doctor`. See the [Chinese installation guide](CONTROL_PLANE_V5_GUIDE.zh-CN.md)
for feature settings and the host's Hook trust step. Keep the tool directory in
place while its installation is in use. On Unix, the corresponding executable is
`<toolRoot>/node_modules/.bin/factoryctl`.

The manifest remains `private: true`; no registry release or version tag was
created. Source tarballs generated on different platforms are tested separately;
this record does not claim their byte hashes are identical. Subsequent source
changes require their own verification.

Formal release remains deferred. See the [release decision](V5_RELEASE_DECISION.md)
and [native evaluation outcomes](V5_NATIVE_EVALUATION_INDEX.md): passing package
tests does not mean every native Factory workflow passed.
