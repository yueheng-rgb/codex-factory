# Drift Types Reference
> Part of: FACTORY-R2.1-INFRA-MVP / Drift Check MVP
> Version: 1.0.0

## Drift Type Catalog

### SCOPE_CREEP
- **Description**: Features or capabilities added beyond original scope
- **Detection**: Compare current codebase against PIC and NGC
- **Example**: Adding payment module when PIC says "no payment in v1"
- **Severity**: MEDIUM (unless it introduces security/compliance risk)
- **Resolution**: ACCEPT (update contract) or REJECT (remove)

### SCOPE_SHRINK
- **Description**: Core features from PIC not implemented
- **Detection**: Compare implemented features against PIC success criteria
- **Example**: PIC says "3 user roles" but only 1 implemented
- **Severity**: HIGH
- **Resolution**: Implement missing features or update PIC

### ARCHITECTURE_DRIFT
- **Description**: System architecture deviates from AC
- **Detection**: Compare module structure, API design against AC
- **Example**: Monolith designed but microservices pattern emerging
- **Severity**: HIGH
- **Resolution**: Revert to AC or update AC with rationale

### TECHNOLOGY_DRIFT
- **Description**: Technology choices change from AC
- **Detection**: Compare package.json, config files against AC techStack
- **Example**: PostgreSQL in AC but SQLite found in codebase
- **Severity**: HIGH
- **Resolution**: Revert or document intentional change

### COMPLEXITY_COLLAPSE
- **Description**: Architecture simplified beyond what contract specifies
- **Detection**: AC specifies patterns not found in implementation
- **Example**: RBAC with 3 roles simplified to single admin check
- **Severity**: HIGH
- **Resolution**: Restore complexity or downgrade contract

### COMPLEXITY_EXPLOSION
- **Description**: Unnecessary complexity added beyond contract
- **Detection**: Patterns/frameworks not in AC found in codebase
- **Example**: S project adding Redis, message queue, microservices
- **Severity**: HIGH
- **Resolution**: Remove unnecessary complexity

### SECURITY_BOUNDARY_DRIFT
- **Description**: Security boundaries weakened from contract
- **Detection**: Auth checks, data access patterns vs AC
- **Example**: Server-side auth becomes client-side only
- **Severity**: CRITICAL
- **Resolution**: Immediate fix required

### EVIDENCE_OVERCLAIM
- **Description**: Agent claims completion but evidence is missing
- **Detection**: Compare handoff claims against actual artifacts
- **Example**: Claims "all tests pass" but no test files found
- **Severity**: HIGH
- **Resolution**: Require evidence or downgrade claim

### PROJECT_IDENTITY_DRIFT
- **Description**: Project type or core purpose changes
- **Detection**: Compare current state against PIC projectType
- **Example**: Content site evolving into full SaaS platform
- **Severity**: CRITICAL
- **Resolution**: User decision required; may need full reclassification

### CONTRACT_VIOLATION
- **Description**: Implementation does not match API or feature contract
- **Detection**: Compare implementation against FC, AC apiContracts
- **Example**: API endpoint returns different shape than contract
- **Severity**: CRITICAL
- **Resolution**: Fix implementation or update contract

### NONGOAL_VIOLATION
- **Description**: A non-goal item found in implementation
- **Detection**: Compare codebase against NGC
- **Example**: Payment code found when NGC says no payment
- **Severity**: MEDIUM
- **Resolution**: Remove or formally add to scope

### ROLE_DRIFT
- **Description**: Agent operating outside its defined scope
- **Detection**: Compare agent outputs against agent definition
- **Example**: Frontend agent writing database migrations
- **Severity**: MEDIUM
- **Resolution**: Reassign work to correct agent

### KNOWLEDGE_LOSS
- **Description**: Design decision rationale not documented
- **Detection**: Architecture decisions without recorded rationale
- **Example**: "Why did we choose Prisma over Drizzle?" — not documented
- **Severity**: LOW
- **Resolution**: Document retroactively

## Checkpoint Triggers

| Checkpoint | When | Primary Checks |
|------------|------|----------------|
| CP-ARCH | After architecture design | PIC vs AC alignment, complexity assessment |
| CP-MID | Mid-implementation (~50%) | SCOPE_CREEP, SCOPE_SHRINK, ROLE_DRIFT |
| CP-PREVER | Before verification | CONTRACT_VIOLATION, EVIDENCE_OVERCLAIM |
| CP-PREDEPLOY | Before deploy/package | SECURITY_BOUNDARY_DRIFT, TECHNOLOGY_DRIFT, NONGOAL_VIOLATION |
| CP-POSTMORTEM | After completion | KNOWLEDGE_LOSS, all cumulative drifts |
