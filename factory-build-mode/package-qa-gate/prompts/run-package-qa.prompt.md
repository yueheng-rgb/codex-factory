# Run Package QA Gate
# Usage: include this prompt when Codex needs to run Package QA on a delivery

Run the Package QA Gate on the delivery package.

Steps:
1. Locate the package ZIP file at <package_path>
2. Locate the assignment profile at <profile_path> (if available)
3. Run: factory-build-mode\package-qa-gate\scripts\package-qa-check.ps1 -PackagePath <package_path> -ProfilePath <profile_path>
4. Report the results:
   - If PASS: confirm package is ready for handoff
   - If PASS_WITH_WARNINGS: list warnings, ask user if they want to proceed
   - If BLOCKED: list all BLOCKING findings with file paths and fix suggestions
5. If BLOCKED, offer to repair automatically using the repair prompt
6. Do NOT hand off the package if BLOCKED unless user explicitly approves override

Gate is READ-ONLY. Never modify the package during QA. Only report and suggest.
