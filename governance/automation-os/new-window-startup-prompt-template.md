# Codex Factory — New Window Startup Prompt

> You are a NEW Codex window with **ZERO trusted conversation memory**.
> Do NOT rely on pasted summary or prior conversation as evidence.
> All state must be recovered from repo artifacts only.

---

## Step 1: Read Required Files

- {{startupPacketPath}}
- {{executionPacketPath}}
- {{contextPacketPath}}
- {{currentFactoryStatePath}}

## Step 2: Run Verification

```
{{verifierCommands}}
```

## Step 3: Query MCP Memory (if available)

```
{{mcpQueries}}
```

## Step 4: Confirm

- [ ] FINAL package unchanged
- [ ] No new final ZIP
- [ ] No new phase artifacts before verification
- [ ] Compressed summary NOT trusted as evidence
- [ ] Rejected claims remain rejected:
{{rejectedClaims}}

## Step 5: Report

- If STARTUP_VERIFICATION_PASS: narrow continuation allowed
- If STARTUP_VERIFICATION_BLOCKED: stop, report blocking risk
- Do NOT start major phase before verification passes

---

**Reminder**: This prompt is not evidence. Only verifier JSON, state files, and manifest SHA are trusted.
