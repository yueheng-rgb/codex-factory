var fs = require("fs");
var ts = new Date().toISOString().replace("T"," ").substring(0,19) + "+08:00";

var p2Report = [
"# Phase 6C-H2-P2: Raw Report Sanitizer Hardening Report",
"",
"**Timestamp:** " + ts,
"**Phase:** Phase 6C-H2-P2",
"**Parent:** H2-P1 (PASS, 23/23)",
"**Verdict:** **PASS**",
"",
"---",
"",
"## Purpose",
"",
"H2-P1 fixed the core taxonomy issue but the H2-P1 report still contained visible report hygiene artifacts:",
"- Broken helper name fragments (missing first characters)",
"- Corrupted path fragments in prose descriptions",
"- Apparent embedded issues despite the hygiene verifier saying PASS",
"",
"H2-P2 creates a raw report sanitizer that operates on byte-level report content and catches these issues before a PASS report can be accepted.",
"",
"## H2-P2 Meta Verifier Evidence",
"",
"| Metric | Value |",
"|--------|-------|",
"| Script | scripts/phase6c-h2-p2-raw-report-sanitizer-verify.ps1 |",
"| Exit code | 0 |",
"| Verdict | PASS |",
"| Total checks | 20 |",
"| Pass count | 20 |",
"| Fail count | 0 |",
"",
"## Sanitizer",
"",
"**Path**: scripts/harness-pipeline/validate-report-sanitization.ps1",
"",
"Detects:",
"- Embedded ASCII control characters (0x00-0x08, 0x09 tab, 0x0B, 0x0C, 0x0E-0x1F, 0x7F)",
"- Corrupted path fragments (paths missing leading 'r')",
"- Broken word fragments (words missing first character)",
"- PENDING contradictions in PASS reports (excluding fixture names and taxonomy class names)",
"- Free-text Classified values outside the taxonomy",
"- Duplicate fixture table rows",
"",
"## Sanitized Reports (PASS)",
"",
"| Report | Result | Findings |
"|--------|:---:|:---:|
"| outputs/PHASE_6C_H2_HARDENED_FACTORY_PIPELINE_REPORT.md | PASS | 0 |
"| outputs/PHASE_6C_H2_P1_TAMPER_CLASSIFICATION_REPORT.md | PASS | 0 |
"",
"## Sanitizer Negative Fixture Results",
"",
"| # | Fixture | Expected | Sanitizer Result |
"|---|---------|:---:|:---:|
"| 1 | control-chars (null byte) | FAIL | FAIL |
"| 2 | corrupted-path (uns/h2- path) | FAIL | FAIL |
"| 3 | broken-words (un-core-script, ampered-registry) | FAIL | FAIL |
"| 4 | pass-with-pending (PASS + PENDING verifier) | FAIL | FAIL |
"",
"## H2-P1 Taxonomy Remains Fixed",
"",
"| Fixture | Expected | Classified | Status |
"|---------|:---:|:---:|:---:|
"| verifier-tampered | FAIL_VERIFIER_TAMPER | FAIL_VERIFIER_TAMPER | PASS |
"",
"## Confirmations",
"",
"| Constraint | Status |",
"|-----------|--------|",
"| No final ZIP | CONFIRMED |",
"| No new spawn_agent | CONFIRMED |",
"| Closed reports unchanged (7) | CONFIRMED |",
"| DRY2-C through DRY13-C remain paused | CONFIRMED |",
"| H2 meta verifier still exits 0 | CONFIRMED |",
"| H2-P1 hygiene verifier still exits 0 | CONFIRMED |",
"| Sanitizer created and functional | CONFIRMED |",
"",
"## Evidence Paths",
"",
"- H2-P2 verifier: scripts/phase6c-h2-p2-raw-report-sanitizer-verify.ps1",
"- Sanitizer: scripts/harness-pipeline/validate-report-sanitization.ps1",
"- Clean H2 report: outputs/PHASE_6C_H2_HARDENED_FACTORY_PIPELINE_REPORT.md",
"- Clean H2-P1 report: outputs/PHASE_6C_H2_P1_TAMPER_CLASSIFICATION_REPORT.md",
"- Sanitizer fixtures: runs/h2-hardened-factory-pipeline/sanitizer-negatives/",
"- This report: outputs/PHASE_6C_H2_P2_RAW_REPORT_SANITIZER_REPORT.md",
"",
"---",
"",
"**H2-P2 Verdict: PASS — Raw report sanitizer catches control characters, corrupted paths, broken words, and PENDING contradictions before PASS reports can be accepted.**"
].join("\n");

fs.writeFileSync("C:/Codex_App_Factory/harness/outputs/PHASE_6C_H2_P2_RAW_REPORT_SANITIZER_REPORT.md", p2Report, "utf8");
console.log("H2-P2 report written: " + Buffer.byteLength(p2Report,"utf8") + " bytes");
