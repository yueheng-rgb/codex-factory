---
name: auth-permission-security
description: Design or review authentication, authorization, secret handling, and sensitive operations. Use for login, registration, roles, permissions, tokens, API keys, or mobile/miniapp identity.
---

<!-- >>> CODEX_APP_FACTORY:SKILL >>> -->
# Auth and permission security

- Enforce authorization on the server for every protected operation; UI hiding is not authorization.
- Store passwords with Argon2 or bcrypt and keep keys/secrets only in server-side environment storage.
- Define token/session expiry, refresh, revocation, logout, disabled-account behavior, and rate limits.
- Default to admin-created accounts unless open registration is explicitly required.
- Test unauthenticated, wrong-role, cross-owner, replay, duplicate, expired-token, and secret-leak paths.
<!-- <<< CODEX_APP_FACTORY:SKILL <<< -->
