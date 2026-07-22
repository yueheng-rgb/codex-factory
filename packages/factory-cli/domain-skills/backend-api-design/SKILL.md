---
name: backend-api-design
description: Design or implement consistent server APIs with validation, authorization, pagination, errors, and transaction boundaries. Use for backend routes, services, controllers, middleware, or API contracts.
---

<!-- >>> CODEX_APP_FACTORY:SKILL >>> -->
# Backend API design

- Keep request parsing at the route/controller boundary and business rules in services.
- Validate params, query, and body on the server; never trust client identity or role fields.
- Define request, success response, error response, status code, permission, and idempotency behavior per endpoint.
- Paginate list endpoints and support bounded filtering/sorting.
- Use one error envelope with stable machine codes and non-sensitive messages.
<!-- <<< CODEX_APP_FACTORY:SKILL <<< -->
