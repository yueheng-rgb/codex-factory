# Expert Pack System
# Codex Factory R5.1 — Expert Pack Foundation
# Version 1.0.0

## Overview

The Expert Pack System extends Codex Factory Foundation RC with domain-specific
capability packs. Each pack bundles surface templates, risk rules, business
invariants, test requirements, engine recommendations, audit points, and
benchmark cases for a specific project domain.

Expert Packs do NOT replace Foundation RC. They layer on top of it.

## Architecture

```
Task Description
  → Expert Pack Activation (keyword match)
    → Expert Pack Loader (load domain definition)
      → Inject into Foundation RC:
        ├── Project Surface Plan (domain surface templates)
        ├── Risk Classifier (domain risk rules)
        ├── Business Invariant Engine (domain invariants)
        ├── External Engine Broker (domain engine requirements)
        ├── Gate Detection (domain test requirements)
        └── Risk Enforcement Gate (domain audit points)
    → Foundation RC pipeline continues normally
```

## Pack Structure

Each expert pack is defined in `governance/expert-packs/{domain}/`:

- `{domain}-pack.json` — Core pack definition (schema: `schemas/expert-pack.schema.json`)
- `{domain}-invariants.json` — Domain-specific business invariants
- `{domain}-benchmarks.json` — Domain-specific benchmark cases
- `{DOMAIN}_PACK.md` — Human-readable documentation

## Loading Flow

1. `expert-pack-loader.ps1` reads `expert-pack-registry.json`
2. Loads the specified pack JSON file
3. Exposes surfaces, risk rules, invariants, engines, tests, audit points
4. `expert-pack-activation.ps1` matches task descriptions to packs
5. Activated pack data feeds into Foundation RC pipeline steps

## Integration Points

Expert Packs integrate with Foundation RC at these points:

| Foundation RC Component | Expert Pack Input |
|-------------------------|-------------------|
| Project Surface Plan | `supported_surfaces`, `default_surface_templates` |
| Risk Classifier / Risk Profile | `domain_risk_rules`, `critical_fields` |
| Business Invariant Engine | `business_invariants` |
| External Engine Broker | `required_external_engines` |
| Automated Gate Detector | `required_tests` |
| Risk Enforcement Gate | `human_audit_points` |

## Rules

1. Expert Packs MUST NOT modify frozen Foundation RC pipelines
2. Expert Packs MUST NOT bypass Risk Gate
3. Expert Packs MUST NOT claim production readiness
4. Expert Packs are ADVISORY — they inform pipeline decisions but do not replace them
5. Expert Pack activation is based on keyword matching from task descriptions
6. Multiple packs CAN be activated for cross-domain projects
7. Non-claims are enforced — packs explicitly state what they do NOT support

## Versioning

Expert packs follow the Factory version cycle. Current: v1.0.0 (Foundation RC era).
