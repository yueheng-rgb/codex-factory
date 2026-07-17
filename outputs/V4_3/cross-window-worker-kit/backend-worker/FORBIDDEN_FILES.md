# Forbidden Files

DO NOT modify:
- src/*/auth* (any auth-related files)
- config/secrets*
- Other workers' directories (src/worker-frontend/, src/worker-qa/)
- Root configuration files (factory.config.json, package.json)
- Any file that matches these patterns

Violations will be caught by handoff validation and WILL block integration.
