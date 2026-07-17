# SaaS Auto-Test Template

> Generic test patterns for SaaS/AI tool projects built with Codex App Factory.

## Client-Side Idempotency-Key Patterns

### Generating a Key

```ts
// Each NEW logical operation creates a fresh key
const idempotencyKey = crypto.randomUUID();
```

### Submitting with Key

```ts
const response = await fetch("/api/generate", {
  method: "POST",
  headers: {
    "Content-Type": "application/json",
    "Idempotency-Key": idempotencyKey,
  },
  body: JSON.stringify(payload),
});
```

### Retry Logic

```ts
// On network error or unknown result, RETAIN the same key for retry
try {
  const response = await fetch("/api/generate", { ... });
  if (!response.ok && response.status !== 409) {
    // Server error — keep key for possible retry
    throw new Error("Server error");
  }
  // Success — clear the key (operation complete)
  idempotencyKey = null;
} catch (networkError) {
  // Network failure — keep key, user can retry same operation
  // Do NOT generate a new key
}
```

### New Operation = New Key

```ts
// User explicitly starts a NEW generation → create new key
function onNewGeneration() {
  idempotencyKey = crypto.randomUUID();
  // submit with this key
}

// Retry the SAME generation after failure → reuse key
function onRetry() {
  // idempotencyKey is still set from the failed attempt
  // submit with the SAME key
}
```

### Key Lifecycle

1. **Created**: When user initiates a new logical operation
2. **Retained**: On network error, 5xx, or GENERATION_FAILED — keep for retry
3. **Cleared**: On successful response (2xx) or IDEMPOTENCY_CONFLICT (409) — operation complete
4. **Not reused**: Never reuse a key across different logical operations

## Cross-User Isolation Assertions

Test suites MUST include these assertions in the final `ok` condition:

```ts
// Cross-user idempotency: same raw key, different users → independent
const sharedKey = crypto.randomUUID();

// User B generates with sharedKey
const bResult = await apiGenerate(sharedKey, genBody, userBCookie);
// User A generates with SAME sharedKey (must be independent, not cached from B)
const aResult = await apiGenerate(sharedKey, genBody, userACookie);

// BOTH assertions must be part of the PASS condition
const ok = bResult.status === 200 &&
           aResult.status === 200 &&
           bResult.json.data.id !== aResult.json.data.id &&  // different generation IDs
           bResult.json.data.remaining < initialBQuota &&      // B's quota deducted
           aResult.json.data.remaining < initialAQuota;       // A's quota deducted

// History isolation
const bHistory = await apiHistory(userBCookie);
const aHistory = await apiHistory(userACookie);
const bItems = bHistory.json.data.items;
const aItems = aHistory.json.data.items;

// A MUST not see B's records and vice versa
const historyIsolated = bItems.every(item => item.userId === userBId) &&
                        aItems.every(item => item.userId === userAId);
```

## Test Naming Rules

- T16 (or last test): If server restart is NOT actually performed, name it "Mock storage implementation confirmed" — never claim "reset verified"
- Any test that requires actual server restart must include the restart steps in the test code
- Tests that use `sleep()` must use real delays (not fake "instant" responses)

## Transcript Requirements

- Every HTTP request MUST be logged with real status codes and response bodies
- No placeholders (`<UUID>`, `...`, etc.)
- Timestamps must be generated at call time, not hardcoded
- Line count must match actual HTTP call count
