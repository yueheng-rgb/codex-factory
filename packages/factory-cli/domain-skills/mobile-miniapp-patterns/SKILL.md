---
name: mobile-miniapp-patterns
description: Design or implement mobile, H5, React Native, Expo, uni-app, or WeChat miniapp flows. Use for navigation, secure login, weak-network behavior, safe areas, or mobile API integration.
---

<!-- >>> CODEX_APP_FACTORY:SKILL >>> -->
# Mobile and miniapp patterns

- Design for one primary action per screen, shallow navigation, safe areas, and thumb-reachable controls.
- Keep provider secrets and code-to-session exchanges on the server; store only scoped tokens in secure client storage.
- Centralize API calls, timeouts, typed errors, refresh behavior, retry rules, and offline messaging.
- Test cold start, expired login, slow/offline networks, repeated taps, interrupted navigation, and small screens.
- Do not compress a desktop sidebar/table workflow into a mobile layout.
<!-- <<< CODEX_APP_FACTORY:SKILL <<< -->
