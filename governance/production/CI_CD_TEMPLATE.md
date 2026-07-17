# CI/CD Template Guide
# Codex Factory R6.0

## Supported Templates

- `ci-templates/github-actions-node.yml` — GitHub Actions for Node.js/TypeScript

## Pipeline Stages

1. **Install** — `npm ci` for reproducible installs
2. **Typecheck** — `npx tsc --noEmit`
3. **Test** — `npm test` with Postgres service container
4. **Build** — `npm run build`
5. **Security Scan** — semgrep auto config
6. **Load Smoke** — autocannon on /health (optional, continue-on-error)
7. **Production Readiness Check** — Codex Factory checker
8. **Artifact Upload** — test results, semgrep output

## Customization

- Change `node-version` to match project requirements
- Add `NODE_ENV` and other env vars
- Add Docker build/push steps for containerized deployment
- Add Vercel/Netlify/Railway deploy steps

## Non-Claims

- This template does NOT guarantee production safety
- Local load smoke does NOT represent production traffic
- Security scan is a static baseline — not a penetration test
