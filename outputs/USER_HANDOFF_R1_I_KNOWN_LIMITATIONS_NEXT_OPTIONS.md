# USER-HANDOFF-R1 — I: Known Limitations & Next Options

## Known Limitations
1. **Not yet real-project validated** after R1 integration — all evidence is fixture/smoke level
2. **CLI canonical name** (`factory.ps1`) is a target; current entry is `factoryctl.ps1`
3. **Dashboard/recovery/evidence scripts** are fixture-level prototypes — may need real-use hardening
4. **Multi-agent runtime integration** depends on Codex platform capabilities — policies and schemas defined, execution is platform-dependent
5. **Cloud deferred** — no update distribution, no remote checks
6. **v0.6 not started** — feature expansion awaits real feedback
7. **Production deployment out of scope** — Security Gate is safety check only
8. **Native Build Pro still conditional** — not defaulted

## Next Options

### 1. Pause and use R1 on next real project
Best option if you have a suitable project coming up. Gather real feedback before next iteration.

### 2. FACTORY-REAL-VALIDATION-READINESS-0
Formal readiness assessment before broad real validation. Verifies that governance, smoke, and handoff artifacts are sufficient to support real project trials.

### 3. First R1 real project usage trial
Pick a controlled project, run it through R1 Factory, and document findings.

### 4. R1 repair pass
If handoff reveals any issues, run V05-R1-REPAIR.

### 5. Defer v0.6
Wait for real feedback before planning v0.6 features.

## Recommendation
**FACTORY-REAL-VALIDATION-READINESS-0** before broad real validation, or pause and use R1 on next suitable project.
