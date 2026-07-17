# AGENTS.md — Example fixture for CAP-SKILL-004 verification

## Build
Run `npm run build` to compile the project.

## Test
Run `npm test` to execute all test suites.
Run `npm run test:e2e` for end-to-end tests (requires Docker).

## Lint
Run `eslint src/ --ext .ts,.tsx` before committing.
Run `prettier --check src/` for formatting validation.

## Security
- Do not commit .env files or any file containing secrets
- All API routes must validate JWT via authMiddleware
- Passwords must use bcrypt with cost factor >= 12
- API keys must be stored in environment variables, never in source code

## Conventions
- Use kebab-case for all filenames
- Component files go in src/components/<ComponentName>/
- API route handlers go in src/api/<resource>/
- Database migrations in prisma/migrations/
- Use TypeScript strict mode throughout

## Handoff
- Implementer must produce build PASS evidence before handoff to Verifier
- Verifier must record test results in verification report
- Handoff format: projectId, phaseId, agentId, filesChanged, testResults, caveats

## Directory Rules
- /src/api/: All handlers must validate input with zod schemas
- /src/components/: All components must handle loading, empty, error, success states
- /prisma/: Migration files must not be edited manually after generation
