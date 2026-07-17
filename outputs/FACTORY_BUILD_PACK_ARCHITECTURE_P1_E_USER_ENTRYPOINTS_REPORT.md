# FACTORY-BUILD-PACK-ARCHITECTURE-P1 — Section E: User Entrypoints

| Entrypoint | Trigger | Mode | Approval |
|-----------|---------|------|----------|
| Build Lite (auto) | "build a project" | DEFAULT | No |
| Build Lite (explicit) | "use Build Lite" | DEFAULT | No |
| Native Build Pro | "use Build Pro" | CONDITIONAL | **Yes** |
| Vanilla | "skip factory" | FALLBACK | No |
| Context Packet | Phase/agent start | REQUIRED (BP) | Auto |
| Diagnostic Gate | Iteration boundary | SUPPORT | Auto |
| Recovery Drill | Lifecycle anomaly | SUPPORT | Auto |
| Verifier | Phase complete | REQUIRED | Auto |
