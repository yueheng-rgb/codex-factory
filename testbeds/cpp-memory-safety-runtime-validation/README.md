# C/C++ Memory Safety Runtime Validation Testbed

Part of Codex Factory v2.4: Runtime Validation Batch for New Expert Packs.

## Purpose

Validates the `cpp-memory-safety` expert pack invariants through:
1. **Source code pattern detection** — scans mock C/C++ files for unsafe patterns
2. **Concept-level invariant validation** — tests that invariants correctly identify dangerous patterns
3. **Tool availability detection** — honestly reports which tools (g++, clang, ASan, UBSan, Valgrind) are available
4. **Negative controls** — verifies that unsafe patterns are correctly caught

## What this testbed IS

- A validation testbed for memory safety invariants
- A concept-level check that the pack rules are coherent and testable
- An honest tool availability reporter

## What this testbed IS NOT

- It does NOT compile or run real C/C++ code (no compiler available)
- It does NOT perform live ASan/UBSan/Valgrind instrumentation
- It does NOT claim production C/C++ safety validation
- The mock .c/.cpp files are for code-review pattern matching only

## Start / Test Commands

```bash
# Install dependencies
npm install

# Run all validation tests
npm test

# Check C/C++ tool availability
npm run tool-check

# TypeScript typecheck
npm run build
```

## Test Coverage

| Invariant | Description | Validation Method |
|-----------|-------------|-------------------|
| CPP-001 | buffer_bounds_must_be_checked | Mock + concept |
| CPP-002 | use_after_free_must_be_prevented | Mock + concept |
| CPP-003 | null_pointer_dereference_must_be_prevented | Mock + concept |
| CPP-004 | double_free_must_be_prevented | Concept |
| CPP-005 | integer_overflow_in_allocation_must_be_prevented | Mock + concept |
| CPP-006 | format_string_vulnerability_must_be_prevented | Concept |
| CPP-007 | file_parser_must_be_bounded | Mock + concept |
| CPP-008 | sanitizer_toolchain_integration_required | Tool check |
| CPP-009 | thread_safety_if_multithreaded | Concept |
| CPP-010 | undefined_behavior_must_be_documented_or_fixed | Concept |
| NEGATIVE | 5 negative controls | All active |

## Tool Availability (current host)

| Tool | Status |
|------|--------|
| g++ | TOOL_UNAVAILABLE |
| clang | TOOL_UNAVAILABLE |
| cmake | TOOL_UNAVAILABLE |
| ASan | TOOL_UNAVAILABLE (requires compiler) |
| UBSan | TOOL_UNAVAILABLE (requires compiler) |
| TSan | TOOL_UNAVAILABLE (requires compiler) |
| Valgrind | TOOL_UNAVAILABLE (not installed) |
