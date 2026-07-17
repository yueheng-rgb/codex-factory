# FACTORY-BUILD-REALWORLD-2-R1-B: Cross-Window Memory Contamination Report

**Date**: 2026-06-27
**Phase**: R1-B — Cross-Window Memory Contamination Note

---

## 1. Core Statement

**A new Codex window is NOT a guaranteed clean experimental baseline.**

Multiple contamination vectors exist across Codex windows within the same user account. Any comparison between "Factory-assisted" and "vanilla Codex" runs must acknowledge and document these vectors.

## 2. Contamination Types

### Type 1: User-Level Memory Contamination
- **Vector**: User account preferences, custom instructions, global rules (AGENTS.md files)
- **Example**: `C:\Codex_App_Factory\GLOBAL_CODEX_RULES.md` applies to all windows
- **Impact**: Vanilla Codex window may still inherit safety rules about secret masking

### Type 2: Project-Level Context Contamination
- **Vector**: Shared file paths, workspace awareness, prior project exposure
- **Example**: The path `C:\Users\90961\Documents\Codex\2026-06-10\files-mentioned-by-the-user-txt` is known across windows
- **Impact**: A "new" window still knows the project exists; file system familiarity persists

### Type 3: Prompt Leakage
- **Vector**: User prompts in one window may reference work done in another
- **Example**: User saying "continue from where we left off" implicitly carries context
- **Impact**: Instructions from Factory window bleed into vanilla window

### Type 4: File Path / Project Name Familiarity
- **Vector**: Directory names, project structure knowledge persists
- **Example**: Knowing it's a "Django project with deploy scripts" before opening it
- **Impact**: Pre-existing expectations shape analysis

### Type 5: Prior Risk Awareness Leakage
- **Vector**: Having already seen the risks in one window, user may inadvertently hint
- **Example**: Asking "check for hardcoded passwords" instead of "inspect this project"
- **Impact**: Vanilla Codex gets directed toward known findings

### Type 6: Assistant Guidance Contamination
- **Vector**: Model-level memory or context retention across sessions
- **Example**: Long-term assistant memory may recall prior interactions about this project
- **Impact**: Assistant behavior may be influenced by past conversations

## 3. Implications for REALWORLD-2

| Implication | Severity |
|------------|----------|
| REALWORLD-2 intake cannot be claimed as "independent verification" | HIGH |
| No comparison to vanilla Codex was performed | HIGH |
| Safety process worked, but reasoning advantage is unmeasured | MEDIUM |
| Future comparisons must be contamination-aware | HIGH |
| Strict scientific isolation is impractical in shared account | MEDIUM |

## 4. Future Isolation Rules (If Comparison is Attempted)

| Rule | Purpose |
|------|---------|
| Use separate Codex user accounts | Eliminate Type 1 contamination |
| Fresh file system path / renamed project | Eliminate Type 2, 4 |
| Identical neutral prompt in both windows | Eliminate Type 3 |
| No prior risk discussion in either window | Eliminate Type 5 |
| Fresh session, no long-term memory carryover | Eliminate Type 6 |
| Both windows must have same secret/deploy safety rules | Safety floor |

## 5. Acknowledgement

This REALWORLD-2-R1 phase itself is NOT contamination-free. It was conducted in the same Codex window that performed REALWORLD-2 intake. The correction is honest about its own limitations.

## 6. Phase R1-B Status: COMPLETE
