# External Skill Audit Capability Survey
# Phase: FACTORY-R2.3-G-SKILL-AUDIT-CAPABILITY-TRUST-PIPELINE
# Date: 2026-07-09

## 1. OpenAI Codex Skills — Security & Deployment

**Source:** OpenAI Codex SKILL.md specification, Codex CLI documentation

**Key security-relevant features:**
- Skills are scoped to directory trees (AGENTS.md inheritance model)
- `forbiddenActions` field in skill definitions
- Trust levels: AVAILABLE → CAUTION → TRUSTED → VERIFIED
- Skills require explicit user approval before execution in untrusted mode
- Plugin marketplace with curated vs community distinction

**Audit-relevant takeaways:**
- Directory-scoped rules can be validated for overreach
- Forbidden action lists provide baseline for automated permission checking
- Trust level progression (AVAILABLE→VERIFIED) maps to audit pipeline stages
- Plugin marketplace curation is an external trust signal, not a substitute for internal audit

---

## 2. Claude Agent Skills — Enterprise Security

**Source:** Anthropic Claude Code CLAUDE.md, enterprise deployment guides

**Key security-relevant features:**
- CLAUDE.md as project-level instruction format
- Custom slash commands with permission boundaries
- MCP integration hooks with tool-level permissions
- Enterprise deployment with admin-controlled skill allowlists

**Audit-relevant takeaways:**
- Admin allowlists pattern: only pre-approved skills enter enterprise environment
- Tool-level permissions (not just skill-level) provide finer audit granularity
- MCP hooks require separate audit from skill content audit

---

## 3. OpenCode Skills / Agents — Permission Model

**Source:** OpenCode project, VS Code agent extensions

**Key security-relevant features:**
- Agent permission model: read, write, execute, spawn scopes
- Workspace trust levels
- Extension sandboxing

**Audit-relevant takeaways:**
- Permission scope auditing is a distinct audit dimension (what can the skill ask the agent to do?)
- Sandbox requirements should be derived from tool access patterns, not declared trust levels

---

## 4. Skill Supply-Chain Security Research

**Source:** Academic literature, OWASP supply-chain guidelines, NIST SP 800-204D

**Key concepts applicable to skill auditing:**
- **Version pinning:** Skills should reference specific versions of dependencies
- **Hash verification:** Skill packages should have SHA256 hashes
- **Signature verification:** Skills from external sources should be signed
- **Review-before-update:** Skills should not auto-update without audit
- **Dependency graph:** Skills that depend on other skills/MCPs create transitive trust
- **Provenance tracking:** Source, author, publication date, modification history

**Audit-relevant takeaways:**
- Supply-chain audit is a mandatory stage in any skill import pipeline
- Auto-update is a critical risk vector — skills should be immutable after audit until re-audited
- Transitive trust (skill A trusts skill B) requires explicit declaration and audit

---

## 5. Prompt Injection / Tool Poisoning Detection

**Source:** Research on LLM prompt injection, indirect prompt injection, tool-use attacks

**Detection methods:**
- **Static analysis:** Search for "ignore previous instructions", "you are now", "system: override"
- **Semantic analysis:** Check if skill instructions attempt to override user/system/Factory rules
- **Tool call pattern analysis:** Skills that request tools outside their declared allowedTools
- **Data flow analysis:** Skills that request reading sensitive files then request write/network access

**Audit-relevant takeaways:**
- Content audit must scan for known injection patterns
- Semantic audit is distinct from static pattern matching (LLM-assisted, not regex-only)
- Tool poisoning detection requires correlating allowedTools with instruction content

---

## 6. Community Marketplace Safety Signals

**Source:** awesome-agent-skills, VS Code marketplace, npm security advisories

**Safety signals to audit:**
- **Download count + rating:** Community signals (unreliable alone, useful as triage)
- **Maintainer history:** Has the skill author published other verified skills?
- **Issue tracker:** Are there open security issues?
- **Update frequency:** Too frequent = instability risk; too infrequent = abandonment risk
- **License type:** Copyleft vs permissive — impacts integration risk

**Audit-relevant takeaways:**
- Community signals are TRIAGE inputs, not VERDICT inputs
- A skill with 10k downloads and 5 stars can still have a prompt injection vulnerability
- License audit is mandatory for skills that modify project files

---

## 7. Existing Audit Tools & Methods

**Static analysis tools (conceptual mapping):**
- ESLint-like rule engine for SKILL.md content
- YARA-like pattern matching for known malicious patterns
- Semgrep-like structural analysis for instruction overrides

**Dynamic/runtime methods:**
- Sandbox execution with instrumented agent
- Fixture-based behavior verification (R2.3-F pattern)
- Permission gate replay with varied agent/projectType/phase inputs

**Gap analysis:**
- No existing tool specifically designed for SKILL.md audit
- General prompt injection scanners can be adapted
- Supply-chain tools (npm audit, pip audit) are dependency-focused, not skill-focused
- Codex Factory must build skill-specific audit from composable primitives

---

## 8. Recommended Audit Capability Candidates

The following capabilities should be registered for the audit pipeline:

| Capability | Type | What It Detects |
|-----------|------|----------------|
| Static content scan | static | Prompt injection, hidden overrides, forbidden patterns |
| Permission scope audit | static | Overbroad allowedTools, overbroad applicableAgents |
| Supply-chain audit | static | Missing hash, auto-update, external scripts, unpinned deps |
| Semantic audit | semantic | Instruction intent conflicts, misleading triggers |
| Sandbox behavioral audit | dynamic | Runtime behavior in instrumented fixture |
| License compliance audit | static | License conflicts, copyleft risk |
| Dependency graph audit | static | Transitive trust, circular dependencies |
| Community signal triage | external | Download count, maintainer history, issue tracker |
| Version diff audit | static | What changed between versions |
| Human review gate | human | Final approval for AVAILABLE/CAUTION skills |
