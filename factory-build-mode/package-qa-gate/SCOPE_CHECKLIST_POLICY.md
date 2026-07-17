# Package QA Gate — Scope, Checklist & Policy

---

## SCOPE

### IN SCOPE (checked by gate)
- Process trace residue (GPT, Codex, Factory, prompt leakage)
- Assignment profile conformance (name, ID, naming)
- Required artifact presence (report, source, SQL, README)
- Technical correctness (syntax, library/platform mismatches, schema)
- Structural hygiene (cache files, secrets, extraction)
- ZIP integrity and extractability

### OUT OF SCOPE (not checked by gate)
- Product functional correctness (does the app work?)
- Business logic validation
- UI/UX quality assessment
- Performance benchmarking
- Security vulnerability scanning (separate Security Gate)
- Code review quality
- Test coverage adequacy
- Architecture/design review

### BOUNDARY RULES
- Gate checks the PACKAGE, not the running application
- Gate is a DELIVERY check, not a development check
- Gate does not replace build verification, testing, or code review
- Gate is the LAST checkpoint before handoff

---

## CHECKLIST (Quick Reference)

### BLOCKING (must pass)
- [ ] No GPT/ChatGPT/OpenAI residue in delivered files
- [ ] No Codex/Codex CLI/Factory residue in delivered files
- [ ] No prompt/instruction text leaked
- [ ] Author name matches assignment profile
- [ ] Author ID matches assignment profile
- [ ] ZIP filename matches expected format
- [ ] Report/document file present
- [ ] Source code directory present
- [ ] SQL file present (DB projects only)
- [ ] No Python syntax errors
- [ ] No library/platform mismatches
- [ ] No `.env` with real secrets
- [ ] ZIP extracts cleanly

### WARNING (should review)
- [ ] Project name matches expected
- [ ] README present
- [ ] Screenshot references resolve
- [ ] No `__pycache__` or `.pyc` files
- [ ] No `node_modules` in package
- [ ] No `venv/` in package
- [ ] ZIP size reasonable
- [ ] JS/TS syntax clean (if applicable)

### INFO (note only)
- [ ] Check categories that passed
- [ ] Check duration
- [ ] Package size

---

## POLICY

### When to Run
1. Before ANY final ZIP handoff to user
2. Before ANY project submission package delivery
3. Before ANY experiment report package delivery
4. Before ANY source code package delivery to external recipient

### Who Runs It
- Codex agent as part of final delivery workflow
- Can also be run manually by user: `.\package-qa-check.ps1 -PackagePath <path>`

### What Happens on BLOCKED
1. Report findings with specific file paths and line numbers
2. Do NOT modify package (read-only gate)
3. Offer repair options:
   - Auto-repair for simple issues (cache cleanup, syntax fixes)
   - Manual repair for content issues (residue removal, profile mismatch)
4. Re-run gate after repair
5. Only handoff when PASS or PASS_WITH_WARNINGS

### Exceptions
- User may override BLOCKING findings with explicit approval
- Override must be documented in delivery record
- "PASS_WITH_OVERRIDE" status recorded

### Gate Self-Integrity
- Gate script must be versioned
- Gate must report its own version in output
- Gate must not modify itself
- Gate failures (ERROR status) must be investigated before package delivery
