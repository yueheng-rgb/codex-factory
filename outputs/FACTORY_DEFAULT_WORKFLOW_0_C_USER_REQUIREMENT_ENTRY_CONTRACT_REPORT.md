# FACTORY-DEFAULT-WORKFLOW-0 — C: User Requirement Entry Contract Report

> Phase: FACTORY-DEFAULT-WORKFLOW-0
> Section: C — User Requirement Entry Contract
> Date: 2026-06-28

## Deliverables

| File | Path |
|------|------|
| Contract Definition | `factory-workflow/USER_REQUIREMENT_ENTRY_CONTRACT.md` |
| Governance JSON | `governance/factory-workflow/factory-default-workflow-0-user-requirement-entry-contract.json` |

## Contract Summary

Defines 9 Chinese and 6 English natural-language trigger phrases that automatically activate Factory mode. Also defines 3 auto-detection conditions based on Factory installation status, AGENTS.md references, and keyword detection.

### Trigger Categories
- **Explicit Factory triggers** (5 phrases): user directly requests Factory
- **Project request triggers** (4 phrases): user asks to build/create something
- **Auto-detection** (3 conditions): Factory installed + requirement given

### Expected Response
Factory Boot Summary format: project type, complexity, architecture, mode, multi-agent recommendation.

### Safety
- Non-trigger conditions prevent false activation
- Edge cases handled (folder switch, multiple triggers, pause)
