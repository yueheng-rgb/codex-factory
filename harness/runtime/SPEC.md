# Phase 6C-A Specification — valid-minimal-app

## Project

**Name**: valid-minimal-app
**Type**: TypeScript + HTML single-page app
**Canonical path**: `C:\Codex_App_Factory\harness\tests\fixtures\valid-minimal-app`

## Tasks

### T-001: Create App Module

- **File**: `src/app.ts`
- **Role**: builder-agent
- **Dependencies**: None
- **Acceptance (AC-T-001)**: File exists at `src/app.ts`, is valid TypeScript, exports an `App` class with:
  - `version: string` property (value: `"1.0.0"`)
  - `init(): void` method that logs `"App initialized v<version>"`
- **Example**:
```typescript
export class App {
  version = "1.0.0";
  init(): void {
    console.log(`App initialized v${this.version}`);
  }
}
```

### T-002: Create Utility Module

- **File**: `src/utils.ts`
- **Role**: builder-agent
- **Dependencies**: None
- **Acceptance (AC-T-002)**: File exists at `src/utils.ts`, is valid TypeScript, exports:
  - `formatDate(date: Date): string` — returns ISO date string `YYYY-MM-DD`
  - `uuid(): string` — returns a random UUID v4 string
- **Example**:
```typescript
export function formatDate(date: Date): string {
  return date.toISOString().split("T")[0];
}

export function uuid(): string {
  return "xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx".replace(/[xy]/g, (c) => {
    const r = (Math.random() * 16) | 0;
    const v = c === "x" ? r : (r & 0x3) | 0x8;
    return v.toString(16);
  });
}
```

## Acceptance Criteria Summary

| ID | Task | Requirement |
|----|------|-------------|
| AC-T-001 | T-001 | `src/app.ts` exists, valid TS, exports App class with version + init() |
| AC-T-002 | T-002 | `src/utils.ts` exists, valid TS, exports formatDate() + uuid() |

## Completion Gate

- Both tasks `candidate_complete`
- Post-integration typecheck passes
- `validate-state.ps1` returns PASS
- Hash chain unbroken
- 2 distinct agent_id values with overlapping execution windows in RUN_STATE.jsonl