# FACTORY-AB-0 — C: Fair Prompt Design

**Timestamp:** 2026-06-28T17:30:00+08:00

---

## Design Principles

- Identical project requirements for both runs
- No Factory-specific instructions in vanilla prompt
- No hidden context leaked between runs
- Both runs start from clean session
- Identical success criteria

---

## Run Conditions

| | RUN-A (Vanilla) | RUN-B (Factory) |
|---|-----------------|-----------------|
| Factory installed | No | Yes |
| Build Lite | No | Yes |
| Security Gate | No | Yes |
| Package QA | No | Yes |
| Context Space | No | Yes |
| Test Repair Policy | No | Yes |

---

## Prompt Files

- `factory-ab/prompts/RUN_A_VANILLA_PROMPT.md` — standard Codex prompt
- `factory-ab/prompts/RUN_B_FACTORY_PROMPT.md` — Factory Build Lite prompt

---

**Status:** FAIR_PROMPTS_DESIGNED
