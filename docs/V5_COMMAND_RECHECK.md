# Command Recheck Policy

New verification receipts use `acceptance-recheck-v2`. Existing unversioned and
`rg-files-v1` receipts keep their original interpretation, including FAIL. Reading
an old run never reruns commands, rewrites handoffs or upgrades its verdict.

## Recovery Boundary

A reported nonzero exit can be labeled `RECHECK_PASSED` only when:

- It is an integer exit code from 1 through 125, not a missing executable,
  signal-style exit or malformed result.
- The complete command, apart from surrounding whitespace, exactly matches a
  `command:` or `cmd:` acceptance method in the authoritative task contract.
- The controller executes that contract's acceptance checks after both handoffs.
  Every matching method passes with exit zero and stored output digests.
- Receipt reads recompute the classification and verify the referenced stdout
  and stderr log bytes. Missing or modified recheck logs fail closed.

The original handoff and nonzero exit remain intact. Independent verifier PASS,
all current acceptance checks and physical artifact checks are still required.
Artifact hashes are checked after acceptance execution, so a successful test
cannot silently replace the delivered bytes. A successful recheck is evidence
of current acceptance only, not proof that a flaky test is now reliable.

Unrelated diagnostics cannot borrow a passing check. Compound commands and shell
wrappers are not treated as aliases. Self-declared expected exits, phases and
parent-command fields do not authorize recovery. No reported command is rerun
unless it is already an executable acceptance method in the approved task.

## Reporting Negative Tests

`commands` describes actual direct top-level invocations. A negative test should
assert its expected child exit inside a parent test that exits zero only when the
assertion holds. Report the parent's actual exit; describe asserted child results
in caveats instead of duplicating them as separately invoked commands. This is
not permission to omit a directly executed command that failed.

Use an existence predicate for optional files, and check repository availability
before Git diagnostics. An unknown nonzero diagnostic still blocks acceptance;
only the pre-existing narrowly parsed `rg --files` no-match exception remains.

## Verification Scope

Regression tests execute actual local commands through Worker/Verifier fixtures,
exercise Context Space on/off, preserve original failures, reject unrelated and
current failures, and detect changed artifacts or altered recheck evidence.
Fixture native IDs are not live Agent measurements. Separate fresh native runs
are required before claiming the updated workflow has worked on the host.

These are local control-plane integrity checks, not cryptographic host
attestations or OS isolation. Hook trust and formal release remain separate gates.
