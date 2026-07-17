# Repair Package QA Findings
# Usage: include this prompt after QA Gate finds BLOCKING issues

Repair the BLOCKING findings from the Package QA Gate run.

Context: The package at <package_path> was checked and has the following BLOCKING findings:
<findings_json>

Repair rules:
1. Fix only the BLOCKING findings listed above
2. Do NOT modify package architecture or add features
3. Fixes should be minimal and targeted:
   - Process trace residue → remove the AI reference lines
   - Name/ID mismatch → correct to match profile
   - Missing files → add required files with minimal content
   - Syntax errors → fix the syntax only
   - Library mismatch → fix placeholder syntax
   - Secret in .env → replace with placeholder values
4. After repair, re-run the Package QA Gate
5. Repeat until PASS or user override
6. Document what was changed
